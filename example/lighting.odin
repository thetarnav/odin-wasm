//+private file
package example

import "core:slice"
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

@private
State_Lighting :: struct {
	cube_angle:    f32,
	ring_angle:    f32,
	u_view:        Uniform_mat4,
	u_local:       Uniform_mat4,
	u_light_dir:   Uniform_vec3,
	u_light_color: Uniform_vec4,
	vao:           VAO,
	positions:     [ALL_VERTICES]vec3,
	normals:       [ALL_VERTICES]vec3,
	colors:        [ALL_VERTICES]RGBA,
}

@private
setup_lighting :: proc(s: ^State_Lighting, program: gl.Program) {
	s.vao = gl.CreateVertexArray()
	gl.BindVertexArray(s.vao)

	a_position := attribute_location_vec3(program, "a_position")
	a_normal   := attribute_location_vec3(program, "a_normal")
	a_color    := attribute_location_vec4(program, "a_color")

	s.u_view        = uniform_location_mat4(program, "u_view")
	s.u_local       = uniform_location_mat4(program, "u_local")
	s.u_light_dir   = uniform_location_vec3(program, "u_light_dir")
	s.u_light_color = uniform_location_vec4(program, "u_light_color")

	gl.Enable(gl.CULL_FACE) // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	/* Cube */
	copy_array(s.positions[:], get_cube_positions(0, CUBE_HEIGHT))
	cube_normals: [CUBE_VERTICES]vec3 = 1
	copy_array(s.normals[:], cube_normals)
	slice.fill(s.colors[:], WHITE)

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

	rings_normals   := s.normals  [CUBE_VERTICES:]
	rings_positions := s.positions[CUBE_VERTICES:]

	for &color in s.colors[CUBE_VERTICES:] {
		color = PURPLE_DARK
	}

	for ri in 0..<RINGS {
		ring_positions := rings_positions[ri*RING_VERTICES:]
		ring_normals   := rings_normals  [ri*RING_VERTICES:]

		radius := CUBE_RADIUS - CUBE_HEIGHT/2 - RING_SPACE - f32(ri) * (RING_LENGTH + RING_SPACE)
		segments := (RINGS - ri) * 16

		for si in 0..<segments {
			a := 2*PI * f32(si+1) / f32(segments)
			b := 2*PI * f32(si  ) / f32(segments)

			out_x0 := cos(a) * radius
			out_z0 := sin(a) * radius
			out_x1 := cos(b) * radius
			out_z1 := sin(b) * radius

			in_x0  := cos(a) * (radius-RING_LENGTH)
			in_z0  := sin(a) * (radius-RING_LENGTH)
			in_x1  := cos(b) * (radius-RING_LENGTH)
			in_z1  := sin(b) * (radius-RING_LENGTH)

			positions: []vec3 = {
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

	attribute(a_position, gl.CreateBuffer(), s.positions[:])
	attribute(a_normal  , gl.CreateBuffer(), s.normals[:])
	attribute(a_color   , gl.CreateBuffer(), s.colors[:])

	uniform(s.u_light_color, rgba_to_vec4(ORANGE))
}

@private
frame_lighting :: proc(s: ^State_Lighting, delta: f32) {
	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	camera_mat: mat4 = 1
	camera_mat *= mat4_translate({0, 0, 800 - 800 * scale})
	camera_mat = glm.inverse_mat4(camera_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= camera_mat

	uniform(s.u_view, view_mat)

	/* Draw cube */
	s.cube_angle += 0.01 * delta * mouse_rel.x

	cube_pos: vec3
	cube_pos.y = 500 * -mouse_rel.y
	cube_pos.x = CUBE_RADIUS * cos(s.cube_angle)
	cube_pos.z = CUBE_RADIUS * sin(s.cube_angle)

	cube_mat: mat4 = 1
	cube_mat *= mat4_translate(cube_pos)
	cube_mat *= mat4_rotate_y(s.cube_angle)

	uniform(s.u_local, cube_mat)
	gl.DrawArrays(gl.TRIANGLES, 0, CUBE_VERTICES)

	/* Draw light from cube */
	light_dir := glm.normalize(cube_pos)
	uniform(s.u_light_dir, light_dir)

	/* Draw rings */
	s.ring_angle += 0.002 * delta

	for i in 0..<RINGS {
		ring_mat: mat4 = 1
		ring_mat *= mat4_rotate_z(2*PI / (f32(RINGS)/f32(i)) + s.ring_angle/4)
		ring_mat *= mat4_rotate_x(s.ring_angle)

		uniform(s.u_local, ring_mat)
		gl.DrawArrays(gl.TRIANGLES, CUBE_VERTICES + i*RING_VERTICES, RING_VERTICES)
	}
}
