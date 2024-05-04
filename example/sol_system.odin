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
	rotation_speed: f32,
	orbit_rotation: f32,
	orbit_speed   : f32,
	orbit_distance: f32,
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
		orbit_distance = 100,
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

	/*
	Progress local rotations
	*/
	for &p in s.planets {
		p.rotation += p.rotation_speed * delta * 0.01
		p.rotation = p.rotation if p.rotation < 360 else p.rotation - 360

		p.orbit_rotation += p.orbit_speed * delta * 0.01
		p.orbit_rotation = p.orbit_rotation if p.orbit_rotation < 360 else p.orbit_rotation - 360
	}

	/*
	Draw planets
	*/
	for &p in s.planets {
		if p.shape == nil do continue

		p.u_matrix = view_mat
		
		parent := s.planets[p.parent_idx]
		for {
			p.u_matrix *=
				mat4_rotate_y(parent.orbit_rotation) *
				mat4_translate({parent.orbit_distance, 0, 0}) *
				mat4_rotate_y(parent.rotation)

			if parent.parent_idx > 0 {
				parent = s.planets[parent.parent_idx]
			} else do break
		}

		p.u_matrix *=
			mat4_rotate_y(parent.orbit_rotation) *
			mat4_translate({p.orbit_distance, 0, 0}) *
			mat4_rotate_y(p.rotation) *
			mat4_scale(p.size)
		
		p.u_color_mult = u8vec4_to_vec4(p.color)

		gl.BindVertexArray(p.shape.vao)
		uniforms_sol_system(p.shape, p)
		gl.DrawArrays(gl.TRIANGLES, 0, len(p.shape.positions))
	}
}
