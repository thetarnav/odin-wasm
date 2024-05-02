//+private file
package example

import glm "core:math/linalg/glsl"
import "core:math/rand"
import gl  "../wasm/webgl"


@private
State_Candy :: struct {
	objects: []Object,
}

Shape :: struct {
	using locations: Input_Locations_Candy,
	vao:       VAO,
	positions: []vec3,
	colors:    []u8vec4,
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
	gl.Enable(gl.CULL_FACE)
	gl.Enable(gl.DEPTH_TEST)


	/*
	Cube
	*/
	cube_shape: Shape

	cube_positions := get_cube_positions(0, 60)
	cube_shape.positions = cube_positions[:]
	
	cube_shape.colors = make([]u8vec4, len(cube_positions))
	for &color in cube_shape.colors {
		color = rand_color()
	}

	cube_shape.vao = gl.CreateVertexArray()
	gl.BindVertexArray(cube_shape.vao)

	input_locations_candy(&cube_shape, program)

	attribute(cube_shape.a_position, gl.CreateBuffer(), cube_shape.positions)
	attribute(cube_shape.a_color   , gl.CreateBuffer(), cube_shape.colors)


	/*
	Objects
	*/
	s.objects = make([]Object, 20)
	for &o in s.objects {
		o.shape = cube_shape
		o.translation = {
			rand.float32_range(-200, 200),
			rand.float32_range(-200, 200),
			rand.float32_range(-200, 200),
		}
		o.rotation_speed = {
			rand.float32_range(-1, 1),
			rand.float32_range(-1, 1),
			rand.float32_range(-1, 1),
		}
		o.u_color_mult = rgba_to_vec4(rand_color())
		o.u_local = mat4_translate(o.translation)
		o.u_view  = 1
	}
}

@private
frame_candy :: proc(s: ^State_Candy, delta: f32) {
	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)


	camera_pos: vec3 = {0, 0, 500 - 500 * (scale-0.5)}

	camera_mat: mat4 = 1
	camera_mat *= mat4_translate(camera_pos)
	camera_mat = glm.inverse_mat4(camera_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= camera_mat


	for &o in s.objects {
		o.u_local *= mat4_rotate_vec(delta * 0.002 * o.rotation_speed)
		o.u_view   = view_mat

		gl.BindVertexArray(o.shape.vao)

		uniform(o.shape.u_view,       o.u_view)
		uniform(o.shape.u_local,      o.u_local)
		uniform(o.shape.u_color_mult, o.u_color_mult)

		gl.DrawArrays(gl.TRIANGLES, 0, len(o.shape.positions))
	}
}
