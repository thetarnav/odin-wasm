package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

PYRAMID_TRIANGLES :: 6
PYRAMID_VERTICES  :: PYRAMID_TRIANGLES * 3

pyramid_colors: [PYRAMID_VERTICES]RGBA = {
	BLUE,   BLUE,   BLUE,   // 0
	BLUE,   BLUE,   BLUE,   // 1
	YELLOW, YELLOW, YELLOW, // 2
	PURPLE, PURPLE, PURPLE, // 3
	RED,    RED,    RED,    // 4
	ORANGE, ORANGE, ORANGE, // 5
}

write_pyramid_positions :: proc(dst: []Vec, x, y, z, h: f32) {
	assert(len(dst) == PYRAMID_VERTICES)

	positions: [PYRAMID_VERTICES]Vec = {
		{x, y, z},   {x+h, y, z}, {x,   y, z+h},
		{x, y, z+h}, {x+h, y, z}, {x+h, y, z+h},

		{x,   y, z},   {x+h/2, y+h, z+h/2}, {x+h, y, z},
		{x+h, y, z},   {x+h/2, y+h, z+h/2}, {x+h, y, z+h},
		{x+h, y, z+h}, {x+h/2, y+h, z+h/2}, {x,   y, z+h},
		{x,   y, z+h}, {x+h/2, y+h, z+h/2}, {x,   y, z},
	}
	for &vec in positions {
		vec -= {0.5, 0.5, 0.5} * h
	}
	copy(dst, positions[:])
}

@(private="file") HEIGHT   :: 60
@(private="file") AMOUNT   :: 10
@(private="file") VERTICES :: AMOUNT * PYRAMID_VERTICES

@(private="file") state: struct {
	rotation:   [2]f32,
	u_matrix:   i32,
	vao:        VAO,
}

look_at_start :: proc(program: gl.Program) {
	using state

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

	positions: [VERTICES]Vec
	colors   : [VERTICES]RGBA

	for i in 0..<AMOUNT {
		angle := 2*PI * f32(i)/f32(AMOUNT)

		write_pyramid_positions(
			positions[i*PYRAMID_VERTICES:][:PYRAMID_VERTICES],
			x = 300 * cos(angle),
			y = 0,
			z = 300 * sin(angle),
			h = HEIGHT,
		)
		
		copy(colors[i*PYRAMID_VERTICES:][:PYRAMID_VERTICES], pyramid_colors[:])
	}

	gl.BindBuffer(gl.ARRAY_BUFFER, positions_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, positions[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_position, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, colors_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, colors[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_color, 4, gl.UNSIGNED_BYTE, true, 0, 0)
}

look_at_frame :: proc(delta: f32) {
	using state

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

	gl.DrawArrays(gl.TRIANGLES, 0, VERTICES)
}
