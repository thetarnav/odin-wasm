import {dom, env, ls, mem, type WasmInstance, type OdinExports} from '../wasm/runtime.js'

if (import.meta.env.DEV) {
    env.enableConsole()
}

const wasm_path = 'dist/lib.wasm'

const instance: WasmInstance = {
    exports: null!,
    memory: null!,
}

const response = await fetch(wasm_path)
const file = await response.arrayBuffer()
const wasm = await WebAssembly.instantiate(file, {
    env: {}, // TODO
    odin_env: env.makeOdinEnv(instance),
    odin_ls: ls.makeOdinLS(instance),
    odin_dom: dom.makeOdinDOM(instance),
})

instance.exports = wasm.instance.exports as any as OdinExports
instance.memory = instance.exports.memory

console.log('Exports', instance.exports)
console.log('Memory', instance.memory)

instance.exports._start()
instance.exports._end()

document.body.style.minHeight = '200vh'
