package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:mem"
import "core:runtime"

import "../wasm"
import "../wasm/dom"
import "../wasm/webgl"

shader_fragment := #load("shader_fragment.glsl", string)
shader_vertex := #load("shader_vertex.glsl", string)

dpr: f32 = 1
res: [2]i32
canvas_pos: [2]i32
canvas_rect: [2]i32 = {640, 480}
window_rect: [2]i32 = {640, 480}
mouse_pos: [2]i32 = {0, 0}

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

	dom.add_window_event_listener(.Mouse_Move, {}, proc(e: dom.Event) {
		mouse_pos = {i32(e.data.mouse.client.x), i32(e.data.mouse.client.y)}
	})

	dom.add_window_event_listener(.Scroll, {}, proc(e: dom.Event) {
		fmt.println("Scroll event!", e.data.scroll.delta)
	})
	dom.add_window_event_listener(.Wheel, {}, proc(e: dom.Event) {
		fmt.println("Wheel event!", e.data.wheel.delta)
	})
	dom.add_window_event_listener(.Visibility_Change, {}, proc(e: dom.Event) {
		fmt.println("Visibility_Change event!", e.data.visibility_change.is_visible)
	})


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
	canvas_rect = {640, 480}
	window_rect = canvas_rect + 200
	mouse_pos = window_rect / 2
}

@(export)
on_window_resize :: proc "c" (vw, vh, cw, ch, cx, cy: i32) {
	window_rect = {vw, vh}
	canvas_rect = {cw, ch}
	canvas_pos = {cx, cy}
	res = {i32(f32(canvas_rect.x) * dpr), i32(f32(canvas_rect.y) * dpr)}
}

@(export)
frame :: proc "c" (delta: i32, ctx: ^runtime.Context) {
	context = ctx^

	err := webgl.GetError()
	if err != webgl.NO_ERROR {
		fmt.println("WebGL error:", err)
		return
	}

	H: f32 : 100
	W: f32 : 200
	// odinfmt: disable
	positions := [?]f32 {
		 0,  0,
		 W,  0,
		 0,  H,

		 0,  H,
		 W,  0,
		 W,  H,
	}
	// odinfmt: enable


	webgl.BindBuffer(webgl.ARRAY_BUFFER, positions_buffer)
	webgl.BufferDataSlice(webgl.ARRAY_BUFFER, positions[:], webgl.STATIC_DRAW)

	// Tell the attribute how to get data out of positionBuffer (ARRAY_BUFFER)
	webgl.VertexAttribPointer(a_position, 2, webgl.FLOAT, false, 0, 0)

	// bind, and fill color buffer
	webgl.BindBuffer(webgl.ARRAY_BUFFER, colors_buffer)
	webgl.BufferDataSlice(webgl.ARRAY_BUFFER, colors[:], webgl.STATIC_DRAW)
	webgl.VertexAttribPointer(a_color, 4, webgl.UNSIGNED_BYTE, true, 0, 0)

	// set the resolution
	webgl.Uniform2f(u_resolution, f32(canvas_rect.x), f32(canvas_rect.y))

	// Tell WebGL how to convert from clip space to pixels
	webgl.Viewport(0, 0, res.x, res.y)

	// Clear the canvas
	webgl.ClearColor(0, 0.01, 0.02, 0)
	webgl.Clear(webgl.COLOR_BUFFER_BIT)
	
	// odinfmt: disable
	mat: glm.mat3 = {
		1, 0, f32(mouse_pos.x) - f32(canvas_pos.x),
		0, 1, f32(mouse_pos.y) - f32(canvas_pos.y),
		0, 0, 1,
	}
	// odinfmt: enable

	webgl.UniformMatrix3fv(u_matrix, mat)

	// draw
	webgl.DrawArrays(webgl.TRIANGLES, 0, 6) // 2 triangles, 6 vertices
}
