#+private file
package example

import glm "core:math/linalg/glsl"
import     "core:strings"
// import     "core:fmt"
import gl  "../wasm/webgl"
import     "../obj"

@private
State_Suzanne :: struct {
	using locations: Input_Locations_Boxes,
	vao:      VAO,
	rotation: mat4,
	data:     obj.Data,
}

suzanne_obj_bytes := #load("./public/suzanne.obj", string)

@private
setup_suzanne :: proc(s: ^State_Suzanne, program: gl.Program) {

	s.vao = gl.CreateVertexArray()
	gl.BindVertexArray(s.vao)

	it := suzanne_obj_bytes
	for line in strings.split_lines_iterator(&it) {
		obj.parse_line(&s.data, line)
	}

	input_locations_boxes(s, program)

	gl.Enable(gl.CULL_FACE) // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	for &pos in s.data.positions {
		pos *= 100
	}

	colors := make([]u8vec4, len(s.data.positions))
	// for _, i in s.data.positions {
	// 	colors[i] = {u8(col.x), u8(col.y), u8(col.z), 255} rand_colors
	// }
	rand_colors(colors)

	attribute(s.a_position, gl.CreateBuffer(), s.data.positions[:])
	attribute(s.a_color   , gl.CreateBuffer(), colors)

	/* Init rotation */
	s.rotation = 1
}

@private
frame_suzanne :: proc(s: ^State_Suzanne, delta: f32) {

	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	rotation := -0.01 * delta * mouse_rel.yx
	s.rotation = mat4_rotate_x(rotation.x) * mat4_rotate_y(rotation.y) * s.rotation

	mat: mat4 = 1
	mat *= glm.mat4PerspectiveInfinite(
		fovy   = glm.radians_f32(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	mat *= glm.mat4Translate({0, 0, -900 + scale * 720})
	mat *= s.rotation

	uniform(s.u_matrix, mat)

	gl.DrawArrays(gl.TRIANGLES, 0, len(s.data.positions))
}
