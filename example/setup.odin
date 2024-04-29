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
mouse_pos:   [2]f32 // Absolute mouse position
mouse_rel:   [2]f32 // Relative mouse position -0.5 to 0.5
dpr: f32
aspect_ratio: f32

scale: f32 = 0.5

Example_Kind :: enum {
	Rectangle,
	Pyramid,
	Boxes,
	Camera,
	Lighting,
	Specular,
	Spotlight,
}
example: Example_Kind

Demo_Sources :: struct {
	vs_sources, fs_sources: []string,
}
demos: [Example_Kind]Demo_Sources = {
	.Rectangle = {
		vs_sources = {#load("./rectangle.vert", string)},
		fs_sources = {#load("./simple.frag", string)},
	},
	.Pyramid = {
		vs_sources = {#load("./pyramid.vert", string)},
		fs_sources = {#load("./simple.frag", string)},
	},
	.Boxes = {
		vs_sources = {#load("./boxes.vert", string)},
		fs_sources = {#load("./simple.frag", string)},
	},
	.Camera = {
		vs_sources = {#load("./boxes.vert", string)},
		fs_sources = {#load("./simple.frag", string)},
	},
	.Lighting = {
		vs_sources = {#load("./lighting.vert", string)},
		fs_sources = {#load("./lighting.frag", string)},
	},
	.Specular = {
		vs_sources = {#load("./specular.vert", string)},
		fs_sources = {#load("./specular.frag", string)},
	},
	.Spotlight = {
		vs_sources = {#load("./spotlight.vert", string)},
		fs_sources = {#load("./spotlight.frag", string)},
	},
}

// state is a union because it is being used by only one of the examples
demo_state: struct #raw_union {
	rectangle: State_Rectangle,
	pyramid:   State_Pyramid,
	boxes:     State_Boxes,
	camera:    State_Camera,
	lighting:  State_Lighting,
	specular:  State_Specular,
	spotlight: State_Spotlight,
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

on_mouse_move :: proc(e: dom.Event) {
	mouse_pos = cast_vec2(f32, e.mouse.client)
	mouse_rel = (mouse_pos - window_size / 2) / window_size
}
on_wheel :: proc(e: dom.Event) {
	scale -= f32(e.wheel.delta.y) * 0.001
	scale = clamp(scale, 0, 1)
}
@export
on_window_resize :: proc "c" (vw, vh, cw, ch, cx, cy: f32) {
	window_size  = {vw, vh}
	canvas_size  = {cw, ch}
	canvas_pos   = {cx, cy}
	canvas_res   = cast_vec2(i32, canvas_size * dpr)
	aspect_ratio = canvas_size.x / canvas_size.y
}

@export
start :: proc "c" (ctx: ^runtime.Context, example_kind: Example_Kind) -> (ok: bool) {
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

	switch example {
	case .Rectangle: setup_rectangle(&demo_state.rectangle, program)
	case .Pyramid:   setup_pyramid  (&demo_state.pyramid,   program)
	case .Boxes:     setup_boxes    (&demo_state.boxes,     program)
	case .Camera:    setup_camera   (&demo_state.camera,    program)
	case .Lighting:  setup_lighting (&demo_state.lighting,  program)
	case .Specular:  setup_specular (&demo_state.specular,  program)
	case .Spotlight: setup_spotlight(&demo_state.spotlight, program)
	}

	if err := gl.GetError(); err != gl.NO_ERROR {
		fmt.eprintln("WebGL error:", err)
		return false
	}

	return true
}

@export
frame :: proc "c" (ctx: ^runtime.Context, delta: f32) {
	context = ctx^
	context.temp_allocator = mem.arena_allocator(&frame_arena)
	defer free_all(context.temp_allocator)

	if err := gl.GetError(); err != gl.NO_ERROR {
		fmt.eprintln("WebGL error:", err)
		return
	}

	switch example {
	case .Rectangle: frame_rectangle(&demo_state.rectangle, delta)
	case .Pyramid:   frame_pyramid  (&demo_state.pyramid,   delta)
	case .Boxes:     frame_boxes    (&demo_state.boxes,     delta)
	case .Camera:    frame_camera   (&demo_state.camera,    delta)
	case .Lighting:  frame_lighting (&demo_state.lighting,  delta)
	case .Specular:  frame_specular (&demo_state.specular,  delta)
	case .Spotlight: frame_spotlight(&demo_state.spotlight, delta)
	}
}
