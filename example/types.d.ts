import * as wasm from "../wasm/runtime.js"

export type Example_Type = {
	D2: 0
	D3: 1
}
declare const Example_Type: Example_Type
export type Example_Type_Value = Example_Type[keyof Example_Type]

export interface WasmExports extends wasm.OdinExports {
	start_example: (ctx_ptr: wasm.rawptr, example_type: Example_Type_Value) => wasm.bool
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
