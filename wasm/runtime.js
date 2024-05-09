/*

Copied and modified from Odin's wasm vendor library:
https://github.com/odin-lang/Odin/blob/master/vendor/wasm/js/runtime.js

*/

export * as env   from "./env.js"
export * as mem   from "./memory.js"
export * as dom   from "./dom/dom.js"
export * as ls    from "./ls/local_storage.js"
export * as webgl from "./webgl/index.js"
export * as ctx2d from "./ctx2d/ctx2d.js"

export * from "./types.js"
export * from "./console.js"

/** @returns {import("./types.js").WasmState} */
export function makeWasmState() {
	return {
		exports: /** @type {any} */ (null),
		memory: /** @type {any} */ (null),
	}
}

/**
 * Init a wasm instance with exports and memory from instanciated wasm module exports
 *
 * @param {import("./types.js").WasmState}            state
 * @param {WebAssembly.WebAssemblyInstantiatedSource} src_instance
 */
export function initWasmState(state, src_instance) {
	state.exports = /** @type {import("./types.js").OdinExports} */ (src_instance.instance.exports)
	state.memory = state.exports.memory
}

/**
 * @param   {string}                                             path
 * @param   {WebAssembly.Imports}                                imports
 * @returns {Promise<WebAssembly.WebAssemblyInstantiatedSource>}
 */
export function fetchInstanciateWasm(path, imports) {
	const wasm_fetch = fetch(path)

	return typeof WebAssembly.instantiateStreaming == "function"
		? WebAssembly.instantiateStreaming(wasm_fetch, imports)
		: wasm_fetch
				.then(r => r.arrayBuffer())
				.then(wasm_file => WebAssembly.instantiate(wasm_file, imports))
}
