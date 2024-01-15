import * as wasm from "../wasm/runtime.js"

export interface WasmExports extends wasm.OdinExports {
	frame: (delta: wasm.i32, ctx_ptr: wasm.rawptr) => void
	on_canvas_rect_update: (w: wasm.i32, h: wasm.i32) => void
}
