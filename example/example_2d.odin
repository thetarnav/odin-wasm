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

@(private = "file")
TRIANGLES :: 2
@(private = "file")
VERTICES :: TRIANGLES * 3
@(private = "file")
BOX_W: f32 : 160
@(private = "file")
BOX_H: f32 : 100
@(private = "file")
box_size: [2]f32 = {BOX_W, BOX_H}

// odinfmt: disable
@(private = "file")
colors: [VERTICES*4]u8 = {
	60,  210, 0,   255, // G
	210, 210, 0,   255, // Y
	0,   80,  190, 255, // B

	230, 20,  0,   255, // R
	210, 210, 0,   255, // Y
	0,   80,  190, 255, // B
}
@(private = "file")
positions: [VERTICES*2]f32 = {
	0,     0,
	BOX_W, 0,
	0,     BOX_H,

	BOX_W, BOX_H,
	BOX_W, 0,
	0,     BOX_H,
}
// odinfmt: enable


example_2d_start :: proc(program: webgl.Program) -> (ok: bool) {
	using example_2d_state

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
	webgl.BufferDataSlice(webgl.ARRAY_BUFFER, positions[:], webgl.STATIC_DRAW)
	webgl.VertexAttribPointer(a_position, 2, webgl.FLOAT, false, 0, 0)

	webgl.BindBuffer(webgl.ARRAY_BUFFER, colors_buffer)
	webgl.BufferDataSlice(webgl.ARRAY_BUFFER, colors[:], webgl.STATIC_DRAW)
	webgl.VertexAttribPointer(a_color, 4, webgl.UNSIGNED_BYTE, true, 0, 0)

	webgl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	webgl.ClearColor(0, 0.01, 0.02, 0)
	webgl.Clear(webgl.COLOR_BUFFER_BIT)

	rotation += 0.01 * delta * (window_size.x / 2 - mouse_pos.x) / window_size.x
	mat :=
		mat3_projection(canvas_size) *
		mat3_translate(mouse_pos - canvas_pos) *
		mat3_scale(scale) *
		mat3_rotate(rotation) *
		mat3_translate(-box_size / 2)

	webgl.UniformMatrix3fv(u_matrix, mat)

	webgl.DrawArrays(webgl.TRIANGLES, 0, VERTICES)
}
