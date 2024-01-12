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

/** @param {import("../types.js").WasmInstance} _wasm */
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
			const offset = mem.makeByteOffset(event_ptr)
			const data = new DataView(wasm.memory.buffer)
			const e = temp_event
			const name_code = temp_name_code
			const id_ptr = temp_id_ptr
			const id_len = temp_id_len

			/* kind: Event_Kind */
			mem.store_offset_u32(data, offset, name_code)

			/* target_kind: Event_Target_Kind */
			mem.store_offset_u32(data, offset, targetToKind(e.target))

			/* current_target_kind: Event_Target_Kind */
			mem.store_offset_u32(data, offset, targetToKind(e.currentTarget))

			/* id: string */
			mem.store_offset_uint(data, offset, id_ptr)
			mem.store_offset_uint(data, offset, id_len)
			mem.store_offset_uint(data, offset, 0) // padding

			/* timestamp: f64 */
			mem.store_offset_f64(data, offset, e.timeStamp * 1e-3)

			/* phase: Event_Phase */
			mem.store_offset_u8(data, offset, e.eventPhase)

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
			mem.store_offset_u8(data, offset, options)

			mem.store_offset_bool(data, offset, !!(/** @type {InputEvent} */ (e).isComposing))
			mem.store_offset_bool(data, offset, !!e.isTrusted)

			void mem.off(offset, 0, 8) // padding
			// scroll
			if (e.type === "scroll") {
				mem.store_offset_f64(data, offset, window.scrollX)
				mem.store_offset_f64(data, offset, window.scrollY)
			}
			// visibility_change
			else if (e.type === "visibilitychange") {
				mem.store_offset_bool(data, offset, !document.hidden)
			}
			// wheel
			else if (e instanceof WheelEvent) {
				mem.store_offset_f64(data, offset, e.deltaX)
				mem.store_offset_f64(data, offset, e.deltaY)
				mem.store_offset_f64(data, offset, e.deltaZ)
				mem.store_offset_u32(data, offset, e.deltaMode)
			}
			// key
			else if (e instanceof KeyboardEvent) {
				// Note: those strings are constructed
				// on the native side from buffers that
				// are filled later, so skip them
				void mem.off(offset, mem.REG_SIZE * 2, mem.REG_SIZE)
				void mem.off(offset, mem.REG_SIZE * 2, mem.REG_SIZE)

				/* Key_Location */
				mem.store_offset_u8(data, offset, e.location)

				mem.store_offset_bool(data, offset, !!e.ctrlKey)
				mem.store_offset_bool(data, offset, !!e.shiftKey)
				mem.store_offset_bool(data, offset, !!e.altKey)
				mem.store_offset_bool(data, offset, !!e.metaKey)

				mem.store_offset_bool(data, offset, !!e.repeat)

				mem.store_offset_i32(data, offset, e.key.length)
				mem.store_offset_i32(data, offset, e.code.length)
				void mem.store_string_raw(
					wasm.memory.buffer,
					mem.off(offset, 16, 1),
					KEYBOARD_MAX_KEY_SIZE,
					e.key,
				)
				void mem.store_string_raw(
					wasm.memory.buffer,
					mem.off(offset, 16, 1),
					KEYBOARD_MAX_CODE_SIZE,
					e.code,
				)
			}
			// mouse
			else if (e instanceof MouseEvent) {
				mem.store_offset_i64_number(data, offset, e.screenX)
				mem.store_offset_i64_number(data, offset, e.screenY)
				mem.store_offset_i64_number(data, offset, e.clientX)
				mem.store_offset_i64_number(data, offset, e.clientY)
				mem.store_offset_i64_number(data, offset, e.offsetX)
				mem.store_offset_i64_number(data, offset, e.offsetY)
				mem.store_offset_i64_number(data, offset, e.pageX)
				mem.store_offset_i64_number(data, offset, e.pageY)
				mem.store_offset_i64_number(data, offset, e.movementX)
				mem.store_offset_i64_number(data, offset, e.movementY)

				mem.store_offset_b8(data, offset, !!e.ctrlKey)
				mem.store_offset_b8(data, offset, !!e.shiftKey)
				mem.store_offset_b8(data, offset, !!e.altKey)
				mem.store_offset_b8(data, offset, !!e.metaKey)

				mem.store_offset_i16(data, offset, e.button)
				mem.store_offset_u16(data, offset, e.buttons)
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

			const str_buf = mem.load_bytes(wasm.memory.buffer, buf_ptr, buf_len)
			str_buf.set(new TextEncoder().encode(str))

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
		 * Get window rect
		 *
		 * @param   {number} rect_ptr pointer to Rect
		 * @returns {void}
		 */
		window_get_rect(rect_ptr) {
			const values = mem.load_f64_array(wasm.memory.buffer, rect_ptr, 4)

			values[0] = window.screenX
			values[1] = window.screenY
			values[2] = window.screen.width
			values[3] = window.screen.height
		},
		/**
		 * Get window scroll
		 *
		 * @param   {number} pos_ptr pointer to [2]f64
		 * @returns {void}
		 */
		window_get_scroll(pos_ptr) {
			const values = mem.load_f64_array(wasm.memory.buffer, pos_ptr, 2)

			values[0] = window.scrollX
			values[1] = window.scrollY
		},
		/**
		 * Set window scroll
		 *
		 * @param   {number} x scroll x
		 * @param   {number} y scroll y
		 * @returns {void}
		 */
		window_set_scroll(x, y) {
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
