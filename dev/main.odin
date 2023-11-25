//+build js
package main

import "../wasm"
import "../wasm/dom"
import "core:fmt"
import "core:mem"

main :: proc() {
	test_buf, err := wasm.page_alloc(1)
	context.allocator = mem.arena_allocator(&{data = test_buf})

	fmt.println("Hello, WebAssembly!")

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
