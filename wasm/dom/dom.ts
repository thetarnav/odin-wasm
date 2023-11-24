import {ByteOffset, REG_SIZE} from '../mem.js'
import {odin_exports, wmi} from '../runtime.js'

export interface DomOdinExports {
    odin_dom_do_event_callback: (data: number, callback: number, ctx_ptr: number) => void
}

const event_temp_data: {
    id_ptr: number
    id_len: number
    event: Event
    name_code: number
} = {
    id_ptr: 0,
    id_len: 0,
    event: null!,
    name_code: 0,
}

const listener_map = new Map<number, EventListener>()

export function init_event_raw(event_ptr: number /*Event*/) {
    const offset = new ByteOffset(event_ptr)

    const e = event_temp_data.event

    /* kind: Event_Kind */
    wmi.storeU32(offset.off(4), event_temp_data.name_code)

    /* target_kind: Event_Target_Kind */
    if (e.target == document) {
        wmi.storeU32(offset.off(4), 1)
    } else if (e.target == window) {
        wmi.storeU32(offset.off(4), 2)
    } else {
        wmi.storeU32(offset.off(4), 0)
    }

    /* current_target_kind: Event_Target_Kind */
    if (e.currentTarget == document) {
        wmi.storeU32(offset.off(4), 1)
    } else if (e.currentTarget == window) {
        wmi.storeU32(offset.off(4), 2)
    } else {
        wmi.storeU32(offset.off(4), 0)
    }

    /* id: string */
    wmi.storeUint(offset.off(REG_SIZE), event_temp_data.id_ptr)
    wmi.storeUint(offset.off(REG_SIZE), event_temp_data.id_len)
    wmi.storeUint(offset.off(REG_SIZE), 0) // padding

    /* timestamp: f64 */
    wmi.storeF64(offset.off(8), e.timeStamp * 1e-3)

    /* phase: Event_Phase */
    wmi.storeU8(offset.off(1), e.eventPhase)

    /* options: Event_Options */
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
    wmi.storeU8(offset.off(1), options)

    wmi.storeU8(offset.off(1), !!e.isComposing)
    wmi.storeU8(offset.off(1), !!e.isTrusted)

    void offset.off(0, 8)
    if (e instanceof MouseEvent) {
        wmi.storeI64(offset.off(8), e.screenX)
        wmi.storeI64(offset.off(8), e.screenY)
        wmi.storeI64(offset.off(8), e.clientX)
        wmi.storeI64(offset.off(8), e.clientY)
        wmi.storeI64(offset.off(8), e.offsetX)
        wmi.storeI64(offset.off(8), e.offsetY)
        wmi.storeI64(offset.off(8), e.pageX)
        wmi.storeI64(offset.off(8), e.pageY)
        wmi.storeI64(offset.off(8), e.movementX)
        wmi.storeI64(offset.off(8), e.movementY)

        wmi.storeU8(offset.off(1), !!e.ctrlKey)
        wmi.storeU8(offset.off(1), !!e.shiftKey)
        wmi.storeU8(offset.off(1), !!e.altKey)
        wmi.storeU8(offset.off(1), !!e.metaKey)

        wmi.storeI16(offset.off(2), e.button)
        wmi.storeU16(offset.off(2), e.buttons)
    } else if (e instanceof KeyboardEvent) {
        // Note: those strings are constructed
        // on the native side from buffers that
        // are filled later, so skip them
        void offset.off(REG_SIZE * 2, REG_SIZE)
        void offset.off(REG_SIZE * 2, REG_SIZE)

        wmi.storeU8(offset.off(1), e.location)

        wmi.storeU8(offset.off(1), !!e.ctrlKey)
        wmi.storeU8(offset.off(1), !!e.shiftKey)
        wmi.storeU8(offset.off(1), !!e.altKey)
        wmi.storeU8(offset.off(1), !!e.metaKey)

        wmi.storeU8(offset.off(1), !!e.repeat)

        wmi.storeI32(offset.off(REG_SIZE), e.key.length)
        wmi.storeI32(offset.off(REG_SIZE), e.code.length)
        wmi.storeString(offset.off(16, 1), e.key)
        wmi.storeString(offset.off(16, 1), e.code)
    } else if (e instanceof WheelEvent) {
        wmi.storeF64(offset.off(8), e.deltaX)
        wmi.storeF64(offset.off(8), e.deltaY)
        wmi.storeF64(offset.off(8), e.deltaZ)
        wmi.storeU32(offset.off(4), e.deltaMode)
    } else if (e instanceof Event) {
        if ('scrollX' in e) {
            wmi.storeF64(offset.off(8), e.scrollX)
            wmi.storeF64(offset.off(8), e.scrollY)
        }
    }
}

export function add_event_listener(
    id_ptr: number,
    id_len: number,
    name_ptr: number,
    name_len: number,
    name_code: number,
    data: number,
    callback: number,
    use_capture: boolean,
): boolean {
    const id = wmi.loadString(id_ptr, id_len)
    const name = wmi.loadString(name_ptr, name_len)
    const element = document.getElementById(id)
    if (!element) return false

    const listener = (e: Event) => {
        const odin_ctx = odin_exports.default_context_ptr()
        event_temp_data.id_ptr = id_ptr
        event_temp_data.id_len = id_len
        event_temp_data.event = e
        event_temp_data.name_code = name_code
        odin_exports.odin_dom_do_event_callback(data, callback, odin_ctx)
    }
    listener_map.set(callback, listener)
    element.addEventListener(name, listener, !!use_capture)
    return true
}

