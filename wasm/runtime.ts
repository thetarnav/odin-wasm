/*

Copied and modified from Odin's wasm vendor library:
https://github.com/odin-lang/Odin/blob/master/vendor/wasm/js/runtime.js

*/

import {odin_env} from './env.js'
import {odin_ls} from './ls/local_storage.js'

export interface OdinExports {
    memory: WebAssembly.Memory
    _start: () => void
    _end: () => void
    default_context_ptr: () => number
}

const env = {}

export let wasm_memory: WebAssembly.Memory
export let odin_exports: OdinExports | undefined

export type WasmResult = {
    wasm_memory: WebAssembly.Memory
    odin_exports: OdinExports
}

export async function runWasm(wasm_path: string): Promise<WasmResult> {
    const imports: WebAssembly.Imports = {
        env: env,
        odin_env: odin_env,
        odin_ls: odin_ls,
    }

    const response = await fetch(wasm_path)
    const file = await response.arrayBuffer()
    const wasm = await WebAssembly.instantiate(file, imports)
    odin_exports = wasm.instance.exports as any as OdinExports

    wasm_memory = odin_exports.memory

    console.log('Exports', odin_exports)
    console.log('Memory', odin_exports.memory)

    odin_exports._start()
    odin_exports._end()

    return {
        wasm_memory: wasm_memory,
        odin_exports: odin_exports,
    }
}
