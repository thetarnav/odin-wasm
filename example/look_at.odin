package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

@(private="file") HEIGHT         :: 60
@(private="file") RADIUS         :: 260
@(private="file") CUBE_ELEVATION :: 140
@(private="file") AMOUNT         :: 10
@(private="file") ALL_PYRAMID_VERTICES :: AMOUNT * PYRAMID_VERTICES
@(private="file") ALL_VERTICES :: ALL_PYRAMID_VERTICES + CUBE_VERTICES

@(private="file") look_at_state: struct {
	rotation: [2]f32,
	u_matrix: i32,
	vao:      VAO,
}

@(private="file") pyramid_colors: [PYRAMID_VERTICES]RGBA = {
	BLUE,   BLUE,   BLUE,   // 0
	BLUE,   BLUE,   BLUE,   // 1
	YELLOW, YELLOW, YELLOW, // 2
	PURPLE, PURPLE, PURPLE, // 3
	RED,    RED,    RED,    // 4
	ORANGE, ORANGE, ORANGE, // 5
}

@(private="file") cube_colors: [CUBE_VERTICES]RGBA = {
	WHITE, WHITE, WHITE, // 0
	WHITE, WHITE, WHITE, // 1
	WHITE, WHITE, WHITE, // 2
	WHITE, WHITE, WHITE, // 3
	WHITE, WHITE, WHITE, // 4
	WHITE, WHITE, WHITE, // 5
	WHITE, WHITE, WHITE, // 6
	WHITE, WHITE, WHITE, // 7
	WHITE, WHITE, WHITE, // 8
	WHITE, WHITE, WHITE, // 9
	WHITE, WHITE, WHITE, // 10
	WHITE, WHITE, WHITE, // 11
}

look_at_start :: proc(program: gl.Program) {
	using look_at_state

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
		angle := 2*PI * f32(i)/f32(AMOUNT)

		write_pyramid_positions(
			positions[i*PYRAMID_VERTICES:][:PYRAMID_VERTICES],
			x = RADIUS * cos(angle),
			y = 0,
			z = RADIUS * sin(angle),
			h = HEIGHT,
		)
		
		copy(colors[i*PYRAMID_VERTICES:][:PYRAMID_VERTICES], pyramid_colors[:])
	}

	/* Cube */
	write_cube_positions(
		positions[ALL_PYRAMID_VERTICES:][:CUBE_VERTICES],
		x = 0,
		y = CUBE_ELEVATION,
		z = -RADIUS,
		h = HEIGHT,
	)
	copy(colors[ALL_PYRAMID_VERTICES:][:CUBE_VERTICES], cube_colors[:])

	gl.BindBuffer(gl.ARRAY_BUFFER, positions_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, positions[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_position, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, colors_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, colors[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_color, 4, gl.UNSIGNED_BYTE, true, 0, 0)
}

look_at_frame :: proc(delta: f32) {
	using look_at_state

	gl.BindVertexArray(vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0.01, 0.02, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	rotation += 0.01 * delta * (window_size.yx / 2 - mouse_pos.yx) / window_size.yx

	camera_mat := mat4_rotate_y(-rotation.y)
	camera_mat *= mat4_rotate_x(-rotation.x)
	camera_mat *= mat4_translate({0, 0, 800 - 700 * (scale/1.2)})
	camera_mat = glm.inverse_mat4(camera_mat)

	mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	mat *= camera_mat

	// mat *= mat4_translate({0, 0, -1000 + scale * 800})
	// mat *= mat4_rotate_x(rotation.x)
	// mat *= mat4_rotate_y(rotation.y)

	gl.UniformMatrix4fv(u_matrix, mat)

	gl.DrawArrays(gl.TRIANGLES, 0, ALL_VERTICES)
}
