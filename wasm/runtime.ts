/*

Copied and modified from Odin's wasm vendor library:
https://github.com/odin-lang/Odin/blob/master/vendor/wasm/js/runtime.js

*/

export * as env from './env.js'
export * as mem from './memory.js'
export * as dom from './dom/dom.js'
export * as ls from './ls/local_storage.js'

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
