#+private file
package example

import glm "core:math/linalg/glsl"
import     "core:strings"
import     "core:slice"
import gl  "../wasm/webgl"
import     "../obj"

@private
State_Chair :: struct {
	rotation:  mat4,
	objects:    []Object,
}

Object :: struct {
	using locations: Input_Locations_Boxes,
	vao      : VAO,
	positions: []vec3,
	colors   : []u8vec4,
}

chair_obj_bytes := #load("./public/chair.obj", string)

@private
setup_chair :: proc(s: ^State_Chair, program: gl.Program) {

	data := obj.data_make(context.temp_allocator)
	it := chair_obj_bytes
	for line in strings.split_lines_iterator(&it) {
		obj.parse_line(&data, line)
	}

	objects: [dynamic]Object

	for object in data.objects {
		append(&objects, Object{})
		o := last(&objects)

		o.vao = gl.CreateVertexArray()

		lines := obj.object_to_lines(data, object, context.allocator)
		
		o.positions = lines.pos[:len(lines)]
		o.colors    = lines.col[:len(lines)]

		for &pos in o.positions {
			pos *= 100
		}

		slice.fill(o.colors, GREEN)


		gl.BindVertexArray(o.vao)
	
		input_locations_boxes(&o.locations, program)
	
		// gl.Enable(gl.CULL_FACE) // don't draw back faces
		// gl.Enable(gl.DEPTH_TEST) // draw only closest faces
	
		attribute(o.a_position, gl.CreateBuffer(), o.positions)
		attribute(o.a_color   , gl.CreateBuffer(), o.colors)
	}

	s.objects = objects[:]

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

	

	for &o in s.objects {

		gl.BindVertexArray(o.vao)

		uniform(o.u_matrix, mat)
		
		gl.DrawArrays(gl.LINES, 0, len(o.positions))
	}

}
