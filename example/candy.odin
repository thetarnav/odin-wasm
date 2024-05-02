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
	vao      : VAO,
	positions: []vec3,
	colors   : []u8vec4,
}

Object :: struct {
	using uniforms: Uniform_Values_Candy,
	shape         : Shape,
	rotation      : vec3,
	rotation_speed: vec3,
	translation   : vec3,
	scale         : f32,
}


@private
setup_candy :: proc(s: ^State_Candy, program: gl.Program) {
	gl.Enable(gl.CULL_FACE)
	gl.Enable(gl.DEPTH_TEST)


	/*
	Cube
	*/
	cube_shape: Shape

	cube_positions := get_cube_positions()
	cube_shape.positions = cube_positions[:]
	
	cube_shape.colors = make([]u8vec4, len(cube_positions))
	rand_colors_gray(cube_shape.colors)

	cube_shape.vao = gl.CreateVertexArray()
	gl.BindVertexArray(cube_shape.vao)

	input_locations_candy(&cube_shape, program)

	attribute(cube_shape.a_position, gl.CreateBuffer(), cube_shape.positions)
	attribute(cube_shape.a_color   , gl.CreateBuffer(), cube_shape.colors)


	/*
	Pyramid
	*/
	pyramid_shape: Shape

	pyramid_positions := get_pyramid_positions()
	pyramid_shape.positions = pyramid_positions[:]

	pyramid_shape.colors = make([]u8vec4, len(pyramid_positions))
	rand_colors_gray(pyramid_shape.colors)

	pyramid_shape.vao = gl.CreateVertexArray()
	gl.BindVertexArray(pyramid_shape.vao)

	input_locations_candy(&pyramid_shape, program)

	attribute(pyramid_shape.a_position, gl.CreateBuffer(), pyramid_shape.positions)
	attribute(pyramid_shape.a_color   , gl.CreateBuffer(), pyramid_shape.colors)


	/*
	Sphere
	*/

	sphere_shape: Shape

	segments :: 6
	sphere_vertices  := get_sphere_vertices(segments)
	sphere_shape.positions = make([]vec3, sphere_vertices)
	sphere_normals        := make([]vec3, sphere_vertices)
	get_sphere_base_triangle(sphere_shape.positions, sphere_normals, 1, segments)

	sphere_shape.colors = make([]u8vec4, sphere_vertices)
	rand_colors_gray(sphere_shape.colors)

	sphere_shape.vao = gl.CreateVertexArray()
	gl.BindVertexArray(sphere_shape.vao)

	input_locations_candy(&sphere_shape, program)

	attribute(sphere_shape.a_position, gl.CreateBuffer(), sphere_shape.positions)
	attribute(sphere_shape.a_color   , gl.CreateBuffer(), sphere_shape.colors)

	/*
	Objects
	*/
	s.objects = make([]Object, 60)

	oi := 0
	for &o in s.objects[oi:oi+20] {
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
		o.scale = rand.float32_range(30, 60)
		o.u_color_mult = rgba_to_vec4(rand_color())
		o.u_local = 1
		o.u_view  = 1
	}
	oi += 20

	for &o in s.objects[oi:oi+20] {
		o.shape = pyramid_shape
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
		o.scale = rand.float32_range(30, 60)
		o.u_color_mult = rgba_to_vec4(rand_color())
		o.u_local = 1
		o.u_view  = 1
	}
	oi += 20

	for &o in s.objects[oi:oi+20] {
		o.shape = sphere_shape
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
		o.scale = rand.float32_range(20, 40)
		o.u_color_mult = rgba_to_vec4(rand_color())
		o.u_local = 1
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
		o.rotation += o.rotation_speed * delta * 0.002
		o.u_local = mat4_translate(o.translation) * mat4_rotate_vec(o.rotation) * mat4_scale(o.scale)
		o.u_view  = view_mat

		gl.BindVertexArray(o.shape.vao)

		uniform(o.shape.u_view,       o.u_view)
		uniform(o.shape.u_local,      o.u_local)
		uniform(o.shape.u_color_mult, o.u_color_mult)

		gl.DrawArrays(gl.TRIANGLES, 0, len(o.shape.positions))
	}
}
