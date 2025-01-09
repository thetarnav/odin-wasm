#+private file
package example

import glm "core:math/linalg/glsl"
import     "core:strings"
import gl  "../wasm/webgl"
import     "../obj"

@private
State_Book :: struct {
	using locations: Input_Locations_Boxes,
	vao:       VAO,
	positions: []vec3,
	colors:    []u8vec4,
	rotation:  mat4,
}

@private
setup_book :: proc(s: ^State_Book, program: gl.Program) {
	
	gl.Enable(gl.CULL_FACE)  // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	data := obj.data_make(context.temp_allocator)
	obj_file := #load("./public/book.obj", string)
	
	for line in strings.split_lines_iterator(&obj_file) {
		obj.parse_line(&data, line)
	}

	s.vao = gl.CreateVertexArray()

	vertices := obj.object_to_triangles(data, data.objects[0], context.allocator)
	
	s.positions = vertices.pos[:len(vertices)]
	for &pos in s.positions {
		pos *= 1000
	}
	
	s.colors = make([]rgba, len(vertices))
	for &col, i in s.colors {
		col = to_rgba(vertices[i].col)
	}


	gl.BindVertexArray(s.vao)

	input_locations_boxes(&s.locations, program)

	attribute(s.a_position, gl.CreateBuffer(), s.positions)
	attribute(s.a_color   , gl.CreateBuffer(), s.colors)

	/* Init rotation */
	s.rotation = 1
}

@private
frame_book :: proc(s: ^State_Book, delta: f32) {

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

	gl.BindVertexArray(s.vao)

	uniform(s.u_matrix, mat)
	
	gl.DrawArrays(gl.TRIANGLES, 0, len(s.positions))
}
