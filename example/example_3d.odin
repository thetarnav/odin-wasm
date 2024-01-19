package main

import "core:fmt"
import "core:math"

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
	230, 20,  0,   255,
	0,   80,  190, 255,
	0,   80,  190, 255,

	210, 210, 0,   255,
	0,   80,  190, 255,
	230, 20,  0,   255,

	60,  210, 0,   255,
	210, 210, 0,   255,
	0,   80,  190, 255,

	60,  210, 0,   255,
	210, 210, 0,   255,
	230, 20,  0,   255,
}
@(private = "file")
positions: [VERTICES*3]f32 = {
	 0,      0,   SIDE/2,
	 SIDE/2, H,   0,
	-SIDE/2, H,   0,

	 0,      0,  -SIDE/2,
	 SIDE/2, H,   0,
	-SIDE/2, H,   0,

	 0,      0,   SIDE/2,
	 0,      0,  -SIDE/2,
	 SIDE/2, H,   0,

 	 0,      0,   SIDE/2,
 	 0,      0,  -SIDE/2,
    -SIDE/2, H,   0,
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
	webgl.Clear(webgl.COLOR_BUFFER_BIT)

	rotation_y += 0.01 * delta * (window_size.x / 2 - mouse_pos.x) / window_size.x
	rotation_x += 0.01 * delta * (window_size.y / 2 - mouse_pos.y) / window_size.y
	mat :=
		mat4_projection(vec2_to_vec3(canvas_size, 400)) *
		mat4_translate(vec2_to_vec3(mouse_pos - canvas_pos, 0)) *
		mat4_scale(scale) *
		mat4_rotate_y(rotation_y) *
		mat4_rotate_x(-rotation_x) *
		mat4_translate({0, -H / 2, 0})

	webgl.UniformMatrix4fv(u_matrix, mat)

	webgl.DrawArrays(webgl.TRIANGLES, 0, VERTICES)
}
