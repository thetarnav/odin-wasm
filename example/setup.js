import * as wasm from "../wasm/runtime.js"
import * as mem  from "../wasm/memory.js"

import {IS_DEV, RELOAD_URL, WASM_FILENAME} from "./_config.js"

/*
Development server
*/

if (IS_DEV) {
	wasm.enableConsole()

	/* Hot Reload */
	const events = new EventSource(RELOAD_URL)
	events.onmessage = _ => {
		location.reload()
	}

	/* To test dispatching custom events */
	document.body.addEventListener("lol", () => {
		console.log("lol event has been received")
	})
}

/*
Example selection
*/

/** @enum {(typeof Example_Kind)[keyof typeof Example_Kind]} */
const Example_Kind = /** @type {const} */ ({
	Rectangle   : 0,
	Pyramid     : 1,
	Boxes       : 2,
	Camera      : 3,
	Lighting    : 4,
	Specular    : 5,
	Spotlight   : 6,
	Candy       : 7,
	Sol_System  : 8,
	Bezier_Curve: 9,
	Lathe       : 10,
	Suzanne     : 11,
	Chair       : 12,
	Book        : 13,
	Windmill    : 14,
})
/** @type {Example_Kind[]} */
const example_kinds = Object.values(Example_Kind)

/** @type {Record<Example_Kind, string>} */
const example_kind_href_hashes = {
	[Example_Kind.Rectangle]   : "#rectangle",
	[Example_Kind.Pyramid]     : "#pyramid",
	[Example_Kind.Boxes]       : "#boxes",
	[Example_Kind.Camera]      : "#camera",
	[Example_Kind.Lighting]    : "#lighting",
	[Example_Kind.Specular]    : "#specular",
	[Example_Kind.Spotlight]   : "#spotlight",
	[Example_Kind.Candy]       : "#candy",
	[Example_Kind.Sol_System]  : "#sol-system",
	[Example_Kind.Bezier_Curve]: "#bezier-curve",
	[Example_Kind.Lathe]       : "#lathe",
	[Example_Kind.Suzanne]     : "#suzanne",
	[Example_Kind.Chair]       : "#chair",
	[Example_Kind.Book]        : "#book",
	[Example_Kind.Windmill]    : "#windmill",
}

/** @type {Example_Kind} */
let example_kind = Example_Kind.Boxes

for (const kind of example_kinds) {
	const hash = example_kind_href_hashes[kind]
	if (location.hash === hash) {
		example_kind = kind
		break
	}
}

