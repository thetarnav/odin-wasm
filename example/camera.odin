#+private file
package example

import "core:slice"
import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

ALL_PYRAMID_VERTICES :: AMOUNT * PYRAMID_VERTICES
ALL_VERTICES :: ALL_PYRAMID_VERTICES + CUBE_VERTICES

PYRAMID_COLORS: [PYRAMID_VERTICES]rgba : {
	BLUE,   BLUE,   BLUE,   // 0
	BLUE,   BLUE,   BLUE,   // 1
	YELLOW, YELLOW, YELLOW, // 2
	PURPLE, PURPLE, PURPLE, // 3
	RED,    RED,    RED,    // 4
	ORANGE, ORANGE, ORANGE, // 5
}

@private
State_Camera :: struct {
	using locations: Input_Locations_Boxes,
	vao:      VAO,
	rotation: f32,
}

HEIGHT :: 80
RING_RADIUS :: 260
CUBE_RADIUS :: 220
AMOUNT :: 10

@private
setup_camera :: proc(s: ^State_Camera, program: gl.Program) {
	s.vao = gl.CreateVertexArray()
	gl.BindVertexArray(s.vao)

	input_locations_boxes(s, program)

	gl.Enable(gl.CULL_FACE) // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	positions: [ALL_VERTICES]vec3
	colors   : [ALL_VERTICES]rgba

	/* Pyramids */
	for i in 0..<AMOUNT {
		// Position of the pyramids is 0
		// because they will be moved with the matrix
		copy_array(positions[i*PYRAMID_VERTICES:], get_pyramid_positions(0, HEIGHT))
		copy_array(colors[i*PYRAMID_VERTICES:], PYRAMID_COLORS)
	}

	/* Cube */
	copy_array(positions[ALL_PYRAMID_VERTICES:], get_cube_positions(0, HEIGHT))
	slice.fill(colors[ALL_PYRAMID_VERTICES:], WHITE)

	attribute(s.a_position, gl.CreateBuffer(), positions[:])
	attribute(s.a_color   , gl.CreateBuffer(), colors[:])
}

@private
frame_camera :: proc(s: ^State_Camera, delta: f32) {

	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	camera_mat: mat4 = 1
	camera_mat *= mat4_translate({0, 0, 800 - 700 * (scale/1.2)})
	camera_mat = glm.inverse_mat4(camera_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= camera_mat

	s.rotation += 0.01 * delta * mouse_rel.x
	elevation  := 300 * -(mouse_rel.y - 0.5)

	cube_pos: vec3
	cube_pos.y = elevation
	cube_pos.x = CUBE_RADIUS * cos(s.rotation)
	cube_pos.z = CUBE_RADIUS * sin(s.rotation)

	for i in 0..<AMOUNT {
		/* Draw pyramid looking at the cube */

		angle := 2*PI * f32(i)/f32(AMOUNT)
		eye   := vec3_on_radius(RING_RADIUS, angle, -80)

		mat := view_mat
		mat *= mat4_look_at(
			eye    = eye,
			target = cube_pos,
			up     = {0, 1, 0},
		)
		mat *= mat4_rotate_x(PI/2)

		uniform(s.u_matrix, mat)
		gl.DrawArrays(gl.TRIANGLES, i*PYRAMID_VERTICES, PYRAMID_VERTICES)
	}

	{ /* Draw cube */
		mat := view_mat
		mat *= mat4_translate(cube_pos)
		mat *= mat4_rotate_y(s.rotation)
		uniform(s.u_matrix, mat)
		gl.DrawArrays(gl.TRIANGLES, ALL_PYRAMID_VERTICES, CUBE_VERTICES)
	}
}
