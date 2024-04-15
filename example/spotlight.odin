//+private file
package example

import "core:slice"
import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"


CUBE_HEIGHT :: 80
CUBE_RADIUS :: 300

GUY_HEIGHT :: 100
GUY_WIDTH  :: 70

GUY_JOINTS   :: 6
GUY_VERTICES :: GUY_JOINTS * JOINT_VERTICES

PLANE_WIDTH :: 1000

PLANE_VERTICES :: 6

ALL_VERTICES :: PLANE_VERTICES + CUBE_VERTICES + GUY_VERTICES

#assert(GUY_VERTICES % 3 == 0)

camera_angle : f32
u_view       : i32
u_local      : i32
u_light_pos  : i32
u_light_color: i32
u_eye_pos	 : i32
vao          : VAO
positions    : [ALL_VERTICES]Vec
normals      : [ALL_VERTICES]Vec
colors       : [ALL_VERTICES]RGBA


@(private="package")
spotlight_start :: proc(program: gl.Program) {

	vao = gl.CreateVertexArray()
	gl.BindVertexArray(vao)

	a_position := gl.GetAttribLocation(program, "a_position")
	a_normal   := gl.GetAttribLocation(program, "a_normal")
	a_color    := gl.GetAttribLocation(program, "a_color")

	u_view        = gl.GetUniformLocation(program, "u_view")
	u_local       = gl.GetUniformLocation(program, "u_local")
	u_light_pos   = gl.GetUniformLocation(program, "u_light_pos")
	u_light_color = gl.GetUniformLocation(program, "u_light_color")
	u_eye_pos     = gl.GetUniformLocation(program, "u_eye_pos")

	gl.EnableVertexAttribArray(a_position)
	gl.EnableVertexAttribArray(a_normal)
	gl.EnableVertexAttribArray(a_color)

	positions_buffer := gl.CreateBuffer()
	normals_buffer   := gl.CreateBuffer()
	colors_buffer    := gl.CreateBuffer()

	gl.Enable(gl.CULL_FACE) // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	/* Plane */

	plane_positions := positions[:PLANE_VERTICES]
	plane_normals   := normals  [:PLANE_VERTICES]
	plane_colors    := colors   [:PLANE_VERTICES]

	plane_positions[0] = {-PLANE_WIDTH/2, 0, -PLANE_WIDTH/2}
	plane_positions[1] = { PLANE_WIDTH/2, 0,  PLANE_WIDTH/2}
	plane_positions[2] = { PLANE_WIDTH/2, 0, -PLANE_WIDTH/2}
	plane_positions[3] = {-PLANE_WIDTH/2, 0, -PLANE_WIDTH/2}
	plane_positions[4] = {-PLANE_WIDTH/2, 0,  PLANE_WIDTH/2}
	plane_positions[5] = { PLANE_WIDTH/2, 0,  PLANE_WIDTH/2}

	slice.fill(plane_normals, Vec{0, 1, 0})
	slice.fill(plane_colors, PURPLE_DARK)

	/* Cube */
	cube_positions := positions[PLANE_VERTICES:][:CUBE_VERTICES]
	cube_normals   := normals  [PLANE_VERTICES:][:CUBE_VERTICES]
	cube_colors    := colors   [PLANE_VERTICES:][:CUBE_VERTICES]

	copy_array(cube_positions, get_cube_positions(0, CUBE_HEIGHT))
	slice.fill(cube_normals, 1)
	copy_array(cube_colors, WHITE_CUBE_COLORS)

	/* Guy */
	guy_positions := positions[PLANE_VERTICES+CUBE_VERTICES:]
	guy_normals   := normals  [PLANE_VERTICES+CUBE_VERTICES:]
	guy_colors    := colors   [PLANE_VERTICES+CUBE_VERTICES:]

	copy_array(guy_positions[JOINT_VERTICES*0:], get_joint(
		{0,           GUY_HEIGHT, 0},
		{GUY_WIDTH/2, 0,          20},
	))
	copy_array(guy_positions[JOINT_VERTICES*1:], get_joint(
		{0,            GUY_HEIGHT, 0},
		{-GUY_WIDTH/2, 0,         -20},
	))
	copy_array(guy_positions[JOINT_VERTICES*2:], get_joint(
		{0, GUY_HEIGHT*2,   0},
		{0, GUY_HEIGHT*0.9, 0},
	))
	copy_array(guy_positions[JOINT_VERTICES*3:], get_joint(
		{0, GUY_HEIGHT*2.1, -25},
		{0, GUY_HEIGHT*1.9,   0},
	))
	copy_array(guy_positions[JOINT_VERTICES*4:], get_joint(
		{0,            GUY_HEIGHT*1.9, 0},
		{-GUY_WIDTH/2, GUY_HEIGHT*1.1, 0},
	))
	copy_array(guy_positions[JOINT_VERTICES*5:], get_joint(
		{0,           GUY_HEIGHT*1.9,  0},
		{GUY_WIDTH/2, GUY_HEIGHT*2.7, -5},
	))

	normals_from_positions(guy_normals, guy_positions)
	slice.fill(guy_colors, BLUE)


	gl.BindBuffer(gl.ARRAY_BUFFER, positions_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, positions[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_position, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, normals_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, normals[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_normal, 3, gl.FLOAT, false, 0, 0)

	gl.BindBuffer(gl.ARRAY_BUFFER, colors_buffer)
	gl.BufferDataSlice(gl.ARRAY_BUFFER, colors[:], gl.STATIC_DRAW)
	gl.VertexAttribPointer(a_color, 4, gl.UNSIGNED_BYTE, true, 0, 0)

	gl.Uniform4fv(u_light_color, rgba_to_vec4(WHITE))
}

@(private="package")
spotlight_frame :: proc(delta: f32) {
	gl.BindVertexArray(vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0.01, 0.02, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	camera_pos := Vec{0, 200 + 300 * mouse_rel.y, 200 - 300 * (scale-0.5)}
	camera_angle += 0.01 * delta * mouse_rel.x

	camera_mat: Mat4 = 1
	camera_mat *= mat4_rotate_y(camera_angle)
	camera_mat *= mat4_translate(camera_pos)
	camera_mat *= mat4_look_at(camera_pos, {0, GUY_HEIGHT, 0}, {0, 1, 0})
	camera_mat = glm.inverse_mat4(camera_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= camera_mat

	cube_pos: Vec
	cube_pos.x = CUBE_RADIUS
	cube_pos.z = CUBE_RADIUS
	cube_pos.y = CUBE_HEIGHT/2

	cube_mat: Mat4 = 1
	cube_mat *= mat4_translate(cube_pos)


	gl.Uniform3fv(u_light_pos, cube_pos)
	gl.Uniform3fv(u_eye_pos, camera_pos)
	gl.UniformMatrix4fv(u_view, view_mat)

	/* Draw plane */
	gl.UniformMatrix4fv(u_local, 1)
	gl.DrawArrays(gl.TRIANGLES, 0, PLANE_VERTICES)

	/* Draw cube */
	gl.UniformMatrix4fv(u_local, cube_mat)
	gl.DrawArrays(gl.TRIANGLES, PLANE_VERTICES, CUBE_VERTICES)

	/* Draw guy */
	gl.UniformMatrix4fv(u_local, 1)
	gl.DrawArrays(gl.TRIANGLES, PLANE_VERTICES+CUBE_VERTICES, GUY_VERTICES)
}
