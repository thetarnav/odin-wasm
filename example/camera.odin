//+private file
package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

ALL_PYRAMID_VERTICES :: AMOUNT * PYRAMID_VERTICES
ALL_VERTICES :: ALL_PYRAMID_VERTICES + CUBE_VERTICES

PYRAMID_COLORS: [PYRAMID_VERTICES]RGBA : {
	BLUE,   BLUE,   BLUE,   // 0
	BLUE,   BLUE,   BLUE,   // 1
	YELLOW, YELLOW, YELLOW, // 2
	PURPLE, PURPLE, PURPLE, // 3
	RED,    RED,    RED,    // 4
	ORANGE, ORANGE, ORANGE, // 5
}

camera_state: struct {
	rotation: f32,
	u_matrix: i32,
	vao:      VAO,
}

HEIGHT :: 80
RING_RADIUS :: 260
CUBE_RADIUS :: 220
AMOUNT :: 10

@(private="package")
camera_start :: proc(program: gl.Program) {
	using camera_state

	vao = gl.CreateVertexArray()
	gl.BindVertexArray(vao)

	a_position := gl.GetAttribLocation (program, "a_position")
	a_color    := gl.GetAttribLocation (program, "a_color")
	u_matrix    = gl.GetUniformLocation(program, "u_matrix")

	gl.EnableVertexAttribArray(a_position)
	gl.EnableVertexAttribArray(a_color)

	positions_buffer := gl.CreateBuffer()
	colors_buffer    := gl.CreateBuffer()

	gl.Enable(gl.CULL_FACE) // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	positions: [ALL_VERTICES]Vec
	colors   : [ALL_VERTICES]RGBA

	/* Pyramids */
	for i in 0..<AMOUNT {
		// Position of the pyramids is 0
		// because they will be moved with the matrix
		copy_array(positions[i*PYRAMID_VERTICES:], get_pyramid_positions(0, HEIGHT))
		copy_array(colors[i*PYRAMID_VERTICES:], PYRAMID_COLORS)
	}

	/* Cube */
	copy_array(positions[ALL_PYRAMID_VERTICES:], get_cube_positions(0, HEIGHT))
	copy_array(colors[ALL_PYRAMID_VERTICES:], WHITE_CUBE_COLORS)

	gl.BindBuffer(gl.ARRAY_BUFFER, positions_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, positions[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_position, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, colors_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, colors[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_color, 4, gl.UNSIGNED_BYTE, true, 0, 0)
}

@(private="package")
camera_frame :: proc(delta: f32) {
	using camera_state

	gl.BindVertexArray(vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0.01, 0.02, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	camera_mat: Mat4 = 1
	camera_mat *= mat4_translate({0, 0, 800 - 700 * (scale/1.2)})
	camera_mat = glm.inverse_mat4(camera_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= camera_mat

	rotation  += 0.01 * delta * mouse_rel.x
	elevation := 300 * -(mouse_rel.y - 0.5)

	cube_pos: Vec
	cube_pos.y = elevation
	cube_pos.x = CUBE_RADIUS * cos(rotation)
	cube_pos.z = CUBE_RADIUS * sin(rotation)

	for i in 0..<AMOUNT {
		/* Draw pyramid looking at the cube */

		angle := 2*PI * f32(i)/f32(AMOUNT)
		y: f32 = -80
		x: f32 = RING_RADIUS * cos(angle)
		z: f32 = RING_RADIUS * sin(angle)

		mat := view_mat
		mat *= mat4_look_at(
			eye    = {x, y, z},
			target = cube_pos,
			up     = {0, 1, 0},
		)
		mat *= mat4_rotate_x(PI/2)

		gl.UniformMatrix4fv(u_matrix, mat)
		gl.DrawArrays(gl.TRIANGLES, i*PYRAMID_VERTICES, PYRAMID_VERTICES)
	}

	{ /* Draw cube */
		mat := view_mat
		mat *= mat4_translate(cube_pos)
		mat *= mat4_rotate_y(rotation)
		gl.UniformMatrix4fv(u_matrix, mat)
		gl.DrawArrays(gl.TRIANGLES, ALL_PYRAMID_VERTICES, CUBE_VERTICES)
	}
}
