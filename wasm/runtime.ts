/*

Copied and modified from Odin's wasm vendor library:
https://github.com/odin-lang/Odin/blob/master/vendor/wasm/js/runtime.js

*/

import {makeOdinEnv} from './env.js'

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

export async function runWasm(wasm_path: string): Promise<WasmInstance> {
    const result: WasmInstance = {
        exports: null!,
        memory: null!,
    }

    const response = await fetch(wasm_path)
    const file = await response.arrayBuffer()
    const wasm = await WebAssembly.instantiate(file, {
        env: {}, // TODO
        odin_env: makeOdinEnv(result),
    })

    result.exports = wasm.instance.exports as any as OdinExports
    result.memory = result.exports.memory

    console.log('Exports', result.exports)
    console.log('Memory', result.memory)

    result.exports._start()
    result.exports._end()

    return result
}
