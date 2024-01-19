package main

import "core:fmt"

import "../wasm/webgl"

example_2d_state: struct {
	rotation:         f32,
	a_position:       i32,
	a_color:          i32,
	u_matrix:         i32,
	positions_buffer: webgl.Buffer,
	colors_buffer:    webgl.Buffer,
}

BOX_W: f32 : 160
BOX_H: f32 : 100
box_size: [2]f32 = {BOX_W, BOX_H}

// odinfmt: disable
example_2d_colors: [2*3*4]u8 = {
	60,  210, 0,   255,
	210, 210, 0,   255,
	0,   80,  190, 255,

	230, 20,  0,   255,
	210, 210, 0,   255,
	0,   80,  190, 255,
}
example_2d_positions: [2*3*2]f32 = {
	0,     0,
	BOX_W, 0,
	0,     BOX_H,

	BOX_W, BOX_H,
	BOX_W, 0,
	0,     BOX_H,
}
// odinfmt: enable


example_2d_start :: proc() -> (ok: bool) {
	using example_2d_state

	program, program_ok := webgl.CreateProgramFromStrings({shader_vertex_2d}, {shader_fragment_2d})
	if !program_ok {
		fmt.eprintln("Failed to create program!")
		return false
	}
	webgl.UseProgram(program)

	a_position = webgl.GetAttribLocation(program, "a_position")
	a_color = webgl.GetAttribLocation(program, "a_color")
	u_matrix = webgl.GetUniformLocation(program, "u_matrix")

	webgl.EnableVertexAttribArray(a_position)
	webgl.EnableVertexAttribArray(a_color)

	positions_buffer = webgl.CreateBuffer()
	colors_buffer = webgl.CreateBuffer()

	err := webgl.GetError()
	if err != webgl.NO_ERROR {
		fmt.eprintln("WebGL error: ", err)
		return false
	}

	return true
}

example_2d_frame :: proc(delta: f32) {
	using example_2d_state

	webgl.BindBuffer(webgl.ARRAY_BUFFER, positions_buffer)
	webgl.BufferDataSlice(webgl.ARRAY_BUFFER, example_2d_positions[:], webgl.STATIC_DRAW)
	webgl.VertexAttribPointer(a_position, 2, webgl.FLOAT, false, 0, 0)

	webgl.BindBuffer(webgl.ARRAY_BUFFER, colors_buffer)
	webgl.BufferDataSlice(webgl.ARRAY_BUFFER, example_2d_colors[:], webgl.STATIC_DRAW)
	webgl.VertexAttribPointer(a_color, 4, webgl.UNSIGNED_BYTE, true, 0, 0)

	webgl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	webgl.ClearColor(0, 0.01, 0.02, 0)
	webgl.Clear(webgl.COLOR_BUFFER_BIT)

	rotation += 0.01 * delta * (window_size.x / 2 - mouse_pos.x) / window_size.x
	mat :=
		mat3_projection(canvas_size) *
		mat3_translate(mouse_pos - canvas_pos) *
		mat3_scale({scale, scale}) *
		mat3_rotate(rotation) *
		mat3_translate(-box_size / 2)

	webgl.UniformMatrix3fv(u_matrix, mat)

	webgl.DrawArrays(webgl.TRIANGLES, 0, 6) // 2 triangles, 6 vertices
}
