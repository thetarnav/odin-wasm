//+private file
package example

import gl "../wasm/webgl"

TRIANGLES :: 2
VERTICES  :: TRIANGLES * 3
BOX_W: f32 : 160
BOX_H: f32 : 100
box_size: [2]f32 = {BOX_W, BOX_H}

colors: [VERTICES]u8vec4 = {
	GREEN, YELLOW, BLUE,
	RED, YELLOW, BLUE,
}
positions: [VERTICES]vec2 = {
	{0,     0},
	{BOX_W, 0},
	{0,     BOX_H},

	{BOX_W, BOX_H},
	{BOX_W, 0},
	{0,     BOX_H},
}

@private
State_Rectangle :: struct {
	using locations: Input_Locations_Rectangle,
	vao       : VAO,
	rotation  : f32,
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

	input_locations_rectangle(s, program)

	attribute(s.a_position, gl.CreateBuffer(), positions[:])
	attribute(s.a_color   , gl.CreateBuffer(), colors[:])
}

@private
frame_rectangle :: proc(s: ^State_Rectangle, delta: f32) {

	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	s.rotation -= 0.01 * delta * mouse_rel.x

	mat: mat3 = 1
	mat *= mat3_projection(vec2(canvas_size))
	mat *= mat3_translate(vec2(mouse_pos - canvas_pos))
	mat *= mat3_scale(scale*2 + 0.4)
	mat *= mat3_rotate(s.rotation)
	mat *= mat3_translate(vec2(-box_size / 2))

	uniform(s.u_matrix, mat)

	gl.DrawArrays(gl.TRIANGLES, 0, VERTICES)
}
