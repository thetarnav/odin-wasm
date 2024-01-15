export type bool = boolean
export type b8 = boolean
export type b16 = boolean
export type b32 = boolean
export type b64 = boolean

export type int = number
export type i8 = number
export type i16 = number
export type i32 = number
export type i64 = number
export type i128 = number
export type uint = number
export type u8 = number
export type u16 = number
export type u32 = number
export type u64 = number
export type u128 = number
export type uintptr = number

export type i16le = number
export type i32le = number
export type i64le = number
export type i128le = number
export type u16le = number
export type u32le = number
export type u64le = number
export type u128le = number
export type i16be = number
export type i32be = number
export type i64be = number
export type i128be = number
export type u16be = number
export type u32be = number
export type u64be = number
export type u128be = number

export type f16 = number
export type f32 = number
export type f64 = number

export type f16le = number
export type f32le = number
export type f64le = number
export type f16be = number
export type f32be = number
export type f64be = number

export type complex32 = number
export type complex64 = number
export type complex128 = number

export type quaternion64 = number
export type quaternion128 = number
export type quaternion256 = number

export type rune = number

// export type string = never
export type cstring = number

// raw pointer type
export type rawptr = number

export interface OdinExports extends WebAssembly.Exports {
	memory: WebAssembly.Memory
	_start: () => void
	_end: () => void
	default_context_ptr: () => number
}

/** The Odin WebAssembly instance. */
export interface WasmState {
	exports: OdinExports
	memory: WebAssembly.Memory
}
