package main

import "core:fmt"
import "core:intrinsics"
import glm "core:math/linalg/glsl"
import "core:mem"
import "core:runtime"

import "../wasm"
import "../wasm/dom"
import "../wasm/webgl"

shader_fragment := #load("shader_fragment.glsl", string)
shader_vertex := #load("shader_vertex.glsl", string)

dpr: f32
res: [2]i32
canvas_pos: [2]f32
canvas_size: [2]f32
window_size: [2]f32
mouse_pos: [2]f32

scale: f32 = 1
scale_min: f32 = 0.25
scale_max: f32 = 5

rotation: f32 = 0

a_position: i32
a_color: i32
u_resolution: i32
u_matrix: i32

positions_buffer: webgl.Buffer
colors_buffer: webgl.Buffer

// odinfmt: disable
colors := [?]u8 {
	255, 0, 0, 255,
	0, 255, 0, 255,
	0, 0, 255, 255,

	255, 0, 0, 255,
	0, 255, 0, 255,
	0, 0, 255, 255,
}
// odinfmt: enable

main :: proc() {
	test_buf, err := wasm.page_alloc(2)
	if err != nil {
		fmt.println("Failed to allocate memory!")
		return
	}
	context.allocator = mem.arena_allocator(&{data = test_buf})

	dom.dispatch_custom_event("body", "lol")

	fmt.print("Hellope, WebAssembly!!!\n")
	fmt.eprint("Hello, Error!\n\ttest\nbyebye!\n")

	dom.add_window_event_listener(.Wheel, {}, on_wheel)
	dom.add_window_event_listener(.Mouse_Move, {}, on_mouse_move)


	// Make sure that this matches the id of your canvas.
	if ok := webgl.SetCurrentContextById("canvas"); !ok {
		fmt.println("Failed to set current context!")
		return
	}

	program, program_ok := webgl.CreateProgramFromStrings({shader_vertex}, {shader_fragment})
	if !program_ok {
		fmt.println("Failed to create program!")
		return
	}
	webgl.UseProgram(program)


	a_position = webgl.GetAttribLocation(program, "a_position")
	a_color = webgl.GetAttribLocation(program, "a_color")
	u_resolution = webgl.GetUniformLocation(program, "u_resolution")
	u_matrix = webgl.GetUniformLocation(program, "u_matrix")

	webgl.EnableVertexAttribArray(a_position)
	webgl.EnableVertexAttribArray(a_color)


	positions_buffer = webgl.CreateBuffer()
	colors_buffer = webgl.CreateBuffer()

	dpr = f32(dom.device_pixel_ratio())
	window_size = cast_vec2(f32, dom.get_window_inner_size())
	canvas_size = window_size - 200
	mouse_pos = window_size / 2
}

on_mouse_move :: proc(e: dom.Event) {
	mouse_pos = cast_vec2(f32, e.data.mouse.client)
}
on_wheel :: proc(e: dom.Event) {
	scale += f32(e.data.wheel.delta.y) * 0.001
	scale = clamp(scale, scale_min, scale_max)
}
@(export)
on_window_resize :: proc "contextless" (vw, vh, cw, ch, cx, cy: f32) {
	window_size = {vw, vh}
	canvas_size = {cw, ch}
	canvas_pos = {cx, cy}
	res = cast_vec2(i32, canvas_size * dpr)
}

@(export)
frame :: proc "c" (delta: i32, ctx: ^runtime.Context) {
	context = ctx^

	err := webgl.GetError()
	if err != webgl.NO_ERROR {
		fmt.println("WebGL error:", err)
		return
	}

	box_size: [2]f32 = {160, 100}
	// odinfmt: disable
	positions := [?]f32 {
		 0,           0,
		 box_size.x,  0,
		 0,           box_size.y,

		 0,           box_size.y,
		 box_size.x,  0,
		 box_size.x,  box_size.y,
	}
	// odinfmt: enable


	webgl.BindBuffer(webgl.ARRAY_BUFFER, positions_buffer)
	webgl.BufferDataSlice(webgl.ARRAY_BUFFER, positions[:], webgl.STATIC_DRAW)
	webgl.VertexAttribPointer(a_position, 2, webgl.FLOAT, false, 0, 0)

	webgl.BindBuffer(webgl.ARRAY_BUFFER, colors_buffer)
	webgl.BufferDataSlice(webgl.ARRAY_BUFFER, colors[:], webgl.STATIC_DRAW)
	webgl.VertexAttribPointer(a_color, 4, webgl.UNSIGNED_BYTE, true, 0, 0)

	webgl.Uniform2f(u_resolution, canvas_size.x, canvas_size.y)

	webgl.Viewport(0, 0, res.x, res.y)
	webgl.ClearColor(0, 0.01, 0.02, 0)
	webgl.Clear(webgl.COLOR_BUFFER_BIT)


	rotation += 0.01 * f32(delta) * (window_size.x / 2 - mouse_pos.x) / window_size.x
	mat :=
		mat3_translate(mouse_pos - canvas_pos) *
		mat3_scale({scale, scale}) *
		mat3_rotate(rotation) *
		mat3_translate(-box_size / 2)

	webgl.UniformMatrix3fv(u_matrix, mat)

	webgl.DrawArrays(webgl.TRIANGLES, 0, 6) // 2 triangles, 6 vertices
}

cast_vec2 :: proc "contextless" (
	$To: typeid,
	v: [2]$From,
) -> [2]To where intrinsics.type_is_numeric(From) &&
	intrinsics.type_is_numeric(To) {
	return {To(v.x), To(v.y)}
}

// odinfmt: disable
@(require_results)
mat3_translate :: proc "contextless" (v: [2]f32) -> glm.mat3 {
	return {
		1, 0, v.x,
		0, 1, v.y,
		0, 0, 1,
   	}
}
@(require_results)
mat3_scale :: proc "contextless" (v: [2]f32) -> glm.mat3 {
	return {
		v.x, 0,   0,
		0,   v.y, 0,
		0,   0,   1,
   	}
}
@(require_results)
mat3_rotate :: proc "contextless" (angle: f32) -> glm.mat3 {
	c := glm.cos(angle)
	s := glm.sin(angle)
	return {
		 c, s, 0,
		-s, c, 0,
		 0, 0, 1,
	}
}
// odinfmt: enable
