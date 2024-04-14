//+private file
package example

import "core:slice"
import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

CUBE_HEIGHT :: 80
CUBE_RADIUS :: 300

FEET_WIDTH :: 10
LEG_HEIGHT :: 120
LEG_DEPTH  :: 20
GUY_WIDTH  :: 80

JOINT_TRIANGLES :: 8
JOINT_VERTICES  :: 3 * JOINT_TRIANGLES

get_joint :: proc(from, to: Vec) -> [JOINT_VERTICES]Vec {
	length: f32 = glm.length(to - from)
	w     : f32 = min(20, length/3)

	mid   : Vec = from*(1.0/3.0) + to*(2.0/3.0)
	normal: Vec = normalize(to - from)
	move_x: Vec = vec3_rotate_by_axis_angle(normal, Vec{1, 0, 0}, PI/2) * w
	move_y: Vec = vec3_rotate_by_axis_angle(normal, Vec{0, 0, 1}, PI/2) * w
	
	// TODO this is not correct
	
	return {
		from,
		mid + move_y,
		mid + move_x,
	
		from,
		mid - move_x,
		mid + move_y,
	
		from,
		mid + move_x,
		mid - move_y,
	
		from,
		mid - move_y,
		mid - move_x,

		mid + move_x,
		mid + move_y,
		to,

		mid + move_y,
		mid - move_x,
		to,

		mid - move_x,
		mid - move_y,
		to,

		mid - move_y,
		mid + move_x,
		to,
	}
}

GUY_JOINTS   :: 6
GUY_VERTICES :: GUY_JOINTS * JOINT_VERTICES
ALL_VERTICES :: CUBE_VERTICES + GUY_VERTICES

#assert(GUY_VERTICES % 3 == 0)

cube_angle   : f32
ball_angle   : f32
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


	/* Cube */
	cube_positions := positions[:CUBE_VERTICES]
	cube_normals   := normals  [:CUBE_VERTICES]
	cube_colors    := colors   [:CUBE_VERTICES]

	copy_array(cube_positions, get_cube_positions(0, CUBE_HEIGHT))
	slice.fill(cube_normals, 1)
	copy_array(cube_colors, WHITE_CUBE_COLORS)

	/* Guy */
	guy_positions := positions[CUBE_VERTICES:]
	guy_normals   := normals  [CUBE_VERTICES:]
	guy_colors    := colors   [CUBE_VERTICES:]

	copy_array(guy_positions[JOINT_VERTICES*0:], get_joint(
		{0,           LEG_HEIGHT, 0},
		{GUY_WIDTH/2, 0,          20},
	))
	copy_array(guy_positions[JOINT_VERTICES*1:], get_joint(
		{0,            LEG_HEIGHT, 0},
		{-GUY_WIDTH/2, 0,         -20},
	))
	copy_array(guy_positions[JOINT_VERTICES*2:], get_joint(
		{0, LEG_HEIGHT*2, 0},
		{0, LEG_HEIGHT*0.9,   0},
	))
	copy_array(guy_positions[JOINT_VERTICES*3:], get_joint(
		{0, LEG_HEIGHT*2.1, -25},
		{0, LEG_HEIGHT*1.9,   0},
	))
	copy_array(guy_positions[JOINT_VERTICES*4:], get_joint(
		{0,            LEG_HEIGHT*1.9,   0},
		{-GUY_WIDTH/2, LEG_HEIGHT*1.1,       0},
	))
	copy_array(guy_positions[JOINT_VERTICES*5:], get_joint(
		{GUY_WIDTH/1.5, LEG_HEIGHT*2.5,  -5},
		{0,             LEG_HEIGHT*1.9,   0},
	))

	normals_from_positions(guy_normals, positions[CUBE_VERTICES:])
	slice.fill(guy_colors, RGBA{0, 0, 255, 255})


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

	camera_pos := Vec{0, 500 * mouse_rel.y, 500 - 500 * (scale-0.5)}

	camera_mat: Mat4 = 1
	camera_mat *= mat4_translate(camera_pos)
	camera_mat = glm.inverse_mat4(camera_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= camera_mat

	cube_angle += 0.01 * delta * mouse_rel.x

	cube_pos: Vec
	cube_pos.x = CUBE_RADIUS * cos(cube_angle)
	cube_pos.z = CUBE_RADIUS * sin(cube_angle)

	cube_mat: Mat4 = 1
	cube_mat *= mat4_translate(cube_pos)
	cube_mat *= mat4_rotate_y(cube_angle)


	gl.Uniform3fv(u_light_pos, cube_pos)
	gl.Uniform3fv(u_eye_pos, camera_pos)
	gl.UniformMatrix4fv(u_view, view_mat)

	/* Draw cube */
	gl.UniformMatrix4fv(u_local, cube_mat)
	gl.DrawArrays(gl.TRIANGLES, 0, CUBE_VERTICES)

	/* Draw guy */
	ball_angle += 0.001 * delta
	gl.UniformMatrix4fv(u_local, mat4_rotate_y(ball_angle))
	gl.DrawArrays(gl.TRIANGLES, CUBE_VERTICES, GUY_VERTICES)
}
