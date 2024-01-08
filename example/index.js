import * as wasm from "../wasm/runtime.js"

import {WEB_SOCKET_PORT, WASM_PATH, MESSAGE_RELOAD} from "../constants.js"

import "./test.js"

// if (import.meta.env.DEV) {
wasm.env.enableConsole()
// }

/* To test dispatching custom events */
document.body.addEventListener("lol", () => {
	// eslint-disable-next-line no-console
	console.log("lol event has been received")
})

/* To test scroll events */
document.body.style.minHeight = "200vh"

const instance = wasm.zeroWasmInstance()

const response = await fetch(WASM_PATH)
const file = await response.arrayBuffer()
const source_instance = await WebAssembly.instantiate(file, {
	env: {}, // TODO
	odin_env: wasm.env.makeOdinEnv(instance),
	odin_ls: wasm.ls.makeOdinLS(instance),
	odin_dom: wasm.dom.makeOdinDOM(instance),
})
wasm.initWasmInstance(instance, source_instance.instance.exports)

console.log("Exports", instance.exports)
console.log("Memory", instance.memory)

instance.exports._start()
instance.exports._end()

const socket = new WebSocket("ws://localhost:" + WEB_SOCKET_PORT)

socket.addEventListener("message", event => {
	if (event.data === MESSAGE_RELOAD) {
		location.reload()
	}
})