export function remove_event_listener(
    id_ptr: number,
    id_len: number,
    name_ptr: number,
    name_len: number,
    data: number,
    callback: number,
): boolean {
    const id = wmi.loadString(id_ptr, id_len)
    const name = wmi.loadString(name_ptr, name_len)
    const element = document.getElementById(id)
    if (!element) {
        return false
    }

    const listener = listener_map.get(callback)
    if (!listener) return false

    listener_map.delete(callback)
    element.removeEventListener(name, listener)
    return true
}

export function add_window_event_listener(
    name_ptr: number,
    name_len: number,
    name_code: number,
    data: number,
    callback: number,
    use_capture: boolean,
): boolean {
    const name = wmi.loadString(name_ptr, name_len)
    const element = window
    const listener = (e: Event) => {
        const odin_ctx = odin_exports.default_context_ptr()
        event_temp_data.id_ptr = 0
        event_temp_data.id_len = 0
        event_temp_data.event = e
        event_temp_data.name_code = name_code
        odin_exports.odin_dom_do_event_callback(data, callback, odin_ctx)
    }
    listener_map.set(callback, listener)
    element.addEventListener(name, listener, !!use_capture)
    return true
}

export function remove_window_event_listener(name_ptr, name_len, data, callback) {
    let name = wmi.loadString(name_ptr, name_len)
    let element = window
    let key = {data: data, callback: callback}

    const listener = listener_map.get(callback)
    if (!listener) return false

    listener_map.delete(callback)
    element.removeEventListener(name, listener)
    return true
}

export function event_stop_propagation() {
    if (event_temp_data && event_temp_data.event) {
        event_temp_data.event.eventStopPropagation()
    }
}
export function event_stop_immediate_propagation() {
    if (event_temp_data && event_temp_data.event) {
        event_temp_data.event.eventStopImmediatePropagation()
    }
}
export function event_prevent_default() {
    if (event_temp_data && event_temp_data.event) {
        event_temp_data.event.preventDefault()
    }
}

export function dispatch_custom_event(id_ptr, id_len, name_ptr, name_len, options_bits) {
    let id = wmi.loadString(id_ptr, id_len)
    let name = wmi.loadString(name_ptr, name_len)
    let options = {
        bubbles: (options_bits & (1 << 0)) !== 0,
        cancelabe: (options_bits & (1 << 1)) !== 0,
        composed: (options_bits & (1 << 2)) !== 0,
    }

    let element = document.getElementById(id)
    if (element) {
        element.dispatchEvent(new Event(name, options))
        return true
    }
    return false
}

export function get_element_value_f64(id_ptr, id_len) {
    let id = wmi.loadString(id_ptr, id_len)
    let element = document.getElementById(id)
    return element ? element.value : 0
}
export function get_element_value_string(id_ptr, id_len, buf_ptr, buf_len): number {
    const id = wmi.loadString(id_ptr, id_len)
    const element = document.getElementById(id)
    if (!element) return 0

    let str = element.value
    if (buf_len > 0 && buf_ptr) {
        let n = Math.min(buf_len, str.length)
        str = str.substring(0, n)
        this.mem.loadBytes(buf_ptr, buf_len).set(new TextEncoder().encode(str))
        return n
    }

    return 0
}
export function get_element_value_string_length(id_ptr, id_len) {
    let id = wmi.loadString(id_ptr, id_len)
    let element = document.getElementById(id)
    if (element) {
        return element.value.length
    }
    return 0
}
export function get_element_min_max(ptr_array2_f64, id_ptr, id_len) {
    let id = wmi.loadString(id_ptr, id_len)
    let element = document.getElementById(id)
    if (element) {
        let values = wmi.loadF64Array(ptr_array2_f64, 2)
        values[0] = element.min
        values[1] = element.max
    }
}
export function set_element_value_f64(id_ptr, id_len, value) {
    let id = wmi.loadString(id_ptr, id_len)
    let element = document.getElementById(id)
    if (element) {
        element.value = value
    }
}
export function set_element_value_string(id_ptr, id_len, value_ptr, value_id) {
    let id = wmi.loadString(id_ptr, id_len)
    let value = wmi.loadString(value_ptr, value_len)
    let element = document.getElementById(id)
    if (element) {
        element.value = value
    }
}

export function get_bounding_client_rect(rect_ptr, id_ptr, id_len) {
    let id = wmi.loadString(id_ptr, id_len)
    let element = document.getElementById(id)
    if (element) {
        let values = wmi.loadF64Array(rect_ptr, 4)
        let rect = element.getBoundingClientRect()
        values[0] = rect.left
        values[1] = rect.top
        values[2] = rect.right - rect.left
        values[3] = rect.bottom - rect.top
    }
}
export function window_get_rect(rect_ptr) {
    let values = wmi.loadF64Array(rect_ptr, 4)
    values[0] = window.screenX
    values[1] = window.screenY
    values[2] = window.screen.width
    values[3] = window.screen.height
}

export function window_get_scroll(pos_ptr) {
    let values = wmi.loadF64Array(pos_ptr, 2)
    values[0] = window.scrollX
    values[1] = window.scrollY
}
export function window_set_scroll(x, y) {
    window.scroll(x, y)
}

export function device_pixel_ratio() {
    return window.devicePixelRatio
}
