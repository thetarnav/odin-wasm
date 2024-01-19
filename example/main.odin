package main

import "core:fmt"
import "core:mem"
import "core:runtime"

import "../wasm/dom"
import "../wasm/webgl"

shader_fragment_2d := #load("shader_fragment.glsl", string)
shader_vertex_2d := #load("shader_vertex.glsl", string)

dpr: f32
canvas_res: [2]i32
canvas_pos: [2]f32
canvas_size: [2]f32
window_size: [2]f32
mouse_pos: [2]f32

scale: f32 = 1
scale_min: f32 = 0.25
scale_max: f32 = 5

Example_Type :: enum {
	D2,
	D3,
}
example: Example_Type

frame_arena_buffer: [1024]byte
frame_arena: mem.Arena = {
	data = frame_arena_buffer[:],
}

main :: proc() {
	if ODIN_DEBUG {
		dom.dispatch_custom_event("body", "lol")

		fmt.print("Hellope, WebAssembly!!!\n")
		fmt.eprint("Hello, Error!\n\ttest\nbyebye!\n")
	}

	dom.add_window_event_listener(.Wheel, {}, on_wheel)
	dom.add_window_event_listener(.Mouse_Move, {}, on_mouse_move)

	dpr = f32(dom.device_pixel_ratio())
	window_size = cast_vec2(f32, dom.get_window_inner_size())
	canvas_size = window_size - 200
	mouse_pos = window_size / 2
}

@(export)
start_example :: proc "contextless" (
	ctx: ^runtime.Context,
	example_type: Example_Type,
) -> (
	ok: bool,
) {
	context = ctx^
	example = example_type

	// Make sure that this matches the id of your canvas.
	if ok := webgl.SetCurrentContextById("canvas"); !ok {
		fmt.eprintln("Failed to set current context!")
		return false
	}

	switch example {
	case .D2:
		return example_2d_start()
	case .D3:
		return example_3d_start()
	case:
		return false
	}
}

on_mouse_move :: proc(e: dom.Event) {
	mouse_pos = cast_vec2(f32, e.data.mouse.client)
}
on_wheel :: proc(e: dom.Event) {
	scale += f32(e.data.wheel.delta.y) * 0.001
	scale = clamp(scale, scale_min, scale_max)
}
@(export)
on_window_resize :: proc "contextless" (vw, vh, cw, ch, cx, cy: f32) {
	window_size = {vw, vh}
	canvas_size = {cw, ch}
	canvas_pos = {cx, cy}
	canvas_res = cast_vec2(i32, canvas_size * dpr)
}

@(export)
frame :: proc "contextless" (ctx: ^runtime.Context, delta: f32) {
	context = ctx^
	context.temp_allocator = mem.arena_allocator(&frame_arena)
	defer free_all(context.temp_allocator)

	if err := webgl.GetError(); err != webgl.NO_ERROR {
		fmt.eprintln("WebGL error:", err)
		return
	}

	switch example {
	case .D2:
		example_2d_frame(delta)
	case .D3:
		example_3d_frame(delta)
	}
}
