import * as wasm from "../wasm/runtime.js"

import {IS_DEV, WEB_SOCKET_PORT, MESSAGE_RELOAD, WASM_FILENAME} from "./_config.js"

// eslint-disable-next-line @typescript-eslint/no-unused-vars
import * as t from "./types.js"

if (IS_DEV) {
	wasm.enableConsole()

	/* Hot Reload */
	new WebSocket("ws://localhost:" + WEB_SOCKET_PORT).addEventListener("message", event => {
		event.data === MESSAGE_RELOAD && location.reload()
	})
}

/* To test dispatching custom events */
document.body.addEventListener("lol", () => {
	// eslint-disable-next-line no-console
	console.log("lol event has been received")
})

const wasm_state = wasm.makeWasmState()
const webgl_state = wasm.webgl.makeWebGLState()

const wasm_file = await fetch(WASM_FILENAME).then(r => r.arrayBuffer())
const src_instance = await WebAssembly.instantiate(wasm_file, {
	env: {}, // TODO
	odin_env: wasm.env.makeOdinEnv(wasm_state),
	odin_ls: wasm.ls.makeOdinLS(wasm_state),
	odin_dom: wasm.dom.makeOdinDOM(wasm_state),
	webgl: wasm.webgl.makeOdinWebGL(webgl_state, wasm_state),
})

wasm.initWasmState(wasm_state, src_instance)
const exports = /** @type {t.WasmExports} */ (wasm_state.exports)

exports._start()
const odin_ctx = exports.default_context_ptr()
exports._end()

void requestAnimationFrame(prev_time => {
	/** @type {FrameRequestCallback} */
	const frame = time => {
		const delta = (time - prev_time) * 0.001
		prev_time = time
		exports.frame(delta, odin_ctx)
		void requestAnimationFrame(frame)
	}

	void requestAnimationFrame(frame)
})
