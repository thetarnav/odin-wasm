/*

Copied from the Odin/vendor/wasm
https://github.com/odin-lang/Odin/tree/master/vendor/wasm

*/

//+build !js
package wasm_js_interface

import "core:runtime"


get_element_value_string :: proc "contextless" (id: string, buf: []byte) -> string {
	context = runtime.default_context()
	panic("vendor:wasm/js not supported on non JS targets")
}


get_element_min_max :: proc "contextless" (id: string) -> (min, max: f64) {
	context = runtime.default_context()
	panic("vendor:wasm/js not supported on non JS targets")
}


Rect :: struct {
	x, y, width, height: f64,
}

get_bounding_client_rect :: proc "contextless" (id: string) -> (rect: Rect) {
	context = runtime.default_context()
	panic("vendor:wasm/js not supported on non JS targets")
}

get_window_inner_size :: proc "contextless" () -> (size: [2]f64) {
	context = runtime.default_context()
	panic("vendor:wasm/js not supported on non JS targets")
}

get_window_outer_size :: proc "contextless" () -> (size: [2]f64) {
	context = runtime.default_context()
	panic("vendor:wasm/js not supported on non JS targets")
}

get_screen_size :: proc "contextless" () -> (size: [2]f64) {
	context = runtime.default_context()
	panic("vendor:wasm/js not supported on non JS targets")
}

get_window_position :: proc "contextless" () -> (pos: [2]f64) {
	context = runtime.default_context()
	panic("vendor:wasm/js not supported on non JS targets")
}

get_window_scroll :: proc "contextless" () -> (scroll: [2]f64) {
	context = runtime.default_context()
	panic("vendor:wasm/js not supported on non JS targets")
}
