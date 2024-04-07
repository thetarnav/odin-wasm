package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

@(private="file") BOX_HEIGHT :: 60

@(private="file") BOXES_ROWS   :: 3
@(private="file") BOXES_AMOUNT :: BOXES_ROWS * BOXES_ROWS * BOXES_ROWS

@(private="file") boxes_state: struct {
	rotation:   [2]f32,
	u_matrix:   i32,
	vao:        VAO,
}

@(private="file") cube_colors: [CUBE_VERTICES]RGBA = {
	GREEN,  GREEN,  GREEN,  // 0
	GREEN,  GREEN,  GREEN,  // 1
	YELLOW, YELLOW, YELLOW, // 2
	YELLOW, YELLOW, YELLOW, // 3
	BLUE,   BLUE,   BLUE,   // 4
	BLUE,   BLUE,   BLUE,   // 5
	RED,    RED,    RED,    // 6
	RED,    RED,    RED,    // 7
	ORANGE, ORANGE, ORANGE, // 8
	ORANGE, ORANGE, ORANGE, // 9
	PURPLE, PURPLE, PURPLE, // 10
	PURPLE, PURPLE, PURPLE, // 11
}

boxes_start :: proc(program: gl.Program) {
	using boxes_state

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

	positions: [BOXES_AMOUNT * CUBE_VERTICES]Vec
	colors   : [BOXES_AMOUNT * CUBE_VERTICES]RGBA

	for i in 0..<BOXES_AMOUNT {
		cube_positions := get_cube_positions(
			pos = {
				100 * f32(i % BOXES_ROWS)              - 100,
				100 * f32(i / BOXES_ROWS % BOXES_ROWS) - 100,
				100 * f32(i / BOXES_ROWS / BOXES_ROWS) - 100,
			},
			h   = BOX_HEIGHT,
		)
		copy(positions[i*CUBE_VERTICES:][:CUBE_VERTICES], cube_positions[:])
		copy(colors[i*CUBE_VERTICES:][:CUBE_VERTICES], cube_colors[:])
	}

	gl.BindBuffer(gl.ARRAY_BUFFER, positions_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, positions[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_position, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, colors_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, colors[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_color, 4, gl.UNSIGNED_BYTE, true, 0, 0)
}

boxes_frame :: proc(delta: f32) {
	using boxes_state

	gl.BindVertexArray(vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0.01, 0.02, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	rotation += 0.01 * delta * (window_size.yx / 2 - mouse_pos.yx) / window_size.yx

	mat: Mat4 = 1
	mat *= glm.mat4PerspectiveInfinite(
		fovy   = glm.radians_f32(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	mat *= glm.mat4Translate({0, 0, -900 + scale * 720})
	mat *= mat4_rotate_x(rotation.x)
	mat *= mat4_rotate_y(rotation.y)

	gl.UniformMatrix4fv(u_matrix, mat)

	gl.DrawArrays(gl.TRIANGLES, 0, CUBE_VERTICES * BOXES_AMOUNT)
}
