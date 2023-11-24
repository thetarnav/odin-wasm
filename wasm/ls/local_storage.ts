import * as mem from '../mem.js'
import {wasm_memory} from '../runtime.js'

export const odin_ls = {
    get_bytes: (k_ptr: number, k_len: number, buf_ptr: number, buf_len: number): number => {
        const key = mem.load_string_bytes(wasm_memory.buffer, k_ptr, k_len)
        const val = localStorage.getItem(key)
        if (val === null) return 0

        return mem.store_string_bytes(wasm_memory.buffer, buf_ptr, buf_len, val)
    },

    get_string: (k_ptr: number, k_len: number, buf_ptr: number, buf_len: number): number => {
        const key = mem.load_string_raw(wasm_memory.buffer, k_ptr, k_len)
        const val = localStorage.getItem(key)
        if (val === null) return 0

        return mem.store_string_raw(wasm_memory.buffer, buf_ptr, buf_len, val)
    },

    set_bytes: (k_ptr: number, k_len: number, v_ptr: number, v_len: number): void => {
        const key = mem.load_string_bytes(wasm_memory.buffer, k_ptr, k_len)
        const str = mem.load_string_bytes(wasm_memory.buffer, v_ptr, v_len)

        localStorage.setItem(key, str)
    },

    set_string: (k_ptr: number, k_len: number, v_ptr: number, v_len: number): void => {
        const key = mem.load_string_raw(wasm_memory.buffer, k_ptr, k_len)
        const val = mem.load_string_raw(wasm_memory.buffer, v_ptr, v_len)

        localStorage.setItem(key, val)
    },

    remove: (k_ptr: number, k_len: number): void => {
        const key = mem.load_string_raw(wasm_memory.buffer, k_ptr, k_len)
        localStorage.removeItem(key)
    },

    clear: (): void => {
        localStorage.clear()
    },

    key: (index: number, buf_ptr: number, buf_len: number): number => {
        const key = localStorage.key(index)
        if (key === null) return 0

        return mem.store_string_raw(wasm_memory.buffer, buf_ptr, buf_len, key)
    },
    key_bytes: (index: number, buf_ptr: number, buf_len: number): number => {
        const key = localStorage.key(index)
        if (key === null) return 0

        return mem.store_string_bytes(wasm_memory.buffer, buf_ptr, buf_len, key)
    },

    length: (): number => {
        return localStorage.length
    },
}
