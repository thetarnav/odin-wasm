import * as wasm from "../wasm/runtime.js"

export type Example_Kind = (typeof Example_Kind)[keyof typeof Example_Kind]
declare const Example_Kind: {
	Rectangle: 0
	Pyramid  : 1
	Boxes    : 2
}

export interface WasmExports extends wasm.OdinExports {
	start_example: (ctx_ptr: wasm.rawptr, example_type: Example_Kind) => wasm.bool
	frame: (ctx_ptr: wasm.rawptr, delta: wasm.f32) => void
	on_window_resize: (
		window_w: wasm.f32,
		window_h: wasm.f32,
		canvas_w: wasm.f32,
		canvas_h: wasm.f32,
		canvas_x: wasm.f32,
		canvas_y: wasm.f32,
	) => void
}
