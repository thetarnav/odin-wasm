#+private file
package example

import glm "core:math/linalg/glsl"
import     "core:slice"
import gl  "../wasm/webgl"
import     "../obj"

@private
State_Chair :: struct {
	rotation:  mat4,
	shapes:    []Shape,
}

Shape :: struct {
	using locations: Input_Locations_Boxes,
	vao      : VAO,
	positions: []vec3,
	colors   : []u8vec4,
}

chair_obj_bytes := #load("./public/chair.obj", string)

@private
setup_chair :: proc(s: ^State_Chair, program: gl.Program) {
	
	gl.Enable(gl.CULL_FACE)  // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	objects := obj.parse_file(#load("./public/chair.obj", string), context.temp_allocator)

	extent_min, extent_max := get_extents(objects[0].vertices.position[:len(objects[0].vertices)])
	for o in objects[1:] {
		extend_extents(&extent_min, &extent_max, o.vertices.position[:len(o.vertices)])
	}

	s.shapes = make([]Shape, len(objects))

	for &shape, i in s.shapes {
		o := objects[i]

		shape.vao = gl.CreateVertexArray()
		
		shape.positions = slice.clone(o.vertices.position[:len(o.vertices)])
		correct_extents(shape.positions, extent_min, extent_max, -200, 200)
		
		shape.colors = make([]rgba, len(shape.positions))
		slice.fill(shape.colors, rand_color())

		gl.BindVertexArray(shape.vao)
	
		input_locations_boxes(&shape.locations, program)
	
		attribute(shape.a_position, gl.CreateBuffer(), shape.positions)
		attribute(shape.a_color,    gl.CreateBuffer(), shape.colors)
	}

	/* Init rotation */
	s.rotation = 1
}

@private
frame_chair :: proc(s: ^State_Chair, delta: f32) {

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

	

	for &o in s.shapes {

		gl.BindVertexArray(o.vao)

		uniform(o.u_matrix, mat)
		
		gl.DrawArrays(gl.TRIANGLES, 0, len(o.positions))
	}

}
