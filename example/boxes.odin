package example

import "core:mem"
import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "../wasm/webgl"


@(private="file") CUBE_ROWS   :: 3
@(private="file") CUBE_SIDE   :: 10
@(private="file") CUBE_AMOUNT :: CUBE_ROWS * CUBE_ROWS * CUBE_ROWS

CUBE_TRIANGLES :: 6 * 2
CUBE_VERTICES  :: CUBE_TRIANGLES * 3

cube_colors: [CUBE_VERTICES*4]u8 = {
	60,  210, 0,   255, // G
	210, 210, 0,   255, // Y
	0,   80,  190, 255, // B

	60,  210, 0,   255, // G
	210, 210, 0,   255, // Y
	0,   80,  190, 255, // B
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
	0,0,0,255,
}

write_cube_positions :: proc(to: []f32, x, y, z, side: f32) {
	assert(len(to) == CUBE_VERTICES*3)

	for i in 0..<CUBE_VERTICES {
		to[i*3+0] = x + side * f32(i % 3)
		to[i*3+1] = y + side * f32(i / 3)
		to[i*3+2] = z
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

	// gl.Enable(gl.CULL_FACE) // don't draw back faces
	// gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	positions: [CUBE_AMOUNT * CUBE_VERTICES * 3]f32
	colors   : [CUBE_AMOUNT * CUBE_VERTICES * 4]u8

	for i in 0..<CUBE_AMOUNT {
		write_cube_positions(
			positions[i*CUBE_VERTICES*3 : (i+1)*CUBE_VERTICES*3],
			x = f32(i % CUBE_ROWS),
			y = f32(i / CUBE_ROWS % CUBE_ROWS),
			z = f32(i / CUBE_ROWS / CUBE_ROWS),
			side = CUBE_SIDE,
		)
		mem.copy_non_overlapping(&colors[i*CUBE_VERTICES*4], &cube_colors, CUBE_VERTICES*4)
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
	// mat *= glm.mat4Translate(vec2_to_vec3(mouse_pos - canvas_pos))
	// mat *= glm.mat4Scale(scale)
	// mat *= mat4_rotate_y(-rotation_y)
	// mat *= mat4_rotate_x(rotation_x)
	// mat *= glm.mat4Translate({0, -CUBE_SIDE / 2, 0})

	gl.UniformMatrix4fv(u_matrix, mat)

	gl.DrawArrays(gl.TRIANGLES, 0, CUBE_VERTICES)
}
