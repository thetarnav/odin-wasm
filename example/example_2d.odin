package example

import "core:fmt"

import gl "../wasm/webgl"

example_2d_state: struct {
	rotation:         f32,
	a_position:       i32,
	a_color:          i32,
	u_matrix:         i32,
	positions_buffer: gl.Buffer,
	colors_buffer:    gl.Buffer,
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


example_2d_start :: proc(program: gl.Program) -> (ok: bool) {
	using example_2d_state

	a_position = gl.GetAttribLocation(program, "a_position")
	a_color = gl.GetAttribLocation(program, "a_color")
	u_matrix = gl.GetUniformLocation(program, "u_matrix")

	gl.EnableVertexAttribArray(a_position)
	gl.EnableVertexAttribArray(a_color)

	positions_buffer = gl.CreateBuffer()
	colors_buffer = gl.CreateBuffer()

	err := gl.GetError()
	if err != gl.NO_ERROR {
		fmt.eprintln("WebGL error: ", err)
		return false
	}

	return true
}

example_2d_frame :: proc(delta: f32) {
	using example_2d_state

	gl.BindBuffer(gl.ARRAY_BUFFER, positions_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, positions[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_position, 2, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, colors_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, colors[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_color, 4, gl.UNSIGNED_BYTE, true, 0, 0)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0.01, 0.02, 0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	rotation += 0.01 * delta * (window_size.x / 2 - mouse_pos.x) / window_size.x
	mat := mat3_projection(canvas_size)
	mat *= mat3_translate(mouse_pos - canvas_pos)
	mat *= mat3_scale(scale)
	mat *= mat3_rotate(rotation)
	mat *= mat3_translate(-box_size / 2)

	gl.UniformMatrix3fv(u_matrix, mat)

	gl.DrawArrays(gl.TRIANGLES, 0, VERTICES)
}
