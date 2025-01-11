#+private file
package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

CUBE_COLORS: [CUBE_VERTICES]rgba : {
	GREEN,  GREEN,  GREEN,  // 0
	GREEN,  GREEN,  GREEN,  // 1
	YELLOW, YELLOW, YELLOW, // 2
	YELLOW, YELLOW, YELLOW, // 3
	BLUE,   BLUE,   BLUE,   // 4
	BLUE,   BLUE,   BLUE,   // 5
	RED,    RED,    RED,    // 6
	RED,    RED,    RED,    // 7
	ORANGE, ORANGE, ORANGE, // 8
	ORANGE, ORANGE, ORANGE, // 9
	PURPLE, PURPLE, PURPLE, // 10
	PURPLE, PURPLE, PURPLE, // 11
}

BOX_HEIGHT :: 60

BOXES_ROWS   :: 3
BOXES_AMOUNT :: BOXES_ROWS * BOXES_ROWS * BOXES_ROWS

@private
State_Boxes :: struct {
	using locations: Input_Locations_Boxes,
	vao     : VAO,
	rotation: mat4,
}

@private
setup_boxes :: proc(s: ^State_Boxes, program: gl.Program) {
	s.vao = gl.CreateVertexArray()
	gl.BindVertexArray(s.vao)

	input_locations_boxes(s, program)

	gl.Enable(gl.CULL_FACE) // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	positions: [BOXES_AMOUNT * CUBE_VERTICES]vec3
	colors   : [BOXES_AMOUNT * CUBE_VERTICES]rgba

	for i in 0..<BOXES_AMOUNT {
		cube_positions := get_cube_positions(
			pos = {
				100 * f32(i % BOXES_ROWS)              - 100,
				100 * f32(i / BOXES_ROWS % BOXES_ROWS) - 100,
				100 * f32(i / BOXES_ROWS / BOXES_ROWS) - 100,
			},
			h   = BOX_HEIGHT,
		)
		copy_array(positions[i*CUBE_VERTICES:], cube_positions)
		copy_array(colors[i*CUBE_VERTICES:], CUBE_COLORS)
	}

	attribute(s.a_position, gl.CreateBuffer(), positions[:])
	attribute(s.a_color   , gl.CreateBuffer(), colors[:])

	/* Init rotation */
	s.rotation = 1
}

@private
frame_boxes :: proc(s: ^State_Boxes, delta: f32) {

	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	rotation := -0.01 * delta * mouse_rel.yx
	s.rotation = mat4_rotate_x(rotation.x) * mat4_rotate_y(rotation.y) * s.rotation

	mat := mat4(1)
	mat *= glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	mat *= mat4_translate({0, 0, -900 + scale * 720})
	mat *= s.rotation

	uniform(s.u_matrix, mat)

	gl.DrawArrays(gl.TRIANGLES, 0, CUBE_VERTICES * BOXES_AMOUNT)
}
