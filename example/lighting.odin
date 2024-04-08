package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

lighting_state: struct {
	rotation: f32,
	u_matrix: i32,
	vao:      VAO,
}

@(private="file") CUBE_HEIGHT :: 80
@(private="file") RADIUS      :: 260

@(private="file") ALL_VERTICES :: CUBE_VERTICES

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
	cube_positions := get_cube_positions(0, CUBE_HEIGHT)
	copy(positions[:CUBE_VERTICES], cube_positions[:])
	cube_colors := WHITE_CUBE_COLORS
	copy(colors[:CUBE_VERTICES], cube_colors[:])

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
	elevation := 300 * -(mouse_rel.y - 0.5)

	cube_pos: Vec
	cube_pos.y = elevation
	cube_pos.x = (RADIUS-40) * cos(rotation)
	cube_pos.z = (RADIUS-40) * sin(rotation)

	{ /* Draw cube */
		mat := view_mat
		mat *= mat4_translate(cube_pos)
		mat *= mat4_rotate_y(rotation)
		gl.UniformMatrix4fv(u_matrix, mat)
		gl.DrawArrays(gl.TRIANGLES, 0, ALL_VERTICES)
	}
}
