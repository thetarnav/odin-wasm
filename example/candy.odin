//+private file
package example

import glm "core:math/linalg/glsl"
import "core:math/rand"
import gl  "../wasm/webgl"


@private
State_Candy :: struct {
	using locations: Input_Locations_Candy,
	objects: []Object,
}

Shape :: struct {
	positions: []vec3,
	colors:    []u8vec4,
	vao:       VAO,
}

Object :: struct {
	using uniforms: Uniform_Values_Candy,
	shape:          Shape,
	rotation_speed: vec3,
	translation:    vec3,
}

rand_color :: proc() -> u8vec4 {
	color := transmute(u8vec4)rand.uint32()
	color.a = 255
	return color
}


@private
setup_candy :: proc(s: ^State_Candy, program: gl.Program) {
	// gl.Enable(gl.CULL_FACE)
	// gl.Enable(gl.DEPTH_TEST)

	input_locations_candy(s, program)


	/*
	Cube
	*/
	cube_shape: Shape

	cube_positions := get_cube_positions()
	cube_shape.positions = cube_positions[:]
	
	cube_shape.colors = make([]u8vec4, len(cube_positions))
	for &color in cube_shape.colors {
		color = rand_color()
	}

	cube_shape.vao = gl.CreateVertexArray()
	gl.BindVertexArray(cube_shape.vao)

	attribute(s.a_position, gl.CreateBuffer(), cube_shape.positions)
	attribute(s.a_color   , gl.CreateBuffer(), cube_shape.colors)


	/*
	Objects
	*/
	s.objects = make([]Object, 20)
	for &object in s.objects {
		object.shape = cube_shape
		object.translation = {
			rand.float32_range(-20, 20),
			rand.float32_range(-20, 20),
			rand.float32_range(-20, 20),
		}
		object.rotation_speed = {rand.float32(), rand.float32(), rand.float32()}
		object.u_color_mult = rgba_to_vec4(rand_color())
		object.u_local = 1
		object.u_view  = 1
	}
}

@private
frame_candy :: proc(s: ^State_Candy, delta: f32) {
	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)


	// camera_pos := vec3{0, 0, 500 - 500 * (scale-0.5)}

	// camera_mat: mat4 = 1
	// camera_mat *= mat4_translate(camera_pos)
	// camera_mat = glm.inverse_mat4(camera_mat)

	// view_mat := glm.mat4PerspectiveInfinite(
	// 	fovy   = radians(80),
	// 	aspect = aspect_ratio,
	// 	near   = 1,
	// )
	// view_mat *= camera_mat


	for &o, i in s.objects {
		// o.u_local *= mat4_rotate_x(delta * o.rotation_speed.x)
		// o.u_local *= mat4_rotate_y(delta * o.rotation_speed.y)
		// o.u_local *= mat4_rotate_z(delta * o.rotation_speed.z)
		// o.u_local *= mat4_translate(o.translation)

		o.u_view = glm.mat4PerspectiveInfinite(
			fovy   = glm.radians_f32(80),
			aspect = aspect_ratio,
			near   = 1,
		)

		gl.BindVertexArray(o.shape.vao)

		uniform(s.u_view,       o.u_view)
		uniform(s.u_local,      o.u_local)
		uniform(s.u_color_mult, o.u_color_mult)

		gl.DrawArrays(gl.TRIANGLES, i*len(o.shape.positions), len(o.shape.positions))
	}
}
