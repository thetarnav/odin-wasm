import * as wasm from "../wasm/runtime.js"

import {IS_DEV, WEB_SOCKET_PORT, WASM_PATH, MESSAGE_RELOAD} from "./_config.js"

import "./test.js" // TODO get rid of this

if (IS_DEV) {
	wasm.env.enableConsole()

	const socket = new WebSocket("ws://localhost:" + WEB_SOCKET_PORT)

	socket.addEventListener("message", event => {
		if (event.data === MESSAGE_RELOAD) {
			location.reload()
		}
	})
}

/* To test dispatching custom events */
document.body.addEventListener("lol", () => {
	// eslint-disable-next-line no-console
	console.log("lol event has been received")
})

/* To test scroll events */
document.body.style.minHeight = "200vh"

const wasm_instance = wasm.zeroWasmInstance()
const webgl_state = wasm.webgl.makeWebGLInterface()

const response = await fetch("/" + WASM_PATH)
const file = await response.arrayBuffer()
const source_instance = await WebAssembly.instantiate(file, {
	env: {}, // TODO
	odin_env: wasm.env.makeOdinEnv(wasm_instance),
	odin_ls: wasm.ls.makeOdinLS(wasm_instance),
	odin_dom: wasm.dom.makeOdinDOM(wasm_instance),
	webgl: wasm.webgl.makeOdinWebGL(webgl_state, wasm_instance),
})
wasm.initWasmInstance(wasm_instance, source_instance.instance.exports)

console.log("Exports", wasm_instance.exports)
console.log("Memory", wasm_instance.memory)

wasm_instance.exports._start()
wasm_instance.exports._end()
