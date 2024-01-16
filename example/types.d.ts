import * as wasm from "../wasm/runtime.js"

export interface WasmExports extends wasm.OdinExports {
	frame: (delta: wasm.i32, ctx_ptr: wasm.rawptr) => void
	on_window_resize: (
		window_w: wasm.i32,
		window_h: wasm.i32,
		canvas_w: wasm.i32,
		canvas_h: wasm.i32,
		canvas_x: wasm.i32,
		canvas_y: wasm.i32,
	) => void
}
