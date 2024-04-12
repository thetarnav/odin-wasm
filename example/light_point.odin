//+private file
package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"


BALL_SEGMENTS :: 16
BALL_VERTICES :: BALL_SEGMENTS * BALL_SEGMENTS * 6
ALL_VERTICES  :: CUBE_VERTICES + BALL_VERTICES

CUBE_HEIGHT :: 80
CUBE_RADIUS :: 300
BALL_RADIUS :: 200

cube_angle:    f32
ball_angle:    f32
u_view:        i32
u_local:       i32
u_light_dir:   i32
u_light_color: i32
vao:           VAO
positions:     [ALL_VERTICES]Vec
normals:       [ALL_VERTICES]Vec
colors:        [ALL_VERTICES]RGBA

@(private="package")
light_point_start :: proc(program: gl.Program) {

	vao = gl.CreateVertexArray()
	gl.BindVertexArray(vao)

	a_position := gl.GetAttribLocation(program, "a_position")
	a_normal   := gl.GetAttribLocation(program, "a_normal")
	a_color    := gl.GetAttribLocation(program, "a_color")

	u_view        = gl.GetUniformLocation(program, "u_view")
	u_local       = gl.GetUniformLocation(program, "u_local")
	u_light_dir   = gl.GetUniformLocation(program, "u_light_dir")
	u_light_color = gl.GetUniformLocation(program, "u_light_color")

	gl.EnableVertexAttribArray(a_position)
	gl.EnableVertexAttribArray(a_normal)
	gl.EnableVertexAttribArray(a_color)

	positions_buffer := gl.CreateBuffer()
	normals_buffer   := gl.CreateBuffer()
	colors_buffer    := gl.CreateBuffer()

	gl.Enable(gl.CULL_FACE) // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces


	/* Cube */
	copy_array(positions[:], get_cube_positions(0, CUBE_HEIGHT))
	cube_normals: [CUBE_VERTICES]Vec = 1
	copy_array(normals[:], cube_normals)
	copy_array(colors[:], WHITE_CUBE_COLORS)

	/* Sphere */
	ball_positions := positions[CUBE_VERTICES:]
	ball_normals   := normals  [CUBE_VERTICES:]
	ball_colors    := colors   [CUBE_VERTICES:]

	// TODO: merge top and bottom segment triangles
	si := 0
	for i in 0..<BALL_SEGMENTS {
		for j in 0..<BALL_SEGMENTS {
			a := 2*PI * f32(i) / f32(BALL_SEGMENTS)
			b :=   PI * f32(j) / f32(BALL_SEGMENTS)

			// Vertices
			v0 := Vec{
				cos(a) * sin(b + PI / f32(BALL_SEGMENTS)),
				cos(b + PI / f32(BALL_SEGMENTS)),
				sin(a) * sin(b + PI / f32(BALL_SEGMENTS)),
			}
			v1 := Vec{
				cos(a) * sin(b),
				cos(b),
				sin(a) * sin(b),
			}
			v2 := Vec{
				cos(a + 2*PI / f32(BALL_SEGMENTS)) * sin(b + PI / f32(BALL_SEGMENTS)),
				cos(b + PI / f32(BALL_SEGMENTS)),
				sin(a + 2*PI / f32(BALL_SEGMENTS)) * sin(b + PI / f32(BALL_SEGMENTS)),
			}
			v3 := Vec{
				cos(a + 2*PI / f32(BALL_SEGMENTS)) * sin(b),
				cos(b),
				sin(a + 2*PI / f32(BALL_SEGMENTS)) * sin(b),
			}

			// Normals
			n0 := normalize(v0)
			n1 := normalize(v1)
			n2 := normalize(v2)
			n3 := normalize(v3)

			// Triangle 1
			ball_positions[si+0] = v0 * BALL_RADIUS
			ball_positions[si+1] = v1 * BALL_RADIUS
			ball_positions[si+2] = v2 * BALL_RADIUS

			ball_normals  [si+0] = n0
			ball_normals  [si+1] = n1
			ball_normals  [si+2] = n2

			ball_colors   [si+0] = RED
			ball_colors   [si+1] = GREEN
			ball_colors   [si+2] = BLUE

			// Triangle 2
			ball_positions[si+3] = v1 * BALL_RADIUS
			ball_positions[si+4] = v3 * BALL_RADIUS
			ball_positions[si+5] = v2 * BALL_RADIUS

			ball_normals  [si+3] = n1
			ball_normals  [si+4] = n3
			ball_normals  [si+5] = n2

			ball_colors   [si+3] = GREEN
			ball_colors   [si+4] = WHITE
			ball_colors   [si+5] = BLUE

			si += 6
		}
	}
	

	gl.BindBuffer(gl.ARRAY_BUFFER, positions_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, positions[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_position, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, normals_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, normals[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_normal, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, colors_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, colors[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_color, 4, gl.UNSIGNED_BYTE, true, 0, 0)

	gl.Uniform4fv(u_light_color, rgba_to_vec4(ORANGE))
}

@(private="package")
light_point_frame :: proc(delta: f32) {
	gl.BindVertexArray(vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0.01, 0.02, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	camera_mat: Mat4 = 1
	camera_mat *= mat4_translate({0, 0, 500 - 500 * (scale-0.5)})
	camera_mat = glm.inverse_mat4(camera_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= camera_mat

	gl.UniformMatrix4fv(u_view, view_mat)

	/* Draw cube */
	cube_angle += 0.01 * delta * mouse_rel.x

	cube_pos: Vec
	cube_pos.y = 500 * -mouse_rel.y
	cube_pos.x = CUBE_RADIUS * cos(cube_angle)
	cube_pos.z = CUBE_RADIUS * sin(cube_angle)

	cube_mat: Mat4 = 1
	cube_mat *= mat4_translate(cube_pos)
	cube_mat *= mat4_rotate_y(cube_angle)

	gl.UniformMatrix4fv(u_local, cube_mat)
	gl.DrawArrays(gl.TRIANGLES, 0, CUBE_VERTICES)

	/* Draw light from cube */
	light_dir := glm.normalize(cube_pos)
	gl.Uniform3fv(u_light_dir, light_dir)

	/* Draw sphere */
	ball_angle += 0.001 * delta
	gl.UniformMatrix4fv(u_local, mat4_rotate_y(ball_angle))
	gl.DrawArrays(gl.TRIANGLES, CUBE_VERTICES, BALL_VERTICES)
}
