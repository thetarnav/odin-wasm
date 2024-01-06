import * as mem from "../memory.js"

/**
 * @param {import('../types.js').WasmInstance} wasm
 */
export function makeOdinLS(wasm) {
	return {
		/**
		 * @param {number} k_ptr
		 * @param {number} k_len
		 * @param {number} buf_ptr
		 * @param {number} buf_len
		 * @returns {number} number of bytes read
		 */
		get_bytes(k_ptr, k_len, buf_ptr, buf_len) {
			const key = mem.load_string_bytes(wasm.memory.buffer, k_ptr, k_len)
			const val = localStorage.getItem(key)
			if (val === null) return 0

			return mem.store_string_bytes(wasm.memory.buffer, buf_ptr, buf_len, val)
		},
		/**
		 * @param {number} k_ptr
		 * @param {number} k_len
		 * @param {number} buf_ptr
		 * @param {number} buf_len
		 * @returns {number} number of bytes read
		 */
		get_string(k_ptr, k_len, buf_ptr, buf_len) {
			const key = mem.load_string_raw(wasm.memory.buffer, k_ptr, k_len)
			const val = localStorage.getItem(key)
			if (val === null) return 0

			return mem.store_string_raw(wasm.memory.buffer, buf_ptr, buf_len, val)
		},
		/**
		 * @param {number} k_ptr
		 * @param {number} k_len
		 * @param {number} v_ptr
		 * @param {number} v_len
		 * @returns {void}
		 */
		set_bytes(k_ptr, k_len, v_ptr, v_len) {
			const key = mem.load_string_bytes(wasm.memory.buffer, k_ptr, k_len)
			const str = mem.load_string_bytes(wasm.memory.buffer, v_ptr, v_len)

			localStorage.setItem(key, str)
		},
		/**
		 * @param {number} k_ptr
		 * @param {number} k_len
		 * @param {number} v_ptr
		 * @param {number} v_len
		 * @returns {void}
		 */
		set_string(k_ptr, k_len, v_ptr, v_len) {
			const key = mem.load_string_raw(wasm.memory.buffer, k_ptr, k_len)
			const val = mem.load_string_raw(wasm.memory.buffer, v_ptr, v_len)

			localStorage.setItem(key, val)
		},
		/**
		 * @param {number} k_ptr
		 * @param {number} k_len
		 * @returns {void}
		 */
		remove(k_ptr, k_len) {
			const key = mem.load_string_raw(wasm.memory.buffer, k_ptr, k_len)
			localStorage.removeItem(key)
		},
		/**
		 * @returns {void}
		 */
		clear() {
			localStorage.clear()
		},
		/**
		 * @param {number} index
		 * @param {number} buf_ptr
		 * @param {number} buf_len
		 * @returns {number} number of bytes read
		 */
		key(index, buf_ptr, buf_len) {
			const key = localStorage.key(index)
			if (key === null) return 0

			return mem.store_string_raw(wasm.memory.buffer, buf_ptr, buf_len, key)
		},
		/**
		 * @param {number} index
		 * @param {number} buf_ptr
		 * @param {number} buf_len
		 * @returns {number} number of bytes read
		 */
		key_bytes(index, buf_ptr, buf_len) {
			const key = localStorage.key(index)
			if (key === null) return 0

			return mem.store_string_bytes(wasm.memory.buffer, buf_ptr, buf_len, key)
		},
		/**
		 * @returns {number}
		 */
		length: () => localStorage.length,
	}
}
