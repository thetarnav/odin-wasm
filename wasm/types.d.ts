export interface OdinExports extends WebAssembly.Exports {
	memory: WebAssembly.Memory
	_start: () => void
	_end: () => void
	default_context_ptr: () => number
}

/** The Odin WebAssembly instance. */
export interface WasmState {
	exports: OdinExports
	memory: WebAssembly.Memory
}
