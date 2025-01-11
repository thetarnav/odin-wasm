package example

import "core:math/rand"
import "core:crypto"

import    "../wasm/dom"
import gl "../wasm/webgl"


canvas_res:  ivec2
canvas_pos:  vec2
canvas_size: vec2
window_size: vec2
mouse_abs:   vec2  // Absolute mouse position from the window top-left
mouse_rel:   rvec2 // Relative mouse position -0.5 to 0.5
mouse_pos:   vec2  // Absolute mouse position from the canvas top-left
mouse_down:  bool
mouse_down_time: f64
mouse_down_time_prev: f64
mouse_down_frame: bool
dpr: f32
aspect_ratio: f32

scale: f32 = 0.5

on_mouse_move :: proc (e: dom.Event) {
	mouse_abs = cast_vec2(e.mouse.client)
	mouse_pos = mouse_abs - canvas_pos
	mouse_rel = rvec2((mouse_pos - canvas_size/2) / canvas_size)
}
on_mouse_down :: proc (e: dom.Event) {
	mouse_down_time_prev = mouse_down_time
	mouse_down_time      = e.timestamp
	mouse_down           = true
	mouse_down_frame     = true
}
on_mouse_up :: proc (e: dom.Event) {
	mouse_down = false
}
on_wheel :: proc (e: dom.Event) {
	scale -= f32(e.wheel.delta.y) * 0.001
	scale = clamp(scale, 0, 1)
}
@export
on_window_resize :: proc (vw, vh, cw, ch, cx, cy: f32) {
	window_size  = {vw, vh}
	canvas_size  = {cw, ch}
	canvas_pos   = {cx, cy}
	canvas_res   = cast_ivec2(canvas_size * dpr)
	aspect_ratio = canvas_size.x / canvas_size.y
}

main :: proc () {
	dom.add_window_event_listener(.Wheel,      {}, on_wheel)
	dom.add_window_event_listener(.Mouse_Move, {}, on_mouse_move)
	dom.add_window_event_listener(.Mouse_Down, {}, on_mouse_down)
	dom.add_window_event_listener(.Mouse_Up,   {}, on_mouse_up)


	dpr = f32(dom.device_pixel_ratio())
	window_size = cast_vec2(dom.get_window_inner_size())
	canvas_size = window_size - 200
	mouse_abs   = vec2(window_size / 2)
	mouse_pos   = vec2(canvas_size / 2)

	// Seed the random number generator
	{
		buf: [8]u8
		crypto.rand_bytes(buf[:])
		rand.reset(transmute(u64)buf)
	}
}


Example_Kind :: enum {
	Rectangle    = 0,
	Pyramid      = 1,
	Boxes        = 2,
	Camera       = 3,
	Lighting     = 4,
	Specular     = 5,
	Spotlight    = 6,
	Candy        = 7,
	Sol_System   = 8,
	Bezier_Curve = 9,
	Lathe        = 10,
	Suzanne      = 11,
	Chair        = 12,
	Book         = 13,
	Windmill     = 14,
}
example: Example_Kind

