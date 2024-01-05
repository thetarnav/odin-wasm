export interface OdinExports extends WebAssembly.Exports {
    memory: WebAssembly.Memory
    _start: () => void
    _end: () => void
    default_context_ptr: () => number
}

export interface WasmInstance {
    exports: OdinExports
    memory: WebAssembly.Memory
}
