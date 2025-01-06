#+private file
package example

import glm "core:math/linalg/glsl"
import     "core:strings"
import     "core:slice"
import gl  "../wasm/webgl"
import     "../obj"

@private
State_Suzanne :: struct {
	using locations: Input_Locations_Boxes,
	vao:       VAO,
	rotation:  mat4,
	positions: []vec3,
	colors:    []u8vec4,
}

suzanne_obj_bytes := #load("./public/suzanne.obj", string)

@private
setup_suzanne :: proc(s: ^State_Suzanne, program: gl.Program) {

	data := obj.data_make(context.temp_allocator)
	it := suzanne_obj_bytes
	for line in strings.split_lines_iterator(&it) {
		obj.parse_line(&data, line)
	}

	s.positions = make([]vec3,   len(data.indices)*2)
	s.colors    = make([]u8vec4, len(s.positions))

	// for idx, i in data.indices {
	// 	s.positions[i] = data.positions[idx.position-1] * 100
	// }

	for i := 0; i < len(data.indices); i += 3 {
		a, b, c := data.indices[i+0], data.indices[i+1], data.indices[i+2]
		s.positions[i*2+0] = data.positions[a.position-1] * 100
		s.positions[i*2+1] = data.positions[b.position-1] * 100
		s.positions[i*2+2] = data.positions[b.position-1] * 100
		s.positions[i*2+3] = data.positions[c.position-1] * 100
		s.positions[i*2+4] = data.positions[c.position-1] * 100
		s.positions[i*2+5] = data.positions[a.position-1] * 100
	}

	slice.fill(s.colors, GREEN)

	/* Init rotation */
	s.rotation = 1


	s.vao = gl.CreateVertexArray()
	gl.BindVertexArray(s.vao)

	input_locations_boxes(s, program)

	// gl.Enable(gl.CULL_FACE) // don't draw back faces
	// gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	attribute(s.a_position, gl.CreateBuffer(), s.positions)
	attribute(s.a_color   , gl.CreateBuffer(), s.colors)
}

@private
frame_suzanne :: proc(s: ^State_Suzanne, delta: f32) {

	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	rotation := -0.01 * delta * mouse_rel.yx
	s.rotation = mat4_rotate_x(rotation.x) * mat4_rotate_y(rotation.y) * s.rotation

	mat: mat4 = 1
	mat *= glm.mat4PerspectiveInfinite(
		fovy   = glm.radians_f32(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	mat *= glm.mat4Translate({0, 0, -900 + scale * 720})
	mat *= s.rotation

	uniform(s.u_matrix, mat)

	gl.DrawArrays(gl.LINES, 0, len(s.positions))
}