demos: [Example_Kind]struct {
	vs_sources, fs_sources: []string,
} = {
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
	.Candy = {
		vs_sources = {#load("./candy.vert", string)},
		fs_sources = {#load("./candy.frag", string)},
	},
	.Sol_System = {
		vs_sources = {#load("./sol_system.vert", string)},
		fs_sources = {#load("./sol_system.frag", string)},
	},
	.Bezier_Curve = {},
	.Lathe = {
		vs_sources = {#load("./lighting.vert", string)},
		fs_sources = {#load("./lighting.frag", string)},
	},
	.Suzanne = {
		vs_sources = {#load("./boxes.vert", string)},
		fs_sources = {#load("./simple.frag", string)},
	},
	.Chair = {
		vs_sources = {#load("./chair.vert", string)},
		fs_sources = {#load("./chair.frag", string)},
	},
	.Book = {
		vs_sources = {#load("./boxes.vert", string)},
		fs_sources = {#load("./simple.frag", string)},
	},
	.Windmill = {
		vs_sources = {#load("./chair.vert", string)},
		fs_sources = {#load("./chair.frag", string)},
	},
}

// state is a union because it is being used by only one of the examples
demo_state: struct #raw_union {
	rectangle:    State_Rectangle,
	pyramid:      State_Pyramid,
	boxes:        State_Boxes,
	camera:       State_Camera,
	lighting:     State_Lighting,
	specular:     State_Specular,
	spotlight:    State_Spotlight,
	candy:        State_Candy,
	sol_system:   State_Sol_System,
	bezier_curve: State_Bezier_Curve,
	lathe:        State_Lathe,
	suzanne:      State_Suzanne,
	chair:        State_Chair,
	book:         State_Book,
	windmill:     State_Windmill,
}

@export
start :: proc (example_kind: Example_Kind) -> (ok: bool) {
	example = example_kind
	demo := demos[example]

	defer free_all(context.temp_allocator)

	program: gl.Program

	// Make sure that this matches the id of your canvas.
	if ok = gl.SetCurrentContextById("canvas-1"); !ok {
		fmt.eprintln("Failed to set current context!")
		return false
	}
	
	// Some examples don't use webgl shaders
	if len(demo.vs_sources) == 0 {
		demo.vs_sources = {"void main() {}"}
	}
	if len(demo.fs_sources) == 0 {
		demo.fs_sources = {"void main() {}"}
	}

	program, ok = gl.CreateProgramFromStrings(demo.vs_sources, demo.fs_sources)
	if !ok {
		fmt.eprintln("Failed to create program!")
		return false
	}

	gl.UseProgram(program)

	switch example {
	case .Rectangle:    setup_rectangle   (&demo_state.rectangle,    program)
	case .Pyramid:      setup_pyramid     (&demo_state.pyramid,      program)
	case .Boxes:        setup_boxes       (&demo_state.boxes,        program)
	case .Camera:       setup_camera      (&demo_state.camera,       program)
	case .Lighting:     setup_lighting    (&demo_state.lighting,     program)
	case .Specular:     setup_specular    (&demo_state.specular,     program)
	case .Spotlight:    setup_spotlight   (&demo_state.spotlight,    program)
	case .Candy:        setup_candy       (&demo_state.candy,        program)
	case .Sol_System:   setup_sol_system  (&demo_state.sol_system,   program)
	case .Bezier_Curve: setup_bezier_curve(&demo_state.bezier_curve, program)
	case .Lathe:        setup_lathe       (&demo_state.lathe,        program)
	case .Suzanne:      setup_suzanne     (&demo_state.suzanne,      program)
	case .Chair:        setup_chair       (&demo_state.chair,        program)
	case .Book:         setup_book        (&demo_state.book,         program)
	case .Windmill:     setup_windmill    (&demo_state.windmill,     program)
	}

	if err := gl.GetError(); err != gl.NO_ERROR {
		fmt.eprintln("WebGL error:", err)
		return false
	}

	return true
}

@export
frame :: proc (delta: f32) {
	
	defer free_all(context.temp_allocator)

	defer mouse_down_frame = false

	if err := gl.GetError(); err != gl.NO_ERROR {
		fmt.eprintln("WebGL error:", err)
		return
	}

	switch example {
	case .Rectangle:    frame_rectangle   (&demo_state.rectangle,    delta)
	case .Pyramid:      frame_pyramid     (&demo_state.pyramid,      delta)
	case .Boxes:        frame_boxes       (&demo_state.boxes,        delta)
	case .Camera:       frame_camera      (&demo_state.camera,       delta)
	case .Lighting:     frame_lighting    (&demo_state.lighting,     delta)
	case .Specular:     frame_specular    (&demo_state.specular,     delta)
	case .Spotlight:    frame_spotlight   (&demo_state.spotlight,    delta)
	case .Candy:        frame_candy       (&demo_state.candy,        delta)
	case .Sol_System:   frame_sol_system  (&demo_state.sol_system,   delta)
	case .Bezier_Curve: frame_bezier_curve(&demo_state.bezier_curve, delta)
	case .Lathe:        frame_lathe       (&demo_state.lathe,        delta)
	case .Suzanne:      frame_suzanne     (&demo_state.suzanne,      delta)
	case .Chair:        frame_chair       (&demo_state.chair,        delta)
	case .Book:         frame_book        (&demo_state.book,         delta)
	case .Windmill:     frame_windmill    (&demo_state.windmill,     delta)
	}
}
