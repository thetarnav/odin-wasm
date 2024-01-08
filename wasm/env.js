import * as mem from "./memory.js"

export let CONSOLE_ENABLED = false
/** @returns {void} */
export function enableConsole() {
	CONSOLE_ENABLED = true
}

/**
 * @param   {boolean} [condition]
 * @param   {...any}  data
 * @returns {void}
 */
export function assert(condition, ...data) {
	if (!CONSOLE_ENABLED) return
	// eslint-disable-next-line no-console
	console.assert(condition, ...data)
}
/**
 * @param   {...any} data
 * @returns {void}
 */
export function log(...data) {
	if (!CONSOLE_ENABLED) return
	// eslint-disable-next-line no-console
	console.log(...data)
}
/**
 * @param   {...any} data
 * @returns {void}
 */
export function warn(...data) {
	if (!CONSOLE_ENABLED) return
	// eslint-disable-next-line no-console
	console.warn(...data)
}
/**
 * @param   {...any} data
 * @returns {void}
 */
export function error(...data) {
	if (!CONSOLE_ENABLED) return
	// eslint-disable-next-line no-console
	console.error(...data)
}

const ERROR_STYLE = "color: #eee; background-color: #d10; padding: 2px 4px"

/** @returns {void} */
export function eprintln(/** @type {string} */ text) {
	if (!CONSOLE_ENABLED) return

	// eslint-disable-next-line no-console
	console.log("%c" + text, ERROR_STYLE)
}

let buffer = ""
/** @type {number | null} */
let last_fd = null

/**
 * @param   {number} fd
 * @param   {string} str
 * @returns {void}
 */
function writeToConsole(fd, str) {
	switch (true) {
		// invalid fd
		case fd !== 1 && fd !== 2:
			buffer = ""
			last_fd = null
			throw new Error(`Invalid fd (${fd}) to 'write' ${str}`)
		// flush on newline
		case str[str.length - 1] === "\n":
			buffer += str.slice(0, -1)
			fd === 1 ? log(buffer) : eprintln(buffer)
			buffer = ""
			last_fd = null
			break
		// flush on fd change
		case last_fd !== fd && last_fd !== null:
			buffer = ""
			last_fd = fd
			break
		// append to buffer
		default:
			buffer += str
			last_fd = fd
	}
}

/** @param {import("./types.js").WasmInstance} wasm */
export function makeOdinEnv(wasm) {
	return {
		/**
		 * @param   {number} fd
		 * @param   {number} ptr
		 * @param   {number} len
		 * @returns {void}
		 */
		write: (fd, ptr, len) => {
			if (!CONSOLE_ENABLED) return
			const str = mem.load_string_raw(wasm.memory.buffer, ptr, len)
			writeToConsole(fd, str)
		},
		/** @returns {never} */
		trap: () => {
			throw new Error()
		},
		/**
		 * @param   {number} ptr
		 * @param   {number} len
		 * @returns {void}
		 */
		alert: (ptr, len) => {
			const str = mem.load_string_raw(wasm.memory.buffer, ptr, len)
			alert(str)
		},
		/** @returns {never} */
		abort: () => {
			throw new Error("abort")
		},
		/**
		 * @param   {number} ptr
		 * @param   {number} len
		 * @returns {void}
		 */
		evaluate: (ptr, len) => {
			const str = mem.load_string_raw(wasm.memory.buffer, ptr, len)
			void eval.call(null, str)
		},
		/** @returns {bigint} */
		time_now: () => BigInt(Date.now()),
		/** @returns {bigint} */
		tick_now: () => BigInt(performance.now()),
		/**
		 * @param   {number} duration_ms
		 * @returns {void}
		 */
		time_sleep: duration_ms => {
			if (duration_ms > 0) {
				// TODO(bill): Does this even make any sense?
			}
		},
		/**
		 * @param   {number} x
		 * @returns {number}
		 */
		sqrt: Math.sqrt,
		/**
		 * @param   {number} x
		 * @returns {number}
		 */
		sin: Math.sin,
		/**
		 * @param   {number} x
		 * @returns {number}
		 */
		cos: Math.cos,
		/**
		 * @param   {number} x
		 * @param   {number} y
		 * @returns {number}
		 */
		pow: Math.pow,
		/**
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} z
		 * @returns {number}
		 */
		fmuladd: (x, y, z) => x * y + z,
		/**
		 * @param   {number} x
		 * @returns {number}
		 */
		ln: Math.log,
		/**
		 * @param   {number} x
		 * @returns {number}
		 */
		exp: Math.exp,
		/**
		 * @param   {number} x
		 * @param   {number} exp
		 * @returns {number}
		 */
		ldexp: (x, exp) => x * Math.pow(2, exp),
		/**
		 * @param   {number} addr
		 * @param   {number} len
		 * @returns {void}
		 */
		rand_bytes: (addr, len) => {
			const view = new Uint8Array(wasm.memory.buffer, addr, len)
			void crypto.getRandomValues(view)
		},
	}
}
