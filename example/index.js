import * as wasm from "../wasm/runtime.js"

import {
	IS_DEV,
	WEB_SOCKET_PORT,
	MESSAGE_RELOAD,
	WASM_FILENAME,
	MESSAGE_RECOMPILE,
} from "./_config.js"

// eslint-disable-next-line @typescript-eslint/no-unused-vars
import * as t from "./types.js"

if (IS_DEV) {
	wasm.enableConsole()

	/* Hot Reload */
	new WebSocket("ws://localhost:" + WEB_SOCKET_PORT).addEventListener("message", event => {
		switch (event.data) {
			case MESSAGE_RELOAD: {
				location.reload()
				break
			}
			case MESSAGE_RECOMPILE: {
				// eslint-disable-next-line no-console
				console.clear()
				void runWasm()
				break
			}
		}
	})
}

let last_raf = 0
let last_version = 0

async function runWasm() {
	last_version += 1
	const version = last_version

	const wasm_state = wasm.makeWasmState()
	const webgl_state = wasm.webgl.makeWebGLState()

	const src_instance = await wasm.fetchInstanciateWasm(WASM_FILENAME, {
		env: {}, // TODO
		odin_env: wasm.env.makeOdinEnv(wasm_state),
		odin_ls: wasm.ls.makeOdinLS(wasm_state),
		odin_dom: wasm.dom.makeOdinDOM(wasm_state),
		webgl: wasm.webgl.makeOdinWebGL(webgl_state, wasm_state),
	})

	if (version !== last_version) return

	wasm.initWasmState(wasm_state, src_instance)
	const exports = /** @type {t.WasmExports} */ (wasm_state.exports)

	exports._start()
	const odin_ctx = exports.default_context_ptr()
	exports._end()

	cancelAnimationFrame(last_raf)
	last_raf = requestAnimationFrame(prev_time => {
		/** @type {FrameRequestCallback} */
		const frame = time => {
			const delta = (time - prev_time) * 0.001
			prev_time = time
			exports.frame(delta, odin_ctx)
			last_raf = requestAnimationFrame(frame)
		}

		last_raf = requestAnimationFrame(frame)
	})
}

void runWasm()

/* To test dispatching custom events */
document.body.addEventListener("lol", () => {
	// eslint-disable-next-line no-console
	console.log("lol event has been received")
})
