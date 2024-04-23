//+private file
package example

import "core:slice"
import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"


BALL_SEGMENTS :: 16
BALL_VERTICES :: BALL_SEGMENTS * BALL_SEGMENTS * 6
ALL_VERTICES  :: CUBE_VERTICES + BALL_VERTICES

CUBE_HEIGHT :: 80
CUBE_RADIUS :: 300
BALL_RADIUS :: 200

@private
State_Specular :: struct {
	cube_angle   : f32,
	ball_angle   : f32,
	u_view       : Uniform_mat4,
	u_local      : Uniform_mat4,
	u_light_pos  : Uniform_vec3,
	u_light_color: Uniform_vec4,
	u_eye_pos	 : Uniform_vec3,
	vao          : VAO,
	positions    : [ALL_VERTICES]vec3,
	normals      : [ALL_VERTICES]vec3,
	colors       : [ALL_VERTICES]RGBA,
}

@private
setup_specular :: proc(s: ^State_Specular, program: gl.Program) {

	s.vao = gl.CreateVertexArray()
	gl.BindVertexArray(s.vao)

	a_position := attribute_location_vec3(program, "a_position")
	a_normal   := attribute_location_vec3(program, "a_normal")
	a_color    := attribute_location_vec4(program, "a_color")

	s.u_view        = uniform_location_mat4(program, "u_view")
	s.u_local       = uniform_location_mat4(program, "u_local")
	s.u_light_pos   = uniform_location_vec3(program, "u_light_pos")
	s.u_light_color = uniform_location_vec4(program, "u_light_color")
	s.u_eye_pos     = uniform_location_vec3(program, "u_eye_pos")

	gl.Enable(gl.CULL_FACE) // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces


	/* Cube */
	copy_array(s.positions[:], get_cube_positions(0, CUBE_HEIGHT))
	cube_normals: [CUBE_VERTICES]vec3 = 1
	copy_array(s.normals[:], cube_normals)
	slice.fill(s.colors[:], WHITE)

	/* Sphere */
	ball_positions := s.positions[CUBE_VERTICES:]
	ball_normals   := s.normals  [CUBE_VERTICES:]
	ball_colors    := s.colors   [CUBE_VERTICES:]

	get_sphere_base_triangle(ball_positions, ball_normals, BALL_RADIUS, BALL_SEGMENTS)
	copy_pattern(ball_colors, []RGBA{PURPLE, CYAN, CYAN, PURPLE, CYAN, PURPLE})

	attribute(a_position, gl.CreateBuffer(), s.positions[:])
	attribute(a_normal  , gl.CreateBuffer(), s.normals[:])
	attribute(a_color   , gl.CreateBuffer(), s.colors[:])

	uniform(s.u_light_color, rgba_to_vec4(WHITE))
}

@private
frame_specular :: proc(s: ^State_Specular, delta: f32) {
	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	camera_pos := vec3{0, 0, 500 - 500 * (scale-0.5)}

	camera_mat: mat4 = 1
	camera_mat *= mat4_translate(camera_pos)
	camera_mat = glm.inverse_mat4(camera_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= camera_mat

	s.cube_angle += 0.01 * delta * mouse_rel.x

	cube_pos: vec3
	cube_pos.y = 500 * -mouse_rel.y
	cube_pos.x = CUBE_RADIUS * cos(s.cube_angle)
	cube_pos.z = CUBE_RADIUS * sin(s.cube_angle)

	cube_mat: mat4 = 1
	cube_mat *= mat4_translate(cube_pos)
	cube_mat *= mat4_rotate_y(s.cube_angle)


	uniform(s.u_light_pos, cube_pos)
	uniform(s.u_eye_pos, camera_pos)
	uniform(s.u_view, view_mat)

	/* Draw cube */
	uniform(s.u_local, cube_mat)
	gl.DrawArrays(gl.TRIANGLES, 0, CUBE_VERTICES)

	/* Draw sphere */
	s.ball_angle += 0.0002 * delta
	uniform(s.u_local, mat4_rotate_y(s.ball_angle) * mat4_rotate_x(s.ball_angle))
	gl.DrawArrays(gl.TRIANGLES, CUBE_VERTICES, BALL_VERTICES)
}
