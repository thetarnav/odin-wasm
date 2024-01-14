import * as wasm from "../wasm/runtime.js"

export interface WasmExports extends wasm.OdinExports {
	frame: (time: number, ctx_ptr: number) => void
}
