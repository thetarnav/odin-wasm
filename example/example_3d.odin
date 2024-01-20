package main

import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"

import "../wasm/webgl"

example_3d_state: struct {
	rotation_y:       f32,
	rotation_x:       f32,
	a_position:       i32,
	a_color:          i32,
	u_matrix:         i32,
	positions_buffer: webgl.Buffer,
	colors_buffer:    webgl.Buffer,
}

@(private = "file")
TRIANGLES :: 4
@(private = "file")
VERTICES :: TRIANGLES * 3
@(private = "file")
SIDE :: 200
@(private = "file")
H :: math.SQRT_TWO * SIDE / 2

// odinfmt: disable
@(private = "file")
colors: [VERTICES*4]u8 = {
	60,  210, 0,   255, // G
	210, 210, 0,   255, // Y
	0,   80,  190, 255, // B

	230, 20,  0,   255, // R
	0,   80,  190, 255, // B
	210, 210, 0,   255, // Y

	60,  210, 0,   255, // G
	230, 20,  0,   255, // R
	210, 210, 0,   255, // Y

	0,   80,  190, 255, // B
	230, 20,  0,   255, // R
	60,  210, 0,   255, // G
}
@(private = "file")
positions: [VERTICES*3]f32 = {
	 0,      0,   SIDE/2,
	 SIDE/2, H,   0,
	-SIDE/2, H,   0,

	 0,      0,  -SIDE/2,
	-SIDE/2, H,   0,
	 SIDE/2, H,   0,

	 0,      0,   SIDE/2,
	 0,      0,  -SIDE/2,
	 SIDE/2, H,   0,

	-SIDE/2, H,   0,
	 0,      0,  -SIDE/2,
	 0,      0,   SIDE/2,
}
// odinfmt: enable


example_3d_start :: proc(program: webgl.Program) -> (ok: bool) {
	using example_3d_state

	a_position = webgl.GetAttribLocation(program, "a_position")
	a_color = webgl.GetAttribLocation(program, "a_color")
	u_matrix = webgl.GetUniformLocation(program, "u_matrix")

	webgl.EnableVertexAttribArray(a_position)
	webgl.EnableVertexAttribArray(a_color)

	positions_buffer = webgl.CreateBuffer()
	colors_buffer = webgl.CreateBuffer()

	webgl.Enable(webgl.CULL_FACE) // don't draw back faces
	webgl.Enable(webgl.DEPTH_TEST) // draw only closest faces

	err := webgl.GetError()
	if err != webgl.NO_ERROR {
		fmt.eprintln("WebGL error: ", err)
		return false
	}

	return true
}

example_3d_frame :: proc(delta: f32) {
	using example_3d_state

	webgl.BindBuffer(webgl.ARRAY_BUFFER, positions_buffer)
	webgl.BufferDataSlice(webgl.ARRAY_BUFFER, positions[:], webgl.STATIC_DRAW)
	webgl.VertexAttribPointer(a_position, 3, webgl.FLOAT, false, 0, 0)

	webgl.BindBuffer(webgl.ARRAY_BUFFER, colors_buffer)
	webgl.BufferDataSlice(webgl.ARRAY_BUFFER, colors[:], webgl.STATIC_DRAW)
	webgl.VertexAttribPointer(a_color, 4, webgl.UNSIGNED_BYTE, true, 0, 0)

	webgl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	webgl.ClearColor(0, 0.01, 0.02, 0)
	// Clear the canvas AND the depth buffer.
	webgl.Clear(webgl.COLOR_BUFFER_BIT | webgl.DEPTH_BUFFER_BIT)

	rotation_y += 0.01 * delta * (window_size.x / 2 - mouse_pos.x) / window_size.x
	rotation_x += 0.01 * delta * (window_size.y / 2 - mouse_pos.y) / window_size.y

	mat := glm.mat4Ortho3d(
		left = 0,
		right = canvas_size.x,
		bottom = canvas_size.y,
		top = 0,
		near = -400,
		far = 400,
	)
	mat *= glm.mat4Translate(vec2_to_vec3(mouse_pos - canvas_pos))
	mat *= glm.mat4Scale(scale)
	mat *= mat4_rotate_y(-rotation_y)
	mat *= mat4_rotate_x(rotation_x)
	mat *= glm.mat4Translate({0, -H / 2, 0})

	webgl.UniformMatrix4fv(u_matrix, mat)

	webgl.DrawArrays(webgl.TRIANGLES, 0, VERTICES)
}
