package example

import glm "core:math/linalg/glsl"
import gl "../wasm/webgl"

@(private="file") BOX_HEIGHT :: 100

@(private="file") BOXES_ROWS   :: 3
@(private="file") BOXES_AMOUNT :: BOXES_ROWS * BOXES_ROWS * BOXES_ROWS

CUBE_TRIANGLES :: 6 * 2
CUBE_VERTICES  :: CUBE_TRIANGLES * 3

cube_colors: [CUBE_VERTICES]RGBA = {
	{60, 210, 0, 255}, // 0
	{60, 210, 0, 255}, // Green
	{60, 210, 0, 255}, // 
	{60, 210, 0, 255}, // 1
	{60, 210, 0, 255}, // Green
	{60, 210, 0, 255}, // 

	{210, 210, 0, 255}, // 2
	{210, 210, 0, 255}, // Yellow
	{210, 210, 0, 255}, //
	{210, 210, 0, 255}, // 3
	{210, 210, 0, 255}, // Yellow
	{210, 210, 0, 255}, //

	{0, 80, 190, 255}, // 4
	{0, 80, 190, 255}, // Blue
	{0, 80, 190, 255}, //
	{0, 80, 190, 255}, // 5
	{0, 80, 190, 255}, // Blue
	{0, 80, 190, 255}, //

	{230, 20, 0, 255}, // 6 
	{230, 20, 0, 255}, // Red
	{230, 20, 0, 255}, //
	{230, 20, 0, 255}, // 7
	{230, 20, 0, 255}, // Red
	{230, 20, 0, 255}, //

	{250, 160, 50, 255}, // 8
	{250, 160, 50, 255}, // Orange
	{250, 160, 50, 255}, //
	{250, 160, 50, 255}, // 9
	{250, 160, 50, 255}, // Orange
	{250, 160, 50, 255}, //

	{160, 100, 200, 255}, // 10
	{160, 100, 200, 255}, // Purple
	{160, 100, 200, 255}, //
	{160, 100, 200, 255}, // 11
	{160, 100, 200, 255}, // Purple
	{160, 100, 200, 255}, //
}

cube_positions: [CUBE_VERTICES]Vec = {
	{0, 0, 0}, // 0
	{0, 0, 1},
	{1, 0, 0},

	{0, 0, 1}, // 1
	{1, 0, 1},
	{1, 0, 0},

	{0, 0, 1}, // 2
	{0, 1, 1},
	{1, 0, 1},

	{0, 1, 1}, // 3
	{1, 1, 1},
	{1, 0, 1},

	{0, 0, 0}, // 4
	{0, 1, 1},
	{0, 0, 1},

	{0, 0, 0}, // 5
	{0, 1, 0},
	{0, 1, 1},

	{1, 0, 0}, // 6
	{1, 0, 1},
	{1, 1, 1},

	{1, 0, 0}, // 7
	{1, 1, 1},
	{1, 1, 0},

	{0, 0, 0}, // 8
	{1, 0, 0},
	{1, 1, 0},

	{0, 0, 0}, // 9
	{1, 1, 0},
	{0, 1, 0},

	{0, 1, 0}, // 10
	{1, 1, 1},
	{0, 1, 1},
	
	{0, 1, 0}, // 11
	{1, 1, 0},
	{1, 1, 1},
}

write_cube_positions :: proc(to: []Vec, x, y, z, h: f32) {
	assert(len(to) == CUBE_VERTICES)
	copy(to, cube_positions[:])
	for &vec in to {
		vec *= h
		vec.x += x
		vec.y += y
		vec.z += z
	}
}


@(private="file") state: struct {
	rotation_y:       f32,
	rotation_x:       f32,
	a_position:       i32,
	a_color:          i32,
	u_matrix:         i32,
	vao:              gl.VertexArrayObject,
}

boxes_start :: proc(program: gl.Program) {
	using state

	vao = gl.CreateVertexArray()
	gl.BindVertexArray(vao)

	a_position = gl.GetAttribLocation (program, "a_position")
	a_color    = gl.GetAttribLocation (program, "a_color")
	u_matrix   = gl.GetUniformLocation(program, "u_matrix")

	gl.EnableVertexAttribArray(a_position)
	gl.EnableVertexAttribArray(a_color)

	positions_buffer := gl.CreateBuffer()
	colors_buffer    := gl.CreateBuffer()

	gl.Enable(gl.CULL_FACE) // don't draw back faces
	// gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	positions: [BOXES_AMOUNT * CUBE_VERTICES]Vec
	colors   : [BOXES_AMOUNT * CUBE_VERTICES]RGBA

	for i in 0..<BOXES_AMOUNT {
		write_cube_positions(
			positions[i*CUBE_VERTICES:][:CUBE_VERTICES],
			x = f32(i % BOXES_ROWS),
			y = f32(i / BOXES_ROWS % BOXES_ROWS),
			z = f32(i / BOXES_ROWS / BOXES_ROWS),
			h = BOX_HEIGHT,
		)
		copy(colors[i*CUBE_VERTICES:][:CUBE_VERTICES], cube_colors[:])
	}

	gl.BindBuffer(gl.ARRAY_BUFFER, positions_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, positions[:CUBE_VERTICES*3], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_position, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, colors_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, colors[:CUBE_VERTICES*4], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_color, 4, gl.UNSIGNED_BYTE, true, 0, 0)
}

boxes_frame :: proc(delta: f32) {
	using state

	gl.BindVertexArray(vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0.01, 0.02, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	rotation_y += 0.01 * delta * (window_size.x / 2 - mouse_pos.x) / window_size.x
	rotation_x += 0.01 * delta * (window_size.y / 2 - mouse_pos.y) / window_size.y

	mat := glm.mat4Ortho3d(
		left = 0,
		right = canvas_size.x,
		bottom = canvas_size.y,
		top = 0,
		near = -1000,
		far = 1000,
	)
	mat *= glm.mat4Translate(vec2_to_vec3(mouse_pos - canvas_pos))
	mat *= glm.mat4Scale(scale)
	mat *= mat4_rotate_y(rotation_y)
	mat *= mat4_rotate_x(-rotation_x)
	mat *= glm.mat4Translate(Vec{1, 1, 1} * -BOX_HEIGHT/2)

	gl.UniformMatrix4fv(u_matrix, mat)

	gl.DrawArrays(gl.TRIANGLES, 0, CUBE_VERTICES)
}
