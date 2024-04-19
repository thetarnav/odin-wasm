//+private file
package example

import gl "../wasm/webgl"

TRIANGLES :: 2
VERTICES  :: TRIANGLES * 3
BOX_W: f32 : 160
BOX_H: f32 : 100
box_size: [2]f32 = {BOX_W, BOX_H}

colors: [VERTICES*4]u8 = {
	60,  210, 0,   255, // G
	210, 210, 0,   255, // Y
	0,   80,  190, 255, // B

	230, 20,  0,   255, // R
	210, 210, 0,   255, // Y
	0,   80,  190, 255, // B
}
positions: [VERTICES*2]f32 = {
	0,     0,
	BOX_W, 0,
	0,     BOX_H,

	BOX_W, BOX_H,
	BOX_W, 0,
	0,     BOX_H,
}

@private
State_Rectangle :: struct {
	rotation: f32,
	u_matrix: i32,
	vao:      VAO,
}

@private
setup_rectangle :: proc(s: ^State_Rectangle, program: gl.Program) {
	/*
	Position and color buffers are static,
	so we can bind them to the Vertex_Array_Object
	and reuse them in the draw call
	*/
	s.vao = gl.CreateVertexArray()
	gl.BindVertexArray(s.vao) // need to bind VAO before binding buffers

	a_position := gl.GetAttribLocation (program, "a_position")
	a_color    := gl.GetAttribLocation (program, "a_color")

	s.u_matrix  = gl.GetUniformLocation(program, "u_matrix")

	gl.EnableVertexAttribArray(a_position)
	gl.EnableVertexAttribArray(a_color)

	positions_buffer := gl.CreateBuffer()
	colors_buffer    := gl.CreateBuffer()

	gl.BindBuffer(gl.ARRAY_BUFFER, positions_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, positions[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_position, 2, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, colors_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, colors[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_color, 4, gl.UNSIGNED_BYTE, true, 0, 0)
}

@private
frame_rectangle :: proc(s: ^State_Rectangle, delta: f32) {

	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	s.rotation -= 0.01 * delta * mouse_rel.x

	mat: Mat3 = 1
	mat *= mat3_projection(canvas_size)
	mat *= mat3_translate(mouse_pos - canvas_pos)
	mat *= mat3_scale(scale*2 + 0.4)
	mat *= mat3_rotate(s.rotation)
	mat *= mat3_translate(-box_size / 2)

	gl.UniformMatrix3fv(s.u_matrix, mat)

	gl.DrawArrays(gl.TRIANGLES, 0, VERTICES)
}
