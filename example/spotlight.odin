//+private file
package example

import "core:slice"
import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"


CUBE_HEIGHT :: 40
CUBE_RADIUS :: 300
GUY_HEIGHT  :: 100
GUY_WIDTH   :: 70
PLANE_WIDTH :: 2000

GUY_JOINT_POSITIONS :: [?]struct {from, to: vec3, w: f32} {
	{{  0,  40,  0}, {  0, 120,  20}, 16},
	{{  0, 140, 35}, {  0, 120,  20}, 14},
	{{  0,  40,  0}, { 30,   5,  40}, 14},
	{{  0,  40,  0}, {-30,   5,  40}, 14},
	{{ 30,   5, 40}, { 20,   0, -40}, 10},
	{{-30,   5, 40}, {-20,   0, -40}, 10},
	{{  0, 120, 20}, { 35, 135,  30}, 10},
	{{  0, 120, 20}, {-35, 135,  30}, 10},
	{{ 35, 135, 30}, { 30, 185,  40},  8},
	{{-35, 135, 30}, {-30, 185,  40},  8},
}

GUY_JOINTS     :: len(GUY_JOINT_POSITIONS)
GUY_VERTICES   :: GUY_JOINTS * JOINT_VERTICES
PLANE_VERTICES :: 6
ALL_VERTICES   :: PLANE_VERTICES + CUBE_VERTICES*2 + GUY_VERTICES

#assert(ALL_VERTICES % 3 == 0)

@private
State_Spotlight :: struct {
	using vert  : Inputs_Spotlight_Vert,
	using frag  : Inputs_Spotlight_Frag,
	vao         : VAO,
	camera_angle: f32,
	positions   : [ALL_VERTICES]vec3,
	normals     : [ALL_VERTICES]vec3,
}


@private
setup_spotlight :: proc(s: ^State_Spotlight, program: gl.Program) {

	s.vao = gl.CreateVertexArray()
	gl.BindVertexArray(s.vao)

	input_locations_spotlight_vert(s, program)
	input_locations_spotlight_frag(s, program)

	gl.Enable(gl.CULL_FACE)
	gl.Enable(gl.DEPTH_TEST)

	vi := 0

	/* Plane */

	plane_positions := s.positions[vi:][:PLANE_VERTICES]
	plane_normals   := s.normals  [vi:][:PLANE_VERTICES]
	vi += PLANE_VERTICES

	plane_positions[0] = {-PLANE_WIDTH/2, 0, -PLANE_WIDTH/2}
	plane_positions[1] = { PLANE_WIDTH/2, 0,  PLANE_WIDTH/2}
	plane_positions[2] = { PLANE_WIDTH/2, 0, -PLANE_WIDTH/2}
	plane_positions[3] = {-PLANE_WIDTH/2, 0, -PLANE_WIDTH/2}
	plane_positions[4] = {-PLANE_WIDTH/2, 0,  PLANE_WIDTH/2}
	plane_positions[5] = { PLANE_WIDTH/2, 0,  PLANE_WIDTH/2}

	slice.fill(plane_normals, vec3{0, 1, 0})

	/* Cube RED */
	cube_red_positions := s.positions[vi:][:CUBE_VERTICES]
	cube_red_normals   := s.normals  [vi:][:CUBE_VERTICES]
	vi += CUBE_VERTICES

	copy_array(cube_red_positions, get_cube_positions(0, CUBE_HEIGHT))
	slice.fill(cube_red_normals, 1)

	/* Cube BLUE */
	cube_blue_positions := s.positions[vi:][:CUBE_VERTICES]
	cube_blue_normals   := s.normals  [vi:][:CUBE_VERTICES]
	vi += CUBE_VERTICES

	copy_array(cube_blue_positions, get_cube_positions(0, CUBE_HEIGHT))
	slice.fill(cube_blue_normals, 1)

	/* Guy */
	guy_positions := s.positions[vi:][:GUY_VERTICES]
	guy_normals   := s.normals  [vi:][:GUY_VERTICES]
	vi += GUY_VERTICES

	for joint, ji in GUY_JOINT_POSITIONS {
		copy_array(guy_positions[JOINT_VERTICES*ji:], get_joint(joint.from, joint.to, joint.w))
	}

	normals_from_positions(guy_normals, guy_positions)

	attribute(s.a_position, gl.CreateBuffer(), s.positions[:])
	attribute(s.a_normal  , gl.CreateBuffer(), s.normals[:])

	uniform(s.u_light_color[0], rgba_to_vec4(RED))
	uniform(s.u_light_color[1], rgba_to_vec4(BLUE))
}

@private
frame_spotlight :: proc(s: ^State_Spotlight, delta: f32) {
	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	camera_pos     := vec3{0, 200 + 300 * mouse_rel.y, 200 - 300 * (scale-0.5)}
	s.camera_angle += 0.01 * delta * mouse_rel.x

	camera_mat: mat4 = 1
	camera_mat *= mat4_rotate_y(s.camera_angle)
	camera_mat *= mat4_translate(camera_pos)
	camera_mat *= mat4_look_at(camera_pos, {0, 50, 0}, {0, 1, 0})
	camera_mat = glm.inverse_mat4(camera_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= camera_mat

	/* Light */

	cube_red_angle : f32 = PI/2 + PI/6
	cube_blue_angle: f32 = PI/2 - PI/6

	cube_red_pos: vec3
	cube_red_pos.x = CUBE_RADIUS * cos(cube_red_angle)
	cube_red_pos.z = CUBE_RADIUS * sin(cube_red_angle)
	cube_red_pos.y = CUBE_HEIGHT*8

	cube_blue_pos: vec3
	cube_blue_pos.x = CUBE_RADIUS * cos(cube_blue_angle)
	cube_blue_pos.z = CUBE_RADIUS * sin(cube_blue_angle)
	cube_blue_pos.y = CUBE_HEIGHT*8

	uniform(s.u_light_pos[0], cube_red_pos)
	uniform(s.u_light_pos[1], cube_blue_pos)
	uniform(s.u_light_dir[0], normalize(-cube_red_pos))
	uniform(s.u_light_dir[1], normalize(-cube_blue_pos))
	uniform(s.u_view, view_mat)

	vi := 0

	/* Draw plane */
	uniform(s.u_local, 1)
	gl.DrawArrays(gl.TRIANGLES, vi, PLANE_VERTICES)
	vi += PLANE_VERTICES

	/* Draw cube RED */
	uniform(s.u_local, mat4_translate(cube_red_pos))
	uniform(s.u_light_add[0], 1)
	gl.DrawArrays(gl.TRIANGLES, vi, CUBE_VERTICES)
	uniform(s.u_light_add[0], 0)
	vi += CUBE_VERTICES

	/* Draw cube BLUE */
	uniform(s.u_local, mat4_translate(cube_blue_pos))
	uniform(s.u_light_add[1], 1)
	gl.DrawArrays(gl.TRIANGLES, vi, CUBE_VERTICES)
	uniform(s.u_light_add[1], 0)
	vi += CUBE_VERTICES

	/* Draw guy */
	uniform(s.u_local, 1)
	gl.DrawArrays(gl.TRIANGLES, vi, GUY_VERTICES)
	vi += GUY_VERTICES
}
