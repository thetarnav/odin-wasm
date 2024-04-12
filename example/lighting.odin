//+private file
package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"


SEGMENT_TRIANGLES :: 2 * 3
SEGMENT_VERTICES  :: SEGMENT_TRIANGLES * 3
RING_TRIANGLES    :: (16 + 32 + 48) * SEGMENT_TRIANGLES
RING_VERTICES     :: RING_TRIANGLES * 3
RINGS             :: 3
RINGS_VERTICES    :: RINGS * RING_VERTICES
ALL_VERTICES      :: CUBE_VERTICES + RINGS_VERTICES

CUBE_HEIGHT :: 80
CUBE_RADIUS :: 300
RING_HEIGHT :: 30
RING_LENGTH :: 40
RING_SPACE  :: 30

cube_angle:    f32
ring_angle:    f32
u_view:        i32
u_local:       i32
u_light_dir:   i32
u_light_color: i32
vao:           VAO
positions:     [ALL_VERTICES]Vec
normals:       [ALL_VERTICES]Vec
colors:        [ALL_VERTICES]RGBA

@(private="package")
lighting_start :: proc(program: gl.Program) {

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

	/* Ring
	
	_____________ <- RING_LENGTH
	v  ramp top v
	     |      @ <|
	     v  @@@@@  |
	    @@@@@@@@@  |
	@@@@@@@@@@@@@  |<- RING_HEIGHT = SIDE
	    @@@@@@@@@  |
	        @@@@@  |
	        ^   @ <|
	ramp bottom
	*/

	rings_normals   := normals  [CUBE_VERTICES:]
	rings_positions := positions[CUBE_VERTICES:]

	for &color in colors[CUBE_VERTICES:] {
		color = PURPLE_DARK
	}

	for ri in 0..<RINGS {
		ring_positions := rings_positions[ri*RING_VERTICES:]
		ring_normals   := rings_normals  [ri*RING_VERTICES:]

		radius := CUBE_RADIUS - CUBE_HEIGHT/2 - RING_SPACE - f32(ri) * (RING_LENGTH + RING_SPACE)
		segments := (RINGS - ri) * 16

		for si in 0..<segments {
			theta0 := 2*PI * f32(si+1) / f32(segments)
			theta1 := 2*PI * f32(si  ) / f32(segments)

			out_x0 := cos(theta0) * radius
			out_z0 := sin(theta0) * radius
			out_x1 := cos(theta1) * radius
			out_z1 := sin(theta1) * radius

			in_x0  := cos(theta0) * (radius - RING_LENGTH)
			in_z0  := sin(theta0) * (radius - RING_LENGTH)
			in_x1  := cos(theta1) * (radius - RING_LENGTH)
			in_z1  := sin(theta1) * (radius - RING_LENGTH)

			positions: []Vec = {
				/* Side */
				{out_x0, -RING_HEIGHT/2, out_z0},
				{out_x1, -RING_HEIGHT/2, out_z1},
				{out_x1,  RING_HEIGHT/2, out_z1},
				{out_x0, -RING_HEIGHT/2, out_z0},
				{out_x1,  RING_HEIGHT/2, out_z1},
				{out_x0,  RING_HEIGHT/2, out_z0},
	
				/* Ramp Top */
				{out_x0,  RING_HEIGHT/2, out_z0},
				{out_x1,  RING_HEIGHT/2, out_z1},
				{in_x0 ,  0            , in_z0 },
				{in_x0 ,  0            , in_z0 },
				{out_x1,  RING_HEIGHT/2, out_z1},
				{in_x1 ,  0            , in_z1 },
	
				/* Ramp Bottom */
				{in_x0 ,  0            , in_z0 },
				{in_x1 ,  0            , in_z1 },
				{out_x1, -RING_HEIGHT/2, out_z1},
				{in_x0 ,  0            , in_z0 },
				{out_x1, -RING_HEIGHT/2, out_z1},
				{out_x0, -RING_HEIGHT/2, out_z0},
			}

			copy(ring_positions[si*SEGMENT_VERTICES:], positions)
			normals_from_positions(ring_normals[si*SEGMENT_VERTICES:], positions)
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
lighting_frame :: proc(delta: f32) {
	gl.BindVertexArray(vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0.01, 0.02, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	camera_mat: Mat4 = 1
	camera_mat *= mat4_translate({0, 0, 800 - 800 * scale})
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

	/* Draw rings */
	ring_angle += 0.002 * delta
	
	for i in 0..<RINGS {
		ring_mat: Mat4 = 1
		ring_mat *= mat4_rotate_z(2*PI / (f32(RINGS)/f32(i)) + ring_angle/4)
		ring_mat *= mat4_rotate_x(ring_angle)

		gl.UniformMatrix4fv(u_local, ring_mat)
		gl.DrawArrays(gl.TRIANGLES, CUBE_VERTICES + i*RING_VERTICES, RING_VERTICES)
	}
}
