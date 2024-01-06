/*

Copied and modified from Odin's wasm vendor library:
https://github.com/odin-lang/Odin/blob/master/vendor/wasm/js/runtime.js

*/

export * as env from "./env.js"
export * as mem from "./memory.js"
export * as dom from "./dom/dom.js"
export * as ls from "./ls/local_storage.js"

export * from "./types.js"

/**
 * @returns {import('./types.js').WasmInstance}
 */
export function zeroWasmInstance() {
	return {
		exports: /**@type {*}*/ (null),
		memory: /**@type {*}*/ (null),
	}
}

/**
 * Init a wasm instance with exports and memory from instanciated wasm module exports
 * @param {import('./types.js').WasmInstance} instance
 * @param {WebAssembly.Exports} exports
 */
export function initWasmInstance(instance, exports) {
	instance.exports = /**@type {import('./types.js').OdinExports}*/ (exports)
	instance.memory = instance.exports.memory
}
