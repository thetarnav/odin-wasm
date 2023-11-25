import * as mem from '../memory.js'
import type {WasmInstance, OdinExports} from '../runtime.js'

export interface DomOdinExports extends OdinExports {
    odin_dom_do_event_callback: (data: number, callback: number, ctx_ptr: number) => void
}

/**
 * target to Event_Target_Kind
 */
function targetToKind(target: EventTarget | null): number {
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

// eslint-disable-next-line @typescript-eslint/explicit-function-return-type
export function makeOdinDOM(_wasm: WasmInstance) {
    const wasm = _wasm as WasmInstance & {exports: DomOdinExports}

    let temp_id_ptr = 0
    let temp_id_len = 0
    let temp_event = new Event('')
    let temp_name_code = 0

    /**
     * callback ptr to EventListener
     */
    const listener_map = new Map<number, EventListener>()

    return {
        init_event_raw(event_ptr: number /*Event*/): void {
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

            mem.store_offset_bool(data, offset, !!(e as InputEvent).isComposing)
            mem.store_offset_bool(data, offset, !!e.isTrusted)

            void mem.off(offset, 0, 8) // padding
            // scroll
            if (e.type === 'scroll') {
                mem.store_offset_f64(data, offset, window.scrollX)
                mem.store_offset_f64(data, offset, window.scrollY)
            }
            // visibility_change
            else if (e.type === 'visibilitychange') {
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

        add_event_listener(
            id_ptr: number,
            id_len: number,
            name_ptr: number,
            name_len: number,
            name_code: number,
            data_ptr: number,
            callback: number,
            use_capture: boolean,
        ): boolean {
            const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)

            const element = document.getElementById(id)
            if (!element) return false

            function listener(e: Event): void {
                const odin_ctx = wasm.exports.default_context_ptr()
                temp_id_ptr = id_ptr
                temp_id_len = id_len
                temp_event = e
                temp_name_code = name_code
                wasm.exports.odin_dom_do_event_callback(data_ptr, callback, odin_ctx)
            }

            const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)

            listener_map.set(callback, listener)
            element.addEventListener(name, listener, use_capture)

            return true
        },
        add_window_event_listener(
            name_ptr: number,
            name_len: number,
            name_code: number,
            data_ptr: number,
            callback: number,
            use_capture: boolean,
        ): boolean {
            function listener(e: Event): void {
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

        remove_event_listener(
            id_ptr: number,
            id_len: number,
            name_ptr: number,
            name_len: number,
            data_ptr: number,
            callback: number,
        ): boolean {
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
        remove_window_event_listener(
            name_ptr: number,
            name_len: number,
            data_ptr: number,
            callback: number,
        ): boolean {
            const listener = listener_map.get(callback)
            if (!listener) return false

            const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)

            listener_map.delete(callback)
            window.removeEventListener(name, listener)

            return true
        },

        event_stop_propagation(): void {
            temp_event.stopPropagation()
        },
        event_stop_immediate_propagation(): void {
            temp_event.stopImmediatePropagation()
        },
        event_prevent_default(): void {
            temp_event.preventDefault()
        },

        dispatch_custom_event(
            id_ptr: number,
            id_len: number,
            name_ptr: number,
            name_len: number,
            options_bits: number,
        ): boolean {
            const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
            const element = document.getElementById(id)
            if (!element) return false

            const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
            const options: EventInit = {
                bubbles: (options_bits & (1 << 0)) !== 0,
                cancelable: (options_bits & (1 << 1)) !== 0,
                composed: (options_bits & (1 << 2)) !== 0,
            }
            void element.dispatchEvent(new Event(name, options))

            return true
        },
        get_element_value_f64(id_ptr: number, id_len: number): number {
            const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
            const element = document.getElementById(id)
            return element instanceof HTMLInputElement ? element.valueAsNumber : 0
        },
        get_element_value_string(
            id_ptr: number,
            id_len: number,
            buf_ptr: number,
            buf_len: number,
        ): number {
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
        get_element_value_string_length(id_ptr: number, id_len: number): number {
            const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
            const element = document.getElementById(id)
            return element instanceof HTMLInputElement ? element.value.length : 0
        },
        get_element_min_max(ptr_array2_f64: number, id_ptr: number, id_len: number): void {
            const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
            const element = document.getElementById(id)

            if (element instanceof HTMLInputElement) {
                const values = mem.load_f64_array(wasm.memory.buffer, ptr_array2_f64, 2)

                values[0] = Number(element.min)
                values[1] = Number(element.max)
            }
        },
        set_element_value_f64(id_ptr: number, id_len: number, value: number): void {
            const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
            const element = document.getElementById(id)

            if (element instanceof HTMLInputElement) {
                element.value = String(value)
            }
        },
        set_element_value_string(
            id_ptr: number,
            id_len: number,
            value_ptr: number,
            value_len: number,
        ): void {
            const id = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
            const value = mem.load_string_raw(wasm.memory.buffer, value_ptr, value_len)
            const element = document.getElementById(id)
            if (element instanceof HTMLInputElement) {
                element.value = value
            }
        },

        get_bounding_client_rect(rect_ptr: number, id_ptr: number, id_len: number): void {
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
        window_get_rect(rect_ptr: number): void {
            const values = mem.load_f64_array(wasm.memory.buffer, rect_ptr, 4)

            values[0] = window.screenX
            values[1] = window.screenY
            values[2] = window.screen.width
            values[3] = window.screen.height
        },

        window_get_scroll(pos_ptr: number): void {
            const values = mem.load_f64_array(wasm.memory.buffer, pos_ptr, 2)

            values[0] = window.scrollX
            values[1] = window.scrollY
        },
        window_set_scroll(x: number, y: number): void {
            window.scroll(x, y)
        },

        device_pixel_ratio(): number {
            return window.devicePixelRatio
        },
    }
}
