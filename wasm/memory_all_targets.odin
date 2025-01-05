/*

Copied from the Odin/vendor/wasm
https://github.com/odin-lang/Odin/tree/master/vendor/wasm

*/

#+build !js
package wasm

import "core:mem"

PAGE_SIZE :: 64 * 1024
page_alloc :: proc(page_count: int) -> (data: []byte, err: mem.Allocator_Error) {
	panic("vendor:wasm/js not supported on non-js targets")
}

page_allocator :: proc() -> mem.Allocator {
	panic("vendor:wasm/js not supported on non-js targets")
}
