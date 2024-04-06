package example

import "core:fmt"
import "core:mem"
import "core:runtime"

import "../wasm/dom"
import gl "../wasm/webgl"

canvas_res:  [2]i32
canvas_pos:  [2]f32
canvas_size: [2]f32
window_size: [2]f32
mouse_pos:   [2]f32
dpr: f32
scale: f32 = 0.5

Example_Kind :: enum {
	Rectangle,
	Pyramid,
	Boxes,
	Look_At,
}
example: Example_Kind

Demo_Interface :: struct {
	vs_sources, fs_sources: []string,
	setup: proc(program: gl.Program),
	frame: proc(delta: f32),
}
demos: [Example_Kind]Demo_Interface = {
	.Rectangle = {
		vs_sources = {#load("./rectangle_vs.glsl", string)},
		fs_sources = {#load("./fs_simple.glsl", string)},
		setup      = rectangle_start,
		frame      = rectangle_frame,
	},
	.Pyramid   = {
		vs_sources = {#load("./pyramid_vs.glsl", string)},
		fs_sources = {#load("./fs_simple.glsl", string)},
		setup      = pyramid_start,
		frame      = pyramid_frame,
	},
	.Boxes     = {
		vs_sources = {#load("./boxes_vs.glsl", string)},
		fs_sources = {#load("./fs_simple.glsl", string)},
		setup      = boxes_start,
		frame      = boxes_frame,
	},
	.Look_At   = {
		vs_sources = {#load("./boxes_vs.glsl", string)},
		fs_sources = {#load("./fs_simple.glsl", string)},
		setup      = look_at_start,
		frame      = look_at_frame,
	},
}

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

@export start :: proc "contextless" (
	ctx: ^runtime.Context,
	example_kind: Example_Kind,
) -> (ok: bool) {
	context = ctx^
	example = example_kind

	// Make sure that this matches the id of your canvas.
	if ok = gl.SetCurrentContextById("canvas"); !ok {
		fmt.eprintln("Failed to set current context!")
		return false
	}

	demo := demos[example]

	program, program_ok := gl.CreateProgramFromStrings(demo.vs_sources, demo.fs_sources)
	if !program_ok {
		fmt.eprintln("Failed to create program!")
		return false
	}

	gl.UseProgram(program)
	demo.setup(program)

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
	scale -= f32(e.data.wheel.delta.y) * 0.001
	scale = clamp(scale, 0, 1)
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

	demos[example].frame(delta)
}