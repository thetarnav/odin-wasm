package main

import "../wasm"
import "../wasm/dom"
import "../wasm/webgl"
import "core:fmt"
import "core:mem"
import "core:strings"

main :: proc() {
	test_buf, err := wasm.page_alloc(2)
	context.allocator = mem.arena_allocator(&{data = test_buf})

	div := dom.dispatch_custom_event("body", "lol")

	fmt.print("Hello, WebAssembly!\n")
	fmt.eprint("Hello, Error!\n\ttest\nbyebye!\n")

	// Make sure that this matches the id of your canvas.
	webgl.SetCurrentContextById("canvas")
	webgl.ClearColor(1, 0, 0, 1)
	webgl.Clear(webgl.COLOR_BUFFER_BIT)

	dom.add_window_event_listener(.Scroll, {}, proc(e: dom.Event) {
		fmt.println("Scroll event!", e.data.scroll.delta)
	})
	dom.add_window_event_listener(.Wheel, {}, proc(e: dom.Event) {
		fmt.println("Wheel event!", e.data.wheel.delta)
	})
	dom.add_window_event_listener(.Visibility_Change, {}, proc(e: dom.Event) {
		fmt.println("Visibility_Change event!", e.data.visibility_change.is_visible)
	})
}
