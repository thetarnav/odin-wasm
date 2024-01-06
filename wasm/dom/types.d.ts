import * as wasm from "../types.js"

export interface OdinDOMExports extends wasm.OdinExports {
	odin_dom_do_event_callback: (data: number, callback: number, ctx_ptr: number) => void
}

export interface OdinDOMInstance extends wasm.WasmInstance {
	exports: OdinDOMExports
}
