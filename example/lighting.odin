package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

lighting_state: struct {
	rotation: f32,
	u_matrix: i32,
	vao:      VAO,
}

@(private="file") SEGMENT_TRIANGLES :: 2 * 3
@(private="file") SEGMENT_VERTICES  :: SEGMENT_TRIANGLES * 3
@(private="file") RING_SEGMENTS     :: 12
@(private="file") RING_TRIANGLES    :: RING_SEGMENTS * SEGMENT_TRIANGLES
@(private="file") RING_VERTICES     :: RING_TRIANGLES * 3
@(private="file") ALL_VERTICES      :: CUBE_VERTICES + RING_VERTICES

@(private="file") CUBE_HEIGHT :: 80
@(private="file") CUBE_RADIUS :: 300
@(private="file") RING_HEIGHT :: 30
@(private="file") RING_WIDTH  :: 40
@(private="file") RING_RADIUS :: 260


lighting_start :: proc(program: gl.Program) {
	using lighting_state

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

	/* Cube */
	copy_array(positions[:], get_cube_positions(0, CUBE_HEIGHT))
	copy_array(colors[:], WHITE_CUBE_COLORS)

	/* Ring */
	ring_positions := positions[CUBE_VERTICES:]
	ring_colors    := colors[CUBE_VERTICES:]
	
	for i in 0..<RING_SEGMENTS {
		theta0 := 2*PI * f32(i+1) / f32(RING_SEGMENTS)
		theta1 := 2*PI * f32(i  ) / f32(RING_SEGMENTS)

		out_x0 := RING_RADIUS * cos(theta0)
		out_z0 := RING_RADIUS * sin(theta0)
		out_x1 := RING_RADIUS * cos(theta1)
		out_z1 := RING_RADIUS * sin(theta1)

		in_x0 := (RING_RADIUS - RING_WIDTH) * cos(theta0)
		in_z0 := (RING_RADIUS - RING_WIDTH) * sin(theta0)
		in_x1 := (RING_RADIUS - RING_WIDTH) * cos(theta1)
		in_z1 := (RING_RADIUS - RING_WIDTH) * sin(theta1)

		copy(ring_positions[i*SEGMENT_VERTICES:], []Vec{
			{out_x0, -RING_HEIGHT/2, out_z0},
			{out_x1, -RING_HEIGHT/2, out_z1},
			{out_x1,  RING_HEIGHT/2, out_z1},
			{out_x0, -RING_HEIGHT/2, out_z0},
			{out_x1,  RING_HEIGHT/2, out_z1},
			{out_x0,  RING_HEIGHT/2, out_z0},
	
			{out_x0,  RING_HEIGHT/2, out_z0},
			{out_x1,  RING_HEIGHT/2, out_z1},
			{in_x0 ,  0            , in_z0 },
			{in_x0 ,  0            , in_z0 },
			{out_x1,  RING_HEIGHT/2, out_z1},
			{in_x1 ,  0            , in_z1 },

			{in_x0 ,  0            , in_z0 },
			{in_x1 ,  0            , in_z1 },
			{out_x1, -RING_HEIGHT/2, out_z1},
			{in_x0 ,  0            , in_z0 },
			{out_x1, -RING_HEIGHT/2, out_z1},
			{out_x0, -RING_HEIGHT/2, out_z0},
		})

		copy(ring_colors[i*SEGMENT_VERTICES:], []RGBA{
			RED, RED, RED,
			RED, RED, RED,
	
			BLUE, BLUE, BLUE,
			BLUE, BLUE, BLUE,

			GREEN, GREEN, GREEN,
			GREEN, GREEN, GREEN,
		})	
	}


	gl.BindBuffer(gl.ARRAY_BUFFER, positions_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, positions[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_position, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, colors_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, colors[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_color, 4, gl.UNSIGNED_BYTE, true, 0, 0)
}

lighting_frame :: proc(delta: f32) {
	using lighting_state

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
	elevation := -100 + 300 * -(mouse_rel.y - 0.5)

	cube_pos: Vec
	cube_pos.y = elevation
	cube_pos.x = CUBE_RADIUS * cos(rotation)
	cube_pos.z = CUBE_RADIUS * sin(rotation)

	/* Draw cube */
	cube_mat := view_mat
	cube_mat *= mat4_translate(cube_pos)
	cube_mat *= mat4_rotate_y(rotation)
	gl.UniformMatrix4fv(u_matrix, cube_mat)
	gl.DrawArrays(gl.TRIANGLES, 0, CUBE_VERTICES)

	/* Draw ring */
	ring_mat := view_mat
	ring_mat *= mat4_rotate_x(rotation)
	gl.UniformMatrix4fv(u_matrix, ring_mat)
	gl.DrawArrays(gl.TRIANGLES, CUBE_VERTICES, RING_VERTICES)
}
