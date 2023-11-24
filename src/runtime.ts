/*

Copied and modified from Odin's wasm vendor library:
https://github.com/odin-lang/Odin/blob/master/vendor/wasm/js/runtime.js

*/

import {odin_env} from './env'
import {local_storage} from './local_storage'
import * as mem from './mem'

export type OdinExports = {
    memory: WebAssembly.Memory
    _start: () => void
    _end: () => void
    default_context_ptr: () => number

    store_own_post: (content_length: number) => void
    loadAllStoredPosts: () => number
}

let string_to_pass: string | null = null

const load_last_string = (buf_ptr: number, buf_len: number): number => {
    if (string_to_pass === null) throw new Error('string_to_pass is null')

    const str = string_to_pass
    string_to_pass = null

    return mem.store_string_raw(wasm_memory.buffer, buf_ptr, buf_len, str)
}

const to_call_on_load: VoidFunction[] = []

export const storeOwnPost = (content: string): void => {
    if (!odin_exports) {
        to_call_on_load.push(() => storeOwnPost(content))
        return
    }
    string_to_pass = content
    odin_exports.store_own_post(content.length)
    // ? call subscribers here?
}

export type Post = {
    timestamp: number
    content: string
}

const deserializePost = (data: DataView, offset: mem.ByteOffset): Post => {
    const timestamp = Number(mem.load_offset_i64(data, offset))
    const content = mem.load_offset_string(data, offset)

    return {
        timestamp,
        content,
    }
}

export type PostListener = (post: Post[]) => void

const post_subscribers: PostListener[] = []

export const subscribeToPosts = (cb: PostListener): void => {
    post_subscribers.push(cb)
}

const initSubscribers = (): void => {
    if (post_subscribers.length === 0) return

    const post_ptr = odin_exports!.loadAllStoredPosts()

    const data = new DataView(wasm_memory.buffer)
    const posts = mem.load_slice(data, post_ptr, deserializePost)

    for (const cb of post_subscribers) {
        cb(posts)
    }
}

const notify_post_subscribers = (post_ptr: number): void => {
    if (post_subscribers.length === 0) return

    const data = new DataView(wasm_memory.buffer)
    const offset = new mem.ByteOffset(post_ptr)
    const post = deserializePost(data, offset)

    for (const cb of post_subscribers) {
        cb([post])
    }
}

const env = {
    load_last_string: load_last_string,
    notify_post_subscribers: notify_post_subscribers,
}

export let wasm_memory: WebAssembly.Memory
export let odin_exports: OdinExports | undefined

export type WasmResult = {
    wasm_memory: WebAssembly.Memory
    odin_exports: OdinExports
}

export const runWasm = async (wasm_path: string): Promise<WasmResult> => {
    const imports: WebAssembly.Imports = {
        env: env,
        odin_env: odin_env,
        local_storage: local_storage,
    }

    const response = await fetch(wasm_path)
    const file = await response.arrayBuffer()
    const wasm = await WebAssembly.instantiate(file, imports)
    odin_exports = wasm.instance.exports as any as OdinExports

    wasm_memory = odin_exports.memory

    console.log('Exports', odin_exports)
    console.log('Memory', odin_exports.memory)

    odin_exports._start()
    odin_exports._end()

    for (const cb of to_call_on_load) {
        cb()
    }
    to_call_on_load.length = 0

    initSubscribers()

    return {
        wasm_memory: wasm_memory,
        odin_exports: odin_exports,
    }
}
