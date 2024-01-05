import * as wasm from "../wasm/runtime.js"

if (import.meta.env.DEV) {
	wasm.env.enableConsole()
}

const wasm_path = "dist/lib.wasm"

/**
 * @type {wasm.WasmInstance}
 */
const instance = {
	exports: /**@type {*}*/ (null),
	memory: /**@type {*}*/ (null),
}

const response = await fetch(wasm_path)
const file = await response.arrayBuffer()
const source_instance = await WebAssembly.instantiate(file, {
	env: {}, // TODO
	odin_env: wasm.env.makeOdinEnv(instance),
	odin_ls: wasm.ls.makeOdinLS(instance),
	odin_dom: wasm.dom.makeOdinDOM(instance),
})

instance.exports = /**@type {wasm.OdinExports}*/ (source_instance.instance.exports)
instance.memory = instance.exports.memory

console.log("Exports", instance.exports)
console.log("Memory", instance.memory)

instance.exports._start()
instance.exports._end()

document.body.style.minHeight = "200vh"
