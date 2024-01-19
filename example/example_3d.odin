package main

import "core:fmt"

import "../wasm/webgl"

example_3d_state: struct {
	positions_buffer: webgl.Buffer,
	colors_buffer:    webgl.Buffer,
}

// odinfmt: disable
example_3d_colors: [2*3*4]u8 = {
	60,  210, 0,   255,
	210, 210, 0,   255,
	0,   80,  190, 255,

	230, 20,  0,   255,
	210, 210, 0,   255,
	0,   80,  190, 255,
}
example_3d_positions: [2*3*2]f32 = {
	0,     0,
	BOX_W, 0,
	0,     BOX_H,

	BOX_W, BOX_H,
	BOX_W, 0,
	0,     BOX_H,
}
// odinfmt: enable


example_3d_start :: proc() -> (ok: bool) {
	using example_3d_state

	program, program_ok := webgl.CreateProgramFromStrings({shader_vertex_2d}, {shader_fragment_2d})
	if !program_ok {
		fmt.eprintln("Failed to create program!")
		return false
	}
	webgl.UseProgram(program)

	positions_buffer = webgl.CreateBuffer()
	colors_buffer = webgl.CreateBuffer()

	err := webgl.GetError()
	if err != webgl.NO_ERROR {
		fmt.eprintln("WebGL error: ", err)
		return false
	}

	return true
}

example_3d_frame :: proc(delta: f32) {
	using example_3d_state

}
