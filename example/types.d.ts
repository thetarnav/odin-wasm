import * as wasm from "../wasm/runtime.js"

export interface WasmExports extends wasm.OdinExports {
	frame: (delta: wasm.i32, ctx_ptr: wasm.rawptr) => void
	on_window_resize: (
		window_w: wasm.f32,
		window_h: wasm.f32,
		canvas_w: wasm.f32,
		canvas_h: wasm.f32,
		canvas_x: wasm.f32,
		canvas_y: wasm.f32,
	) => void
}