for (const kind of example_kinds) {
	const hash = example_kind_href_hashes[kind]
	const anchor = document.querySelector(`a[href="${hash}"]`)
	if (!anchor) continue

	anchor.addEventListener("click", event => {
		event.preventDefault()
		location.hash = hash
	})

	if (example_kind === kind) {
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
 * @property {Fetch_Alloc}              fetch_alloc
 *
 * @typedef {wasm.OdinExports & Example_Exports} Wasm_Exports
 *
 * @callback Example_Start
 * @param   {Example_Kind} example_type
 * @param   {mem.rawptr } ctx
 * @returns {mem.bool   }
 *
 * @callback Example_Frame
 * @param   {mem.f32   } delta
 * @param   {mem.rawptr} ctx
 * @returns {void       }
 *
 * @callback Example_On_Window_Resize
 * @param   {mem.f32}    window_w
 * @param   {mem.f32}    window_h
 * @param   {mem.f32}    canvas_w
 * @param   {mem.f32}    canvas_h
 * @param   {mem.f32}    canvas_x
 * @param   {mem.f32}    canvas_y
 * @param   {mem.rawptr} ctx
 * @returns {void}
 * 
 * @callback Fetch_Alloc
 * @param    {mem.rawptr} res_ptr
 * @param    {mem.int}    data_len
 */

/*
Fetch_Status :: enum u8 {
	Idle,
	Loading,
	Error,
	Done,
}
Fetch_Resource :: struct {
	status:    Fetch_Status,      // u8          4   4
	data:      []byte,            // [ptr, len]  8  12
	url:       string,            // [ptr, len]  8  20
	allocator: runtime.Allocator, // [ptr, ptr]  8  28
}
*/

const wasm_state  = wasm.makeWasmState()
const webgl_state = wasm.webgl.makeWebGLState()
const ctx2d_state = new wasm.ctx2d.Ctx2d_State()

const src_instance = await wasm.fetchInstanciateWasm(WASM_FILENAME, {
	env: {
		/**
		@param   {mem.rawptr} res_ptr
		@returns {void}        */
		fetch(res_ptr) {

			let data = new DataView(exports.memory.buffer)
			let url = mem.load_string(data, res_ptr+12)
			mem.store_u8(data, res_ptr, 1)

			;(async () => {
				try {
					let r = await fetch(url)
					let bytes = await r.arrayBuffer()

					exports.fetch_alloc(res_ptr, bytes.byteLength)
					data = new DataView(exports.memory.buffer)
					mem.store_bytes(
						exports.memory.buffer,
						mem.load_ptr(data, res_ptr+mem.REG_SIZE),
						new Uint8Array(bytes))
					mem.store_u8(data, res_ptr, 3)
					// if (r.body == null) {
					// 	throw new Error('No response body')
					// }
					// let reader = r.body.getReader()
					// for (;;) {
					// 	let res = await reader.read()
					// 	if (res.value != null) {
					// 		console.log('data', res.value)
					// 		exports.fetch_alloc(res_ptr, res.value.byteLength)
					// 	}
					// 	if (res.done) {
					// 		break
					// 	}
					// }
				} catch (err) {
					console.error('Fetch error:', err)
					let data = new DataView(exports.memory.buffer)
					mem.store_u8(data, res_ptr, 2)
				}
			})()
		},
	},
	odin_env: wasm.env  .makeOdinEnv    (wasm_state),
	odin_dom: wasm.dom  .makeOdinDOM    (wasm_state),
	webgl   : wasm.webgl.makeOdinWebGL  (wasm_state, webgl_state),
	webgl2  : wasm.webgl.makeOdinWegGL2 (wasm_state, webgl_state),
	ctx2d   : wasm.ctx2d.make_odin_ctx2d(wasm_state, ctx2d_state),
})

wasm.initWasmState(wasm_state, src_instance)
const exports = /** @type {Wasm_Exports} */ (wasm_state.exports)

if (IS_DEV) {
	console.log("WASM exports:", exports)
	console.log("WASM memory:", exports.memory)
}

/*
Main
*/

exports._start() // Calls main
const odin_ctx = exports.default_context_ptr()
/* _end() should be called when the program is done */
// exports._end()

const ok = exports.start(example_kind, odin_ctx)
if (!ok) throw Error("Failed to start example")

void requestAnimationFrame(prev_time => {
	/** @type {FrameRequestCallback} */
	const frame = time => {
		const delta = time - prev_time
		prev_time = time
		exports.frame(delta, odin_ctx)
		void requestAnimationFrame(frame)
	}

	void requestAnimationFrame(frame)
})

/* One canvas for webgl and the other for 2d */
const canvas_0 = /** @type {HTMLCanvasElement} */ (document.getElementById("canvas-1"))
const canvas_1 = /** @type {HTMLCanvasElement} */ (document.getElementById("canvas-0"))
const dpr = window.devicePixelRatio || 1

function updateCanvasSize() {
	const rect = canvas_0.getBoundingClientRect()

	canvas_0.width  = rect.width  * dpr
	canvas_0.height = rect.height * dpr
	canvas_1.width  = rect.width  * dpr
	canvas_1.height = rect.height * dpr

	exports.on_window_resize(
		window.innerWidth,
		window.innerHeight,
		rect.width,
		rect.height,
		rect.left,
		rect.top,
		odin_ctx,
	)
}
updateCanvasSize()
window.addEventListener("resize", updateCanvasSize)
