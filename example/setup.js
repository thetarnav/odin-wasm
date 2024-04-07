import * as wasm from "../wasm/runtime.js"

import {IS_DEV, WEB_SOCKET_PORT, MESSAGE_RELOAD, WASM_FILENAME} from "./_config.js"

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

/** @enum {(typeof Example_Kind)[keyof typeof Example_Kind]} */
const Example_Kind = /** @type {const} */ ({
	Rectangle: 0,
	Pyramid  : 1,
	Boxes    : 2,
	Look_At  : 3,
})

/** @type {Record<Example_Kind, string>} */
const example_kind_href_hashes = {
	[Example_Kind.Rectangle]: "#rectangle",
	[Example_Kind.Pyramid]  : "#pyramid",
	[Example_Kind.Boxes]    : "#boxes",
	[Example_Kind.Look_At]  : "#look-at",
}
/** @type {[Example_Kind, string][]} */
const example_kind_href_hashes_entries = /** @type {*} */(Object.entries(example_kind_href_hashes))

/** @type {Example_Kind} */
let example_kind = Example_Kind.Boxes

for (const [kind, hash] of example_kind_href_hashes_entries) {
	if (location.hash === hash) {
		example_kind = kind
	}

	const anchor = document.querySelector(`a[href="${hash}"]`)
	if (!anchor) continue

	anchor.addEventListener("click", event => {
		event.preventDefault()
		location.hash = hash
		location.reload()
	})

	if (location.hash === hash) {
		anchor.classList.add("active")
	}
}

/* Reload on hash change */
window.addEventListener("hashchange", () => location.reload())

/*
Wasm instance
*/

/**
 * @typedef  {object}                   Example_Exports
 * @property {Example_Start           } start
 * @property {Example_Frame           } frame
 * @property {Example_On_Window_Resize} on_window_resize
 * 
 * @typedef {wasm.OdinExports & Example_Exports} Wasm_Exports
 * 
 * @callback Example_Start
 * @param   {wasm.rawptr } ctx_ptr
 * @param   {Example_Kind} example_type
 * @returns {wasm.bool   }
 * 
 * @callback Example_Frame
 * @param   {wasm.rawptr} ctx_ptr
 * @param   {wasm.f32   } delta
 * @returns {void       }
 * 
 * @callback Example_On_Window_Resize
 * @param   {wasm.f32} window_w
 * @param   {wasm.f32} window_h
 * @param   {wasm.f32} canvas_w
 * @param   {wasm.f32} canvas_h
 * @param   {wasm.f32} canvas_x
 * @param   {wasm.f32} canvas_y
 * @returns {void    }
 */

const wasm_state = wasm.makeWasmState()
const webgl_state = wasm.webgl.makeWebGLState()

const src_instance = await wasm.fetchInstanciateWasm(WASM_FILENAME, {
	env: {}, // TODO
	odin_env: wasm.env.makeOdinEnv(wasm_state),
	odin_dom: wasm.dom.makeOdinDOM(wasm_state),
	webgl   : wasm.webgl.makeOdinWebGL(webgl_state, wasm_state),
	webgl2  : wasm.webgl.makeOdinWegGL2(webgl_state, wasm_state),
})

wasm.initWasmState(wasm_state, src_instance)
const exports = /** @type {Wasm_Exports} */ (wasm_state.exports)

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

const ok = exports.start(odin_ctx, example_kind)
if (!ok) throw Error("Failed to start example")

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
