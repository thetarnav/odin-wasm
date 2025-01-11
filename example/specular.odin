#+private file
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
	using locations: Input_Locations_Specular,
	vao       : VAO,
	cube_angle: f32,
	ball_angle: f32,
	positions : [ALL_VERTICES]vec3,
	normals   : [ALL_VERTICES]vec3,
	colors    : [ALL_VERTICES]rgba,
}

@private
setup_specular :: proc(s: ^State_Specular, program: gl.Program) {
	s.vao = gl.CreateVertexArray()
	gl.BindVertexArray(s.vao)

	input_locations_specular(s, program)

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
	copy_pattern(ball_colors, []rgba{PURPLE, CYAN, CYAN, PURPLE, CYAN, PURPLE})

	attribute(s.a_position, gl.CreateBuffer(), s.positions[:])
	attribute(s.a_normal  , gl.CreateBuffer(), s.normals[:])
	attribute(s.a_color   , gl.CreateBuffer(), s.colors[:])

	uniform(s.u_light_color, rgba_to_vec4(WHITE))
}

@private
frame_specular :: proc(s: ^State_Specular, delta: f32) {
	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	eye_pos := vec3{0, 0, 500 - 500 * (scale-0.5)}

	eye_mat := mat4(1)
	eye_mat *= mat4_translate(eye_pos)
	eye_mat  = glm.inverse_mat4(eye_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= eye_mat

	s.cube_angle += 0.01 * delta * mouse_rel.x

	cube_pos: vec3
	cube_pos.y = 500 * -mouse_rel.y
	cube_pos.x = CUBE_RADIUS * cos(s.cube_angle)
	cube_pos.z = CUBE_RADIUS * sin(s.cube_angle)

	cube_mat := mat4(1)
	cube_mat *= mat4_translate(cube_pos)
	cube_mat *= mat4_rotate_y(s.cube_angle)


	uniform(s.u_light_pos, cube_pos)
	uniform(s.u_eye_pos,   eye_pos)
	uniform(s.u_view,      view_mat)

	/* Draw cube */
	uniform(s.u_local, cube_mat)
	gl.DrawArrays(gl.TRIANGLES, 0, CUBE_VERTICES)

	/* Draw sphere */
	s.ball_angle += 0.0002 * delta
	uniform(s.u_local, mat4_rotate_y(s.ball_angle) * mat4_rotate_x(s.ball_angle))
	gl.DrawArrays(gl.TRIANGLES, CUBE_VERTICES, BALL_VERTICES)
}
