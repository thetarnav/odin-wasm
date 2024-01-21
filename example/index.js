import * as wasm from "../wasm/runtime.js"

import {IS_DEV, WEB_SOCKET_PORT, MESSAGE_RELOAD, WASM_FILENAME} from "./_config.js"

import * as t from "./types.js"

/*
Development server
*/

if (IS_DEV) {
	wasm.enableConsole()

	/* Hot Reload */
	new WebSocket("ws://localhost:" + WEB_SOCKET_PORT).addEventListener(
		"message",
		event => event.data === MESSAGE_RELOAD && location.reload(),
	)

	/* To test dispatching custom events */
	document.body.addEventListener("lol", () => {
		// eslint-disable-next-line no-console
		console.log("lol event has been received")
	})
}

/*
Example selection
*/

/** @type {Record<string, t.Example_Type_Value | undefined>} */
const example_hash_map = {
	"#2d": t.Example_Type.D2,
	"#3d": t.Example_Type.D3,
}
/** @type {t.Example_Type_Value} */
const example = example_hash_map[location.hash] ?? t.Example_Type.D3

for (const hash in example_hash_map) {
	const anchor = document.querySelector(`a[href="${hash}"]`)
	if (!anchor) continue

	anchor.addEventListener("click", event => {
		event.preventDefault()
		location.hash = hash
		location.reload()
	})

	if (example_hash_map[hash] === example) {
		anchor.classList.add("active")
	}
}

/*
Wasm instance
*/

const wasm_state = wasm.makeWasmState()
const webgl_state = wasm.webgl.makeWebGLState()

const src_instance = await wasm.fetchInstanciateWasm(WASM_FILENAME, {
	env: {}, // TODO
	odin_env: wasm.env.makeOdinEnv(wasm_state),
	odin_ls: wasm.ls.makeOdinLS(wasm_state),
	odin_dom: wasm.dom.makeOdinDOM(wasm_state),
	webgl: wasm.webgl.makeOdinWebGL(webgl_state, wasm_state),
})

wasm.initWasmState(wasm_state, src_instance)
const exports = /** @type {t.WasmExports} */ (wasm_state.exports)

if (IS_DEV) {
	// eslint-disable-next-line no-console
	console.log("WASM exports:", exports)
	// eslint-disable-next-line no-console
	console.log("WASM memory:", exports.memory)
}

/*
Main
*/

exports._start()
const odin_ctx = exports.default_context_ptr()
exports._end()

const ok = exports.start_example(odin_ctx, example)
if (!ok) throw new Error("Failed to start example")

void requestAnimationFrame(prev_time => {
	/** @type {FrameRequestCallback} */
	const frame = time => {
		const delta = time - prev_time
		prev_time = time
		exports.frame(odin_ctx, delta)
		void requestAnimationFrame(frame)
	}

	void requestAnimationFrame(frame)
})

const canvas = /** @type {HTMLCanvasElement} */ (document.getElementById("canvas"))
const dpr = window.devicePixelRatio || 1

function updateCanvasSize() {
	const rect = canvas.getBoundingClientRect()
	canvas.width = rect.width * dpr
	canvas.height = rect.height * dpr
	exports.on_window_resize(
		window.innerWidth,
		window.innerHeight,
		rect.width,
		rect.height,
		rect.left,
		rect.top,
	)
}
updateCanvasSize()
window.addEventListener("resize", updateCanvasSize)
