//+build js
package main

import "../wasm"
import "../wasm/dom"
import "core:fmt"
import "core:mem"
import "core:strings"

main :: proc() {
	test_buf, err := wasm.page_alloc(2)
	context.allocator = mem.arena_allocator(&{data = test_buf})

	div := dom.dispatch_custom_event("lol", "lol")

	// str := fmt.aprint("Hello, WebAssembly!\n")
	// wasm.alert(str)

	fmt.printf("Hello, WebAssembly!\n\tdispatched event: %v\n", div)

	fmt.print("Hello, WebAssembly!\n")
	fmt.println("123")
	fmt.eprint("Hello, Error!\n\ttest\nbyebye!\n")

	list: [dynamic]int
	append(&list, 1)
	append(&list, 2)
	append(&list, 3)

	fmt.println("list:", list)
	fmt.println("list[0]:", list[0])
	fmt.println("list[1]:", list[1])
	fmt.println("list[2]:", list[2])
	fmt.println("list[3]:", list[3])


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
