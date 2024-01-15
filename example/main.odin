package main

import "core:fmt"
import "core:mem"
import "core:runtime"

import "../wasm"
import "../wasm/dom"
import "../wasm/webgl"

shader_fragment := #load("shader_fragment.glsl", string)
shader_vertex := #load("shader_vertex.glsl", string)

device_pixel_ratio: f64 = 1
canvas_width: i32 = 640
canvas_height: i32 = 480

a_position: i32
a_color: i32
u_resolution: i32

positions_buffer: webgl.Buffer
colors_buffer: webgl.Buffer

iteration: i32

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

	webgl.EnableVertexAttribArray(a_position)
	webgl.EnableVertexAttribArray(a_color)


	positions_buffer = webgl.CreateBuffer()
	colors_buffer = webgl.CreateBuffer()

	device_pixel_ratio = dom.device_pixel_ratio()
}

@(export)
on_canvas_rect_update :: proc "c" (w, h: i32) {
	canvas_width = w
	canvas_height = h
}

@(export)
frame :: proc "c" (delta: i32, ctx: ^runtime.Context) {
	context = ctx^

	err := webgl.GetError()
	if err != webgl.NO_ERROR {
		fmt.println("WebGL error:", err)
		return
	}

	iteration += 2
	if iteration > 200 {iteration = 0}

	H: f32 : 100
	W: f32 : 200
	x := f32(iteration)
	// odinfmt: disable
	positions := [?]f32 {
		10+x, 20+x,
		 W+x, 20+x,
		10+x,  H+x,

		10+x,  H+x,
		 W+x, 20+x,
		 W+x,  H+x,
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
	webgl.Uniform2i(u_resolution, canvas_width, canvas_height)

	// Tell WebGL how to convert from clip space to pixels
	webgl.Viewport(0, 0, canvas_width, canvas_height)

	// Clear the canvas
	webgl.ClearColor(0, 0.01, 0.02, 0)
	webgl.Clear(webgl.COLOR_BUFFER_BIT)

	// draw
	webgl.DrawArrays(webgl.TRIANGLES, 0, 6) // 2 triangles, 6 vertices
}
