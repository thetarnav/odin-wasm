//+private file
package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"


@private
State_Sol_System :: struct {
	objects : []Object,
	rotation: [2]f32,
}

Shape :: struct {
	using locations: Input_Locations_Sol_System,
	vao      : VAO,
	positions: []vec3,
	normals  : []vec3,
	colors   : []u8vec4,
}

Object :: struct {
	using uniforms: Uniform_Values_Sol_System,
	shape         : Shape,
	rotation      : vec3,
	rotation_speed: vec3,
	translation   : vec3,
	scale         : f32,
}


@private
setup_sol_system :: proc(s: ^State_Sol_System, program: gl.Program) {
	gl.Enable(gl.CULL_FACE)
	gl.Enable(gl.DEPTH_TEST)

	/*
	Sphere
	*/

	sphere_segments :: 6
	sphere_vertices := get_sphere_vertices(sphere_segments)

	sphere_shape: Shape = {
		positions = make([]vec3  , sphere_vertices),
		normals   = make([]vec3  , sphere_vertices),
		colors    = make([]u8vec4, sphere_vertices),
		vao       = gl.CreateVertexArray(),
	}
	
	get_sphere_base_triangle(sphere_shape.positions, sphere_shape.normals, 1, sphere_segments)
	rand_colors_gray(sphere_shape.colors)

	gl.BindVertexArray(sphere_shape.vao)
	input_locations_sol_system(&sphere_shape, program)

	attribute(sphere_shape.a_position, gl.CreateBuffer(), sphere_shape.positions)
	attribute(sphere_shape.a_color   , gl.CreateBuffer(), sphere_shape.colors)

	/*
	Objects
	*/
	s.objects = make([]Object, 60)

	/* Init rotation */
	s.rotation = 1
}

@private
frame_sol_system :: proc(s: ^State_Sol_System, delta: f32) {
	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	s.rotation -= 0.01 * delta * mouse_rel.yx

	view_mat: mat4 = 1
	view_mat *= glm.mat4PerspectiveInfinite(
		fovy   = glm.radians_f32(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= glm.mat4Translate({0, 0, -900 + scale * 720})
	view_mat *= mat4_rotate_x(s.rotation.x)
	view_mat *= mat4_rotate_y(s.rotation.y)

}
