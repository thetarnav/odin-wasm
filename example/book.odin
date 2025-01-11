#+private file
package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"
import     "../obj"

@private
State_Book :: struct {
	using locations: Input_Locations_Boxes,
	vao:       VAO,
	vertices:  Vertices,
	rotation:  mat4,
}

@private
setup_book :: proc(s: ^State_Book, program: gl.Program) {
	
	gl.Enable(gl.CULL_FACE)  // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	obj_data := obj.parse_file(#load("./public/book.obj", string), context.temp_allocator)
	
	s.vao = gl.CreateVertexArray()
		
	o := &obj_data.objects[0]

	s.vertices = convert_obj_vertices(o.vertices[:])
	
	extent_min, extent_max := get_extents(obj_data.positions[:])
	correct_extents(s.vertices.position[:len(s.vertices)], extent_min, extent_max, -140, 140)


	gl.BindVertexArray(s.vao)

	input_locations_boxes(&s.locations, program)

	attribute(s.a_position, gl.CreateBuffer(), s.vertices.position[:len(s.vertices)])
	attribute(s.a_color,    gl.CreateBuffer(), s.vertices.color[:len(s.vertices)])

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
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	mat *= mat4_translate({0, 0, -900 + scale * 720})
	mat *= s.rotation

	gl.BindVertexArray(s.vao)

	uniform(s.u_matrix, mat)
	
	gl.DrawArrays(gl.TRIANGLES, 0, len(s.vertices))
}
