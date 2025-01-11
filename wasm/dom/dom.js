import * as mem from "../memory.js"

export * from "../types.js"

/**
 * target to Event_Target_Kind
 *
 * @param   {EventTarget | null} target
 * @returns {number}
 */
function targetToKind(target) {
	switch (target) {
		case document:
			return 1
		case window:
			return 2
		default:
			return 0
	}
}

const KEYBOARD_MAX_KEY_SIZE = 16
const KEYBOARD_MAX_CODE_SIZE = 16

/** @param {import("../types.js").WasmState} _wasm */
export function makeOdinDOM(_wasm) {
	const wasm = /** @type {import("./types.js").OdinDOMInstance} */ (_wasm)

	let temp_id_ptr = 0
	let temp_id_len = 0
	let temp_event = new Event("")
	let temp_name_code = 0

	/**
	 * callback ptr to EventListener
	 *
	 * @type {Map<number, EventListener>}
	 */
	const listener_map = new Map()

	return {
		/**
		 * Store latest event data into wasm memory
		 *
		 * @param   {number} event_ptr Event
		 * @returns {void}
		 */
		init_event_raw(event_ptr) {
			let data      = new DataView(wasm.memory.buffer)
			let cursor    = mem.make_cursor(data, event_ptr)
			let e         = temp_event
			let name_code = temp_name_code
			let id_ptr    = temp_id_ptr
			let id_len    = temp_id_len

			/* kind: Event_Kind */
			mem.cursor_store_u32(data, cursor, name_code)

			/* target_kind: Event_Target_Kind */
			mem.cursor_store_u32(data, cursor, targetToKind(e.target))

			/* current_target_kind: Event_Target_Kind */
			mem.cursor_store_u32(data, cursor, targetToKind(e.currentTarget))

			/* id: string */
			mem.cursor_store_uint(data, cursor, id_ptr)
			mem.cursor_store_uint(data, cursor, id_len)
			mem.cursor_store_uint(data, cursor, 0) // padding

			/* timestamp: f64 */
			mem.cursor_store_f64(data, cursor, e.timeStamp * 1e-3)

			/* phase: Event_Phase */
			mem.cursor_store_u8(data, cursor, e.eventPhase)

			/* Event_Options bitset */
			let options = 0
			if (!!e.bubbles) {
				options |= 1 << 0 // 1
			}
			if (!!e.cancelable) {
				options |= 1 << 1 // 2
			}
			if (!!e.composed) {
				options |= 1 << 2 // 4
			}
			mem.cursor_store_u8(data, cursor, options)

			mem.cursor_store_bool(data, cursor, !!(/** @type {InputEvent} */ (e).isComposing))
			mem.cursor_store_bool(data, cursor, !!e.isTrusted)

			void mem.off(cursor, 0, 8) // padding
			// scroll
			if (e.type === "scroll") {
				mem.cursor_store_f64(data, cursor, window.scrollX)
				mem.cursor_store_f64(data, cursor, window.scrollY)
			}
			// visibility_change
			else if (e.type === "visibilitychange") {
				mem.cursor_store_bool(data, cursor, !document.hidden)
			}
			// wheel
			else if (e instanceof WheelEvent) {
				mem.cursor_store_f64(data, cursor, e.deltaX)
				mem.cursor_store_f64(data, cursor, e.deltaY)
				mem.cursor_store_f64(data, cursor, e.deltaZ)
				mem.cursor_store_u32(data, cursor, e.deltaMode)
			}
			// key
			else if (e instanceof KeyboardEvent) {
				// Note: those strings are constructed
				// on the native side from buffers that
				// are filled later, so skip them
				void mem.off(cursor, mem.REG_SIZE * 2, mem.REG_SIZE)
				void mem.off(cursor, mem.REG_SIZE * 2, mem.REG_SIZE)

				/* Key_Location */
				mem.cursor_store_u8(data, cursor, e.location)

				mem.cursor_store_bool(data, cursor, !!e.ctrlKey)
				mem.cursor_store_bool(data, cursor, !!e.shiftKey)
				mem.cursor_store_bool(data, cursor, !!e.altKey)
				mem.cursor_store_bool(data, cursor, !!e.metaKey)

				mem.cursor_store_bool(data, cursor, !!e.repeat)

				mem.cursor_store_i32(data, cursor, e.key.length)
				mem.cursor_store_i32(data, cursor, e.code.length)
				void mem.store_string_raw(
					wasm.memory.buffer,
					mem.off(cursor, 16, 1),
					KEYBOARD_MAX_KEY_SIZE,
					e.key,
				)
				void mem.store_string_raw(
					wasm.memory.buffer,
					mem.off(cursor, 16, 1),
					KEYBOARD_MAX_CODE_SIZE,
					e.code,
				)
			}
			// mouse
			else if (e instanceof MouseEvent) {
				mem.cursor_store_i64_number(data, cursor, e.screenX)
				mem.cursor_store_i64_number(data, cursor, e.screenY)
				mem.cursor_store_i64_number(data, cursor, e.clientX)
				mem.cursor_store_i64_number(data, cursor, e.clientY)
				mem.cursor_store_i64_number(data, cursor, e.offsetX)
				mem.cursor_store_i64_number(data, cursor, e.offsetY)
				mem.cursor_store_i64_number(data, cursor, e.pageX)
				mem.cursor_store_i64_number(data, cursor, e.pageY)
				mem.cursor_store_i64_number(data, cursor, e.movementX)
				mem.cursor_store_i64_number(data, cursor, e.movementY)

				mem.cursor_store_b8(data, cursor, !!e.ctrlKey)
				mem.cursor_store_b8(data, cursor, !!e.shiftKey)
				mem.cursor_store_b8(data, cursor, !!e.altKey)
				mem.cursor_store_b8(data, cursor, !!e.metaKey)

				mem.cursor_store_i16(data, cursor, e.button)
				mem.cursor_store_u16(data, cursor, e.buttons)
			}
		},
		/**
		 * @param   {number}  id_ptr      element id string
		 * @param   {number}  id_len
		 * @param   {number}  name_ptr    event name string (from event_kind_string enum array)
		 * @param   {number}  name_len
		 * @param   {number}  name_code   event name code (from Event_Kind enum)
		 * @param   {number}  data_ptr    user data pointer
		 * @param   {number}  callback    callback function pointer
		 * @param   {boolean} use_capture use capture flag
		 * @returns {boolean}
		 */
		add_event_listener(
			id_ptr,
			id_len,
			name_ptr,
			name_len,
			name_code,
			data_ptr,
			callback,
			use_capture,
		) {
			const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)

			const element = document.getElementById(id)
			if (!element) return false

			/**
			 * @param   {Event} e
			 * @returns {void}
			 */
			function listener(e) {
				const odin_ctx = wasm.exports.default_context_ptr()
				temp_id_ptr = id_ptr
				temp_id_len = id_len
				temp_event = e
				temp_name_code = name_code
				wasm.exports.odin_dom_do_event_callback(data_ptr, callback, odin_ctx)
			}

			// TODO banchmark if this is faster than using a map in js
			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)

			listener_map.set(callback, listener)
			element.addEventListener(name, listener, use_capture)

			return true
		},
		/**
		 * @param   {number}  name_ptr    event name string (from event_kind_string enum array)
		 * @param   {number}  name_len
		 * @param   {number}  name_code   event name code (from Event_Kind enum)
		 * @param   {number}  data_ptr    user data pointer
		 * @param   {number}  callback    callback function pointer
		 * @param   {boolean} use_capture use capture flag
		 * @returns {boolean}
		 */
		add_window_event_listener(name_ptr, name_len, name_code, data_ptr, callback, use_capture) {
			/**
			 * @param   {Event} e
			 * @returns {void}
			 */
			function listener(e) {
				const odin_ctx = wasm.exports.default_context_ptr()
				temp_id_ptr = 0
				temp_id_len = 0
				temp_event = e
				temp_name_code = name_code
				wasm.exports.odin_dom_do_event_callback(data_ptr, callback, odin_ctx)
			}

			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			window.addEventListener(name, listener, use_capture)
			listener_map.set(callback, listener)

			return true
		},
		/**
		 * @param   {number}  id_ptr   element id string
		 * @param   {number}  id_len
		 * @param   {number}  name_ptr event name string (from event_kind_string enum array)
		 * @param   {number}  name_len
		 * @param   {number}  data_ptr user data pointer
		 * @param   {number}  callback callback function pointer
		 * @returns {boolean}
		 */
		remove_event_listener(id_ptr, id_len, name_ptr, name_len, data_ptr, callback) {
			const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)

			const element = document.getElementById(id)
			if (!element) return false

			const listener = listener_map.get(callback)
			if (!listener) return false

			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)

			listener_map.delete(callback)
			element.removeEventListener(name, listener)

			return true
		},
		/**
		 * @param   {number}  name_ptr event name string (from event_kind_string enum array)
		 * @param   {number}  name_len
		 * @param   {number}  data_ptr user data pointer
		 * @param   {number}  callback callback function pointer
		 * @returns {boolean}
		 */
		remove_window_event_listener(name_ptr, name_len, data_ptr, callback) {
			const listener = listener_map.get(callback)
			if (!listener) return false

			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)

			listener_map.delete(callback)
			window.removeEventListener(name, listener)

			return true
		},
		/**
		 * Stop event propagation of the latest event
		 *
		 * @returns {void}
		 */
		event_stop_propagation() {
			temp_event.stopPropagation()
		},
		/**
		 * Stop immediate event propagation of the latest event
		 *
		 * @returns {void}
		 */
		event_stop_immediate_propagation() {
			temp_event.stopImmediatePropagation()
		},
		/**
		 * Prevent default action of the latest event
		 *
		 * @returns {void}
		 */
		event_prevent_default() {
			temp_event.preventDefault()
		},
		/**
		 * @param   {number}  id_ptr       element id string
		 * @param   {number}  id_len
		 * @param   {number}  name_ptr     event name string (from event_kind_string enum array)
		 * @param   {number}  name_len
		 * @param   {number}  options_bits Event_Options bitset
		 * @returns {boolean}
		 */
		dispatch_custom_event(id_ptr, id_len, name_ptr, name_len, options_bits) {
			const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
			const element = document.getElementById(id)
			if (!element) return false

			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			const options = {
				bubbles: (options_bits & (1 << 0)) !== 0,
				cancelable: (options_bits & (1 << 1)) !== 0,
				composed: (options_bits & (1 << 2)) !== 0,
			}
			void element.dispatchEvent(new Event(name, options))

			return true
		},
		/**
		 * Get input element value as f64
		 *
		 * @param   {number} id_ptr element id string
		 * @param   {number} id_len
		 * @returns {number}        input element value as f64
		 */
		get_element_value_f64(id_ptr, id_len) {
			const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
			const element = document.getElementById(id)
			return element instanceof HTMLInputElement ? element.valueAsNumber : 0
		},
		/**
		 * Get input element value as string
		 *
		 * @param   {number} id_ptr  element id string
		 * @param   {number} id_len
		 * @param   {number} buf_ptr string buffer
		 * @param   {number} buf_len
		 * @returns {number}         written string length
		 */
		get_element_value_string(id_ptr, id_len, buf_ptr, buf_len) {
			const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
			const element = document.getElementById(id)

			if (!(element instanceof HTMLInputElement) || buf_len <= 0 || !buf_ptr) return 0

			let str = element.value
			const n = Math.min(buf_len, str.length)
			str = str.substring(0, n)

			const bytes = mem.load_bytes(wasm.memory.buffer, buf_ptr, buf_len)
			new TextEncoder().encodeInto(str, bytes)

			return n
		},
		/**
		 * Get length of input element value
		 *
		 * @param   {number} id_ptr element id string
		 * @param   {number} id_len
		 * @returns {number}        input element value length
		 */
		get_element_value_string_length(id_ptr, id_len) {
			const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
			const element = document.getElementById(id)
			return element instanceof HTMLInputElement ? element.value.length : 0
		},
		/**
		 * Get range input element min and max values
		 *
		 * @param   {number} ptr_array2_f64 array of 2 f64 values
		 * @param   {number} id_ptr         element id string
		 * @param   {number} id_len
		 * @returns {void}
		 */
		get_element_min_max(ptr_array2_f64, id_ptr, id_len) {
			const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
			const element = document.getElementById(id)

			if (element instanceof HTMLInputElement) {
				const values = mem.load_f64_array(wasm.memory.buffer, ptr_array2_f64, 2)

				values[0] = Number(element.min)
				values[1] = Number(element.max)
			}
		},
		/**
		 * Set number input element value
		 *
		 * @param   {number} id_ptr element id string
		 * @param   {number} id_len
		 * @param   {number} value  f64 value
		 * @returns {void}
		 */
		set_element_value_f64(id_ptr, id_len, value) {
			const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
			const element = document.getElementById(id)

			if (element instanceof HTMLInputElement) {
				element.value = String(value)
			}
		},
		/**
		 * Set string input element value
		 *
		 * @param   {number} id_ptr    element id string
		 * @param   {number} id_len
		 * @param   {number} value_ptr string buffer
		 * @param   {number} value_len
		 * @returns {void}
		 */
		set_element_value_string(id_ptr, id_len, value_ptr, value_len) {
			const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
			const value = mem.load_string_raw(wasm.memory.buffer, value_ptr, value_len)
			const element = document.getElementById(id)
			if (element instanceof HTMLInputElement) {
				element.value = value
			}
		},
		/**
		 * Get elements bounding rect ({@link DOMRect})
		 *
		 * @param   {number} rect_ptr pointer to Rect
		 * @param   {number} id_ptr   element id string
		 * @param   {number} id_len
		 * @returns {void}
		 */
		get_bounding_client_rect(rect_ptr, id_ptr, id_len) {
			const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
			const element = document.getElementById(id)
			if (!element) return

			const values = mem.load_f64_array(wasm.memory.buffer, rect_ptr, 4)
			const rect = element.getBoundingClientRect()

			values[0] = rect.left
			values[1] = rect.top
			values[2] = rect.right - rect.left
			values[3] = rect.bottom - rect.top
		},
		/**
		 * @param   {number} size_ptr pointer to [2]f64
		 * @returns {void}
		 */
		get_window_inner_size(size_ptr) {
			const values = mem.load_f64_array(wasm.memory.buffer, size_ptr, 2)
			values[0] = window.innerWidth
			values[1] = window.innerHeight
		},
		/**
		 * @param   {number} size_ptr pointer to [2]f64
		 * @returns {void}
		 */
		get_window_outer_size(size_ptr) {
			const values = mem.load_f64_array(wasm.memory.buffer, size_ptr, 2)
			values[0] = window.outerWidth
			values[1] = window.outerHeight
		},
		/**
		 * @param   {number} size_ptr pointer to [2]f64
		 * @returns {void}
		 */
		get_screen_size(size_ptr) {
			const values = mem.load_f64_array(wasm.memory.buffer, size_ptr, 2)
			values[0] = window.screen.width
			values[1] = window.screen.height
		},
		/**
		 * @param   {number} pos_ptr pointer to [2]f64
		 * @returns {void}
		 */
		get_window_position(pos_ptr) {
			const values = mem.load_f64_array(wasm.memory.buffer, pos_ptr, 2)
			values[0] = window.screenX
			values[1] = window.screenY
		},
		/**
		 * @param   {number} pos_ptr pointer to [2]f64
		 * @returns {void}
		 */
		get_window_scroll(pos_ptr) {
			const values = mem.load_f64_array(wasm.memory.buffer, pos_ptr, 2)
			values[0] = window.scrollX
			values[1] = window.scrollY
		},
		/**
		 * @param   {number} x scroll x
		 * @param   {number} y scroll y
		 * @returns {void}
		 */
		set_window_scroll(x, y) {
			window.scroll(x, y)
		},
		/**
		 * Get window device pixel ratio
		 *
		 * @returns {number} device pixel ratio
		 */
		device_pixel_ratio() {
			return window.devicePixelRatio
		},
	}
}
