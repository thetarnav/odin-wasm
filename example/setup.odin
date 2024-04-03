package example

import "core:fmt"
import "core:mem"
import "core:runtime"

import "../wasm/dom"
import gl "../wasm/webgl"

rectangle_fs := #load("./rectangle_fs.glsl", string)
rectangle_vs := #load("./rectangle_vs.glsl", string)

pyramid_fs := #load("./pyramid_fs.glsl", string)
pyramid_vs := #load("./pyramid_vs.glsl", string)

boxes_fs := #load("./boxes_fs.glsl", string)
boxes_vs := #load("./boxes_vs.glsl", string)

dpr: f32
canvas_res:  [2]i32
canvas_pos:  [2]f32
canvas_size: [2]f32
window_size: [2]f32
mouse_pos:   [2]f32

scale: f32 = 1
scale_min: f32 = 0.25
scale_max: f32 = 3

Example_Kind :: enum {
	Rectangle,
	Pyramid,
	Boxes,
}
example: Example_Kind

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
	mouse_pos   = window_size / 2
}

@(export)
start_example :: proc "contextless" (
	ctx: ^runtime.Context,
	example_kind: Example_Kind,
) -> (ok: bool) {
	context = ctx^
	example = example_kind

	// Make sure that this matches the id of your canvas.
	if ok := gl.SetCurrentContextById("canvas"); !ok {
		fmt.eprintln("Failed to set current context!")
		return false
	}

	vs_sources, fs_sources: []string

	switch example {
	case .Rectangle:
		vs_sources = {rectangle_vs}
		fs_sources = {rectangle_fs}
	case .Pyramid:
		vs_sources = {pyramid_vs}
		fs_sources = {pyramid_fs}
	case .Boxes:
		vs_sources = {boxes_vs}
		fs_sources = {boxes_fs}
	}

	program, program_ok := gl.CreateProgramFromStrings(vs_sources, fs_sources)
	if !program_ok {
		fmt.eprintln("Failed to create program!")
		return false
	}

	gl.UseProgram(program)

	switch example {
	case .Rectangle: rectangle_start(program)
	case .Pyramid  : pyramid_start(program)
	case .Boxes    : boxes_start(program)
	}

	if err := gl.GetError(); err != gl.NO_ERROR {
		fmt.eprintln("WebGL error:", err)
		return false
	}

	return true
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
	canvas_pos  = {cx, cy}
	canvas_res  = cast_vec2(i32, canvas_size * dpr)
}

@(export)
frame :: proc "contextless" (ctx: ^runtime.Context, delta: f32) {
	context = ctx^
	context.temp_allocator = mem.arena_allocator(&frame_arena)
	defer free_all(context.temp_allocator)

	if err := gl.GetError(); err != gl.NO_ERROR {
		fmt.eprintln("WebGL error:", err)
		return
	}

	switch example {
	case .Rectangle: rectangle_frame(delta)
	case .Pyramid  : pyramid_frame(delta)
	case .Boxes    : boxes_frame(delta)
	}
}
