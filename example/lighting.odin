package example

import gl  "../wasm/webgl"

@(private="file") lighting_state: struct {
	rotation: [2]f32,
	u_matrix: i32,
	vao:      VAO,
}

lighting_start :: proc(program: gl.Program) {
	using lighting_state
}

lighting_frame :: proc(delta: f32) {
	using lighting_state
}
