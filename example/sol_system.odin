//+private file
package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

PLANETS_COUNT :: 1 + 1 + 4 // root + sun + planets
SPHERE_SEGMENTS :: 8

@private
State_Sol_System :: struct {
	planets     : [PLANETS_COUNT]Planet,
	rotation    : [2]f32,
	shape_sphere: Shape,
}

Shape :: struct {
	using locations: Input_Locations_Sol_System,
	vao      : VAO,
	positions: []vec3,
	normals  : []vec3,
	colors   : []u8vec4,
}

Planet :: struct {
	using uniforms: Uniform_Values_Sol_System,
	shape         : ^Shape,
	rotation      : f32,
	orbit_speed   : f32,
	orbit_distance: f32,
	rotation_speed: f32,
	size          : f32,
	parent_idx    : int,
	color		  : u8vec4,
}


@private
setup_sol_system :: proc(s: ^State_Sol_System, program: gl.Program) {
	gl.Enable(gl.CULL_FACE)
	gl.Enable(gl.DEPTH_TEST)

	/*
	Sphere shape
	*/

	sphere_vertices := get_sphere_vertices(SPHERE_SEGMENTS)

	s.shape_sphere = {
		positions = make([]vec3  , sphere_vertices),
		normals   = make([]vec3  , sphere_vertices),
		colors    = make([]u8vec4, sphere_vertices),
		vao       = gl.CreateVertexArray(),
	}
	
	get_sphere_base_triangle(s.shape_sphere.positions, s.shape_sphere.normals, 1, SPHERE_SEGMENTS)
	rand_colors_gray(s.shape_sphere.colors)

	gl.BindVertexArray(s.shape_sphere.vao)
	input_locations_sol_system(&s.shape_sphere, program)

	attribute(s.shape_sphere.a_position, gl.CreateBuffer(), s.shape_sphere.positions)
	attribute(s.shape_sphere.a_color   , gl.CreateBuffer(), s.shape_sphere.colors)

	/*
	Planets
	*/

	/* Sun */
	s.planets[1] = {
		shape          = &s.shape_sphere,
		orbit_speed    = 0,
		orbit_distance = 0,
		rotation_speed = 0.1,
		size           = 200,
		parent_idx     = 0,
		color		   = YELLOW,
	}

	/* Mercury */
	s.planets[2] = {
		shape          = &s.shape_sphere,
		orbit_speed    = 0.1,
		orbit_distance = 100,
		rotation_speed = 0.1,
		size           = 40,
		parent_idx     = 1,
		color          = GRAY,
	}

	/* Venus */
	s.planets[3] = {
		shape          = &s.shape_sphere,
		orbit_speed    = 0.05,
		orbit_distance = 200,
		rotation_speed = 0.1,
		size           = 30,
		parent_idx     = 1,
		color          = ORANGE,
	}

	/* Earth */
	s.planets[4] = {
		shape          = &s.shape_sphere,
		orbit_speed    = 0.03,
		orbit_distance = 300,
		rotation_speed = 0.1,
		size           = 80,
		parent_idx     = 1,
		color          = BLUE,
	}

	/* Moon */
	s.planets[5] = {
		shape          = &s.shape_sphere,
		orbit_speed    = 0.1,
		orbit_distance = 50,
		rotation_speed = 0.1,
		size           = 20,
		parent_idx     = 4,
		color          = GRAY,
	}

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


	for &planet in s.planets {
		planet.rotation += planet.rotation_speed * delta * 0.01
		planet.rotation = planet.rotation if planet.rotation < 360 else planet.rotation - 360

		
		if planet.shape != nil {
			parent := s.planets[planet.parent_idx]

			planet.u_matrix =
				view_mat *
				mat4_rotate_y(parent.orbit_speed * delta) *
				mat4_translate({parent.orbit_distance, 0, 0}) *
				mat4_rotate_y(parent.rotation) *
				mat4_rotate_y(planet.orbit_speed * delta) *
				mat4_translate({planet.orbit_distance, 0, 0}) *
				mat4_rotate_y(planet.rotation) *
				mat4_scale(planet.size)
			
			planet.u_color_mult = u8vec4_to_vec4(planet.color)

			gl.BindVertexArray(planet.shape.vao)
			uniforms_sol_system(planet.shape, planet)
			gl.DrawArrays(gl.TRIANGLES, 0, len(planet.shape.positions))
		}
	}
}
