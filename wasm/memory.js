/** @typedef {boolean} bool */
/** @typedef {boolean} b8 */
/** @typedef {boolean} b16 */
/** @typedef {boolean} b32 */
/** @typedef {boolean} b64 */

/** @typedef {number} int */
/** @typedef {number} i8 */
/** @typedef {number} i16 */
/** @typedef {number} i32 */
/** @typedef {number} i64 */
/** @typedef {number} i128 */
/** @typedef {number} uint */
/** @typedef {number} u8 */
/** @typedef {number} u16 */
/** @typedef {number} u32 */
/** @typedef {number} u64 */
/** @typedef {number} u128 */
/** @typedef {number} uintptr */

/** @typedef {number} i16le */
/** @typedef {number} i32le */
/** @typedef {number} i64le */
/** @typedef {number} i128le */
/** @typedef {number} u16le */
/** @typedef {number} u32le */
/** @typedef {number} u64le */
/** @typedef {number} u128le */
/** @typedef {number} i16be */
/** @typedef {number} i32be */
/** @typedef {number} i64be */
/** @typedef {number} i128be */
/** @typedef {number} u16be */
/** @typedef {number} u32be */
/** @typedef {number} u64be */
/** @typedef {number} u128be */

/** @typedef {number} f16 */
/** @typedef {number} f32 */
/** @typedef {number} f64 */

/** @typedef {number} f16le */
/** @typedef {number} f32le */
/** @typedef {number} f64le */
/** @typedef {number} f16be */
/** @typedef {number} f32be */
/** @typedef {number} f64be */

/** @typedef {number} byte */
/** @typedef {number} rune */
/** @typedef {number} cstring */
/** @typedef {number} rawptr */

/** @typedef {Uint8Array} u8array */
/** @typedef {Uint8Array} bytes */

export const u8array = Uint8Array

/** Register size in bytes. */
export const REG_SIZE = 4 // 32-bit
/** Max memory alignment in bytes. */
export const ALIGNMENT = 8 // 64-bit

export const LITTLE_ENDIAN = /*#__PURE__*/ (() => {
	const buffer = new ArrayBuffer(2)
	new DataView(buffer).setInt16(0, 256, true)
	// Int16Array uses the platform's endianness
	return new Int16Array(buffer)[0] === 256
})()

export const STRING_SIZE = 2 * REG_SIZE

export class Cursor {
	offset    = 0
	alignment = ALIGNMENT

	/**
	@param {DataView} data
	*/
	constructor (data) {
		this.data = data
	}
}

/**
@param   {DataView} data
@param   {number}   offset
@param   {number}   alignment
@returns {Cursor} */
export function make_cursor(data, offset = 0, alignment = ALIGNMENT) {
	return {data, offset, alignment}
}

/**
@param   {u8array} data
@param   {number}  offset
@param   {number}  alignment
@returns {Cursor} */
export function make_cursor_from_bytes(data, offset = 0, alignment = ALIGNMENT) {
	return {data: new DataView(data.buffer, data.byteOffset, data.byteLength), offset, alignment}
}
export const cursor_from_bytes = make_cursor_from_bytes

/**
 * Move the offset by the given amount.
 *
 * @param   {Cursor} offset
 * @param   {number} amount      The amount of bytes to move by
 * @param   {number} [alignment] 1 for no-alignment
 * @returns {number}             The previous offset
 */
export function off(offset, amount, alignment = Math.min(amount, offset.alignment)) {
	if (offset.offset % alignment != 0) {
		offset.offset += alignment - (offset.offset % alignment)
	}
	let prev = offset.offset
	offset.offset += amount
	return prev
}

/**
@param   {Cursor} cursor 
@returns {bool}   */
export function cursor_eof(cursor) {
	return cursor.offset >= cursor.data.byteLength
}

/**
Progress the offset by length and return the slice.
@param   {Cursor} cursor 
@param   {number} length 
@returns {ArrayBuffer | SharedArrayBuffer}  */
export function cursor_slice(cursor, length) {
	let slice = cursor.data.buffer.slice(cursor.offset, cursor.offset+length)
	off(cursor, length)
	return slice
}

/**
@param {Cursor} cursor 
@param {bytes}  bytes
*/
export function cursor_write_bytes(cursor, bytes) {
	let view = new Uint8Array(cursor.data.buffer, cursor.data.byteOffset+cursor.offset, bytes.byteLength)
	view.set(bytes)
	off(cursor, bytes.byteLength)
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {boolean}
 */
export const load_b8 = (mem, addr) => {
	return mem.getUint8(addr) !== 0
}
export const load_b16 = load_b8
export const load_b32 = load_b8
export const load_b64 = load_b8
export const load_bool = load_b8

/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {boolean}
 */
export const cursor_load_b8 = (mem, offset) => {
	return load_b8(mem, off(offset, 1))
}
export const cursor_load_bool = cursor_load_b8
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {boolean}
 */
export const cursor_load_b16 = (mem, offset) => {
	return load_b16(mem, off(offset, 2))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {boolean}
 */
export const cursor_load_b32 = (mem, offset) => {
	return load_b32(mem, off(offset, 4))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {boolean}
 */
export const cursor_load_b64 = (mem, offset) => {
	return load_b64(mem, off(offset, 8))
}

/** @returns {void} */
export const store_bool = (
	/** @type {DataView} */ mem,
	/** @type {number} */ ptr,
	/** @type {boolean} */ value,
) => {
	mem.setUint8(ptr, /** @type {any} */ (value))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {boolean}    value
 * @returns {void}
 */
export const cursor_store_bool = (mem, offset, value) => {
	mem.setUint8(off(offset, 1), /** @type {any} */ (value))
}
export const store_b8 = store_bool
export const cursor_store_b8 = cursor_store_bool
export const store_b16 = store_bool
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {boolean}    value
 * @returns {void}
 */
export const cursor_store_b16 = (mem, offset, value) => {
	mem.setUint8(off(offset, 2), /** @type {any} */ (value))
}
export const store_b32 = store_bool
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {boolean}    value
 * @returns {void}
 */
export const cursor_store_b32 = (mem, offset, value) => {
	mem.setUint8(off(offset, 4), /** @type {any} */ (value))
}
export const store_b64 = store_bool
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {boolean}    value
 * @returns {void}
 */
export const cursor_store_b64 = (mem, offset, value) => {
	mem.setUint8(off(offset, 8), /** @type {any} */ (value))
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_u8 = (mem, addr) => {
	return mem.getUint8(addr)
}
export const load_byte = load_u8
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_i8 = (mem, addr) => {
	return mem.getInt8(addr)
}

/**
 * @param   {Cursor} cursor
 * @returns {number}
 */
export const cursor_load_u8 = (cursor) => {
	return load_u8(cursor.data, off(cursor, 1))
}
export const cursor_load_byte = cursor_load_u8
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_i8 = (mem, offset) => {
	return load_i8(mem, off(offset, 1))
}

/** @returns {void} */
export const store_u8 = (
	/** @type {DataView} */ mem,
	/** @type {number} */ ptr,
	/** @type {number} */ value,
) => {
	mem.setUint8(ptr, value)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_u8 = (mem, offset, value) => {
	mem.setUint8(off(offset, 1), value)
}
export const store_byte = store_u8
export const cursor_store_byte = cursor_store_u8
/** @returns {void} */
export const store_i8 = (
	/** @type {DataView} */ mem,
	/** @type {number} */ ptr,
	/** @type {number} */ value,
) => {
	mem.setInt8(ptr, value)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_i8 = (mem, offset, value) => {
	mem.setInt8(off(offset, 1), value)
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_u16 = (mem, addr, le = LITTLE_ENDIAN) => {
	return mem.getUint16(addr, le)
}
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_i16 = (mem, addr, le = LITTLE_ENDIAN) => {
	return mem.getInt16(addr, le)
}
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_u16le = (mem, addr) => {
	return mem.getUint16(addr, true)
}
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_i16le = (mem, addr) => {
	return mem.getInt16(addr, true)
}
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_u16be = (mem, addr) => {
	return mem.getUint16(addr, false)
}
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_i16be = (mem, addr) => {
	return mem.getInt16(addr, false)
}

/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_u16 = (mem, offset) => {
	return load_u16(mem, off(offset, 2))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_i16 = (mem, offset) => {
	return load_i16(mem, off(offset, 2))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_u16le = (mem, offset) => {
	return load_u16le(mem, off(offset, 2))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_i16le = (mem, offset) => {
	return load_i16le(mem, off(offset, 2))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_u16be = (mem, offset) => {
	return load_u16be(mem, off(offset, 2))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_i16be = (mem, offset) => {
	return load_i16be(mem, off(offset, 2))
}

/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {number}   value
 * @returns {void}
 */
export const store_u16 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setUint16(ptr, value, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_u16 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	mem.setUint16(off(offset, 2), value, le)
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {number}   value
 * @returns {void}
 */
export const store_i16 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setInt16(ptr, value, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_i16 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	mem.setInt16(off(offset, 2), value, le)
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_u32 = (mem, addr, le = LITTLE_ENDIAN) => {
	return mem.getUint32(addr, le)
}
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_i32 = (mem, addr, le = LITTLE_ENDIAN) => {
	return mem.getInt32(addr, le)
}

/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_u32 = (mem, offset) => {
	return load_u32(mem, off(offset, 4))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_i32 = (mem, offset) => {
	return load_i32(mem, off(offset, 4))
}

/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {number}   value
 * @returns {void}
 */
export const store_u32 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setUint32(ptr, value, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_u32 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	mem.setUint32(off(offset, 4), value, le)
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {number}   value
 * @returns {void}
 */
export const store_i32 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setInt32(ptr, value, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_i32 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	mem.setInt32(off(offset, 4), value, le)
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_uint = (mem, addr) => {
	return mem.getUint32(addr, LITTLE_ENDIAN)
}
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_int = (mem, addr) => {
	return mem.getInt32(addr, LITTLE_ENDIAN)
}
export const load_ptr = load_uint

/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_uint = (mem, offset) => {
	return load_uint(mem, off(offset, 4))
}
export const cursor_load_ptr = cursor_load_uint
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_int = (mem, offset) => {
	return load_int(mem, off(offset, 4))
}

/** @returns {void} */
export const store_uint = (
	/** @type {DataView} */ mem,
	/** @type {number} */ ptr,
	/** @type {number} */ value,
) => {
	mem.setUint32(ptr, value, LITTLE_ENDIAN)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_uint = (mem, offset, value) => {
	mem.setUint32(off(offset, 4), value, LITTLE_ENDIAN)
}
export const store_ptr = store_uint
export const cursor_store_ptr = cursor_store_uint
/** @returns {void} */
export const store_int = (
	/** @type {DataView} */ mem,
	/** @type {number} */ ptr,
	/** @type {number} */ value,
) => {
	mem.setInt32(ptr, value, LITTLE_ENDIAN)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_int = (mem, offset, value) => {
	mem.setInt32(off(offset, 4), value, LITTLE_ENDIAN)
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {bigint}
 */
export const load_u64 = (mem, addr, le = LITTLE_ENDIAN) => {
	return mem.getBigUint64(addr, le)
}
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {bigint}
 */
export const load_i64 = (mem, addr, le = LITTLE_ENDIAN) => {
	return mem.getBigInt64(addr, le)
}

/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {bigint}
 */
export const cursor_load_u64 = (mem, offset) => {
	return load_u64(mem, off(offset, 8))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {bigint}
 */
export const cursor_load_i64 = (mem, offset) => {
	return load_i64(mem, off(offset, 8))
}

/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {bigint}   value
 * @returns {void}
 */
export const store_u64 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setBigUint64(ptr, value, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {bigint}     value
 * @returns {void}
 */
export const cursor_store_u64 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	mem.setBigUint64(off(offset, 8), value, le)
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {bigint}   value
 * @returns {void}
 */
export const store_i64 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setBigInt64(ptr, value, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {bigint}     value
 * @returns {void}
 */
export const cursor_store_i64 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	mem.setBigInt64(off(offset, 8), value, le)
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_u64_number = (mem, addr, le = LITTLE_ENDIAN) => {
	const lo = mem.getUint32(addr + 4 * /** @type {any} */ (!le), le)
	const hi = mem.getUint32(addr + 4 * /** @type {any} */ (le), le)
	return lo + hi * 4294967296
}
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_i64_number = (mem, addr, le = LITTLE_ENDIAN) => {
	const lo = mem.getUint32(addr + 4 * /** @type {any} */ (!le), le)
	const hi = mem.getInt32(addr + 4 * /** @type {any} */ (le), le)
	return lo + hi * 4294967296
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {number}   value
 * @returns {void}
 */
export const store_u64_number = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setUint32(ptr + 4 * /** @type {any} */ (!le), value, le)
	mem.setUint32(ptr + 4 * /** @type {any} */ (le), value / 4294967296, le)
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {number}   value
 * @returns {void}
 */
export const store_i64_number = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setUint32(ptr + 4 * /** @type {any} */ (!le), value, le)
	mem.setInt32(ptr + 4 * /** @type {any} */ (le), Math.floor(value / 4294967296), le)
}

/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_u64_number = (mem, offset) => {
	return load_u64_number(mem, off(offset, 8))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_i64_number = (mem, offset) => {
	return load_i64_number(mem, off(offset, 8))
}

/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_u64_number = (mem, offset, value, le = LITTLE_ENDIAN) => {
	store_u64_number(mem, off(offset, 8), value, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_i64_number = (mem, offset, value, le = LITTLE_ENDIAN) => {
	store_i64_number(mem, off(offset, 8), value, le)
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {bigint}
 */
export const load_u128 = (mem, addr, le = LITTLE_ENDIAN) => {
	const lo = mem.getBigUint64(addr + 8 * /** @type {any} */ (!le), le)
	const hi = mem.getBigUint64(addr + 8 * /** @type {any} */ (le), le)
	return lo + (hi << 64n)
}
/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {bigint}
 */
export const load_i128 = (mem, addr, le = LITTLE_ENDIAN) => {
	const lo = mem.getBigUint64(addr + 8 * /** @type {any} */ (!le), le)
	const hi = mem.getBigInt64(addr + 8 * /** @type {any} */ (le), le)
	return lo + (hi << 64n)
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {bigint}   value
 * @returns {void}
 */
export const store_u128 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setBigUint64(ptr + 8 * /** @type {any} */ (!le), value & 0xffffffffffffffffn, le)
	mem.setBigUint64(ptr + 8 * /** @type {any} */ (le), value >> 64n, le)
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {bigint}   value
 * @returns {void}
 */
export const store_i128 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setBigUint64(ptr + 8 * /** @type {any} */ (!le), value & 0xffffffffffffffffn, le)
	mem.setBigInt64(ptr + 8 * /** @type {any} */ (le), value >> 64n, le)
}

/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {bigint}
 */
export const cursor_load_u128 = (mem, offset) => {
	return load_u128(mem, off(offset, 16))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {bigint}
 */
export const cursor_load_i128 = (mem, offset) => {
	return load_i128(mem, off(offset, 16))
}

/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {bigint}     value
 * @returns {void}
 */
export const cursor_store_u128 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	store_u128(mem, off(offset, 16), value, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {bigint}     value
 * @returns {void}
 */
export const cursor_store_i128 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	store_i128(mem, off(offset, 16), value, le)
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_f16 = (mem, addr, le = LITTLE_ENDIAN) => {
	const lo = mem.getUint8(addr + /** @type {any} */ (le)),
		hi = mem.getUint8(addr + /** @type {any} */ (!le)),
		sign = lo >> 7,
		exp = (lo & 0b01111100) >> 2,
		mant = ((lo & 0b00000011) << 8) | hi

	switch (exp) {
		case 0b11111:
			return mant ? NaN : sign ? -Infinity : Infinity
		case 0:
			return Math.pow(-1, sign) * Math.pow(2, -14) * (mant / 1024)
		default:
			return Math.pow(-1, sign) * Math.pow(2, exp - 15) * (1 + mant / 1024)
	}
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_f16 = (mem, offset) => {
	return load_f16(mem, off(offset, 2))
}

/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {number}   value
 * @returns {void}
 */
export const store_f16 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	let biased_exponent = 0,
		mantissa = 0,
		sign = 0

	if (isNaN(value)) {
		biased_exponent = 31
		mantissa = 1
	} else if (value === Infinity) {
		biased_exponent = 31
	} else if (value === -Infinity) {
		biased_exponent = 31
		sign = 1
	} else if (value === 0) {
		biased_exponent = 0
		mantissa = 0
	} else {
		if (value < 0) {
			sign = 1
			value = -value
		}
		const exponent = Math.min(Math.floor(Math.log2(value)), 15)
		biased_exponent = exponent + 15
		mantissa = Math.round((value / Math.pow(2, exponent) - 1) * 1024)
	}

	const lo = (sign << 7) | (biased_exponent << 2) | (mantissa >> 8)
	const hi = mantissa & 0xff

	mem.setUint8(ptr + 1 * /** @type {any} */ (le), lo)
	mem.setUint8(ptr + 1 * /** @type {any} */ (!le), hi)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_f16 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	store_f16(mem, off(offset, 2), value, le)
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_f32 = (mem, addr, le = LITTLE_ENDIAN) => {
	return mem.getFloat32(addr, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_f32 = (mem, offset) => {
	return load_f32(mem, off(offset, 4))
}

/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {number}   value
 * @returns {void}
 */
export const store_f32 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setFloat32(ptr, value, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_f32 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	mem.setFloat32(off(offset, 4), value, le)
}

/**
 * @param   {DataView} mem
 * @param   {number}   addr
 * @returns {number}
 */
export const load_f64 = (mem, addr, le = LITTLE_ENDIAN) => {
	return mem.getFloat64(addr, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {number}
 */
export const cursor_load_f64 = (mem, offset) => {
	return load_f64(mem, off(offset, 8))
}

/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @param   {number}   value
 * @returns {void}
 */
export const store_f64 = (mem, ptr, value, le = LITTLE_ENDIAN) => {
	mem.setFloat64(ptr, value, le)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {number}     value
 * @returns {void}
 */
export const cursor_store_f64 = (mem, offset, value, le = LITTLE_ENDIAN) => {
	mem.setFloat64(off(offset, 8), value, le)
}

/**
 * @template T
 * @param   {DataView}                                  mem
 * @param   {number}                                    slice_ptr
 * @param   {(mem: DataView, offset: Cursor) => T} mapFn
 * @returns {T[]}
 */
export const load_slice = (mem, slice_ptr, mapFn) => {
	let raw_data_ptr = load_ptr(mem, slice_ptr)
	let raw_data_len = load_int(mem, slice_ptr+REG_SIZE)

	let cursor = make_cursor(mem, raw_data_ptr)

	let items = new Array(raw_data_len)
	for (let i = 0; i < raw_data_len; i++) {
		items[i] = mapFn(mem, cursor)
	}

	return items
}
/**
 * @template T
 * @param   {DataView}                                 mem
 * @param   {Cursor}                               offset
 * @param   {(mem: DataView, offset: Cursor) => T} mapFn
 * @returns {T[]}
 */
export const cursor_load_slice = (mem, offset, mapFn) => {
	return load_slice(mem, off(offset, REG_SIZE + REG_SIZE), mapFn)
}

/**
 * @param   {ArrayBufferLike} buffer
 * @param   {number}          ptr
 * @param   {number}          len
 * @returns {Uint8Array}
 */
export const load_bytes = (buffer, ptr, len) => {
	return new Uint8Array(buffer, ptr, len)
}

/**
@param   {ArrayBufferLike} buffer
@param   {number}          dst_ptr
@param   {Uint8Array}      src
@returns {void}            */
export const store_bytes = (buffer, dst_ptr, src) => {
	const dst = new Uint8Array(buffer, dst_ptr, src.length)
	dst.set(src)
}

/**
 * @param   {ArrayBufferLike} buffer
 * @param   {number}          ptr
 * @param   {number}          len
 * @returns {string}
 */
export const load_string_bytes = (buffer, ptr, len) => {
	const bytes = new Uint8Array(buffer, ptr, len)
	return String.fromCharCode(...bytes)
}
/**
 * @param   {ArrayBufferLike} buffer
 * @param   {number}          ptr
 * @param   {number}          len
 * @returns {string}
 */
export const load_string_raw = (buffer, ptr, len) => {
	const bytes = new Uint8Array(buffer, ptr, len)
	return new TextDecoder().decode(bytes)
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @returns {string}
 */
export const load_string = (mem, ptr) => {
	const len = load_u32(mem, ptr + REG_SIZE)
	ptr = load_ptr(mem, ptr)
	return load_string_raw(mem.buffer, ptr, len)
}
/** @returns {string[]} */
export const load_strings = (
	/** @type {DataView} */ mem,
	/** @type {Number} */ strings_ptr,
	/** @type {number} */ strings_len,
) => {
	const strings = new Array(strings_len)
	for (let i = 0; i < strings_len; i++) {
		strings[i] = load_string(mem, strings_ptr + i * STRING_SIZE)
	}
	return strings
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @returns {string}
 */
export const load_cstring_raw = (mem, ptr) => {
	let str = "",
		c
	while ((c = mem.getUint8(ptr))) {
		str += String.fromCharCode(c)
		ptr++
	}
	return str
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @returns {string}
 */
export const load_cstring = (mem, ptr) => {
	ptr = load_ptr(mem, ptr)
	return load_cstring_raw(mem, ptr)
}
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @returns {string}
 */
export const load_rune = (mem, ptr) => {
	const code = load_u32(mem, ptr)
	return String.fromCharCode(code)
}

/*
    lbp slice length will be always 64-bit (for consistency)
*/
/**
 * @param   {DataView} mem
 * @param   {number}   ptr
 * @returns {string}
 */
export const load_string_lbp = (mem, ptr) => {
	const len = load_u64_number(mem, ptr)
	return load_string_raw(mem.buffer, ptr, len)
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {string}
 */
export const cursor_load_string_lbp = (mem, offset) => {
	console.assert(offset.alignment === 1, "Alignment must be 1 for LBP strings")
	const len = load_u64_number(mem, off(offset, 8))
	return load_string_raw(mem.buffer, off(offset, len), len)
}

/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {string}
 */
export const cursor_load_string = (mem, offset) => {
	return load_string(mem, off(offset, 8))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {string}
 */
export const cursor_load_cstring = (mem, offset) => {
	return load_cstring(mem, off(offset, 4))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @returns {string}
 */
export const cursor_load_rune = (mem, offset) => {
	return load_rune(mem, off(offset, 4))
}

/**
 * @param   {ArrayBufferLike} buffer
 * @param   {number}          addr
 * @param   {number}          length
 * @param   {string}          value
 * @returns {number}
 */
export const store_string_bytes = (buffer, addr, length, value) => {
	length = Math.min(length, value.length)
	const bytes = new Uint8Array(buffer, addr, length)
	for (let i = 0; i < value.length; i++) {
		bytes[i] = value.charCodeAt(i)
	}
	return length
}
/** @returns {number} */
export const store_string_raw = (
	/** @type {ArrayBufferLike} */ buffer,
	/** @type {number} */ addr,
	/** @type {number} */ length,
	/** @type {string} */ value,
) => {
	const bytes = load_bytes(buffer, addr, length)
	const res = new TextEncoder().encodeInto(value, bytes)
	return res.written
}
/** @returns {void} */
export const store_cstring_raw = (
	/** @type {DataView} */ mem,
	/** @type {number} */ ptr,
	/** @type {string} */ value,
) => {
	void store_string_raw(mem.buffer, ptr, value.length, value)
	mem.setUint8(ptr + value.length, 0)
}
/** @returns {void} */
export const store_rune = (
	/** @type {DataView} */ mem,
	/** @type {number} */ ptr,
	/** @type {string} */ value,
) => {
	store_u32(mem, ptr, value.charCodeAt(0))
}
/**
 * @param   {DataView}   mem
 * @param   {Cursor} offset
 * @param   {string}     value
 * @returns {void}
 */
export const cursor_store_rune = (mem, offset, value) => {
	store_rune(mem, off(offset, 4), value)
}

/*
Not sure how to implement storing multi pointers (strings, cstrings, slices, etc.)
as they just point to some memory of unknown size
and js doesn't know where it can allocate it

That memory has to be allocated on the WASM side
and then [ptr:len] to it can be returned to js
*/

// /** @returns {void} */
// export const store_string = (
// 	/** @type {DataView} */ mem,
// 	/** @type {number} */ ptr,
// 	/** @type {string} */ value,
// ) => {
// 	warn("store_string not implemented")
// 	store_u32(mem, ptr, 0)
// 	store_u32(mem, ptr + 4, 0)
// }
// /**
//  * @param   {DataView}   mem
//  * @param   {Byte_Cursor} offset
//  * @param   {string}     value
//  * @returns {void}
//  */
// export const cursor_store_string = (mem, offset, value) => {
// 	store_string(mem, off(offset, 8), value)
// }
// /** @returns {void} */
// export const store_cstring = (
// 	/** @type {DataView} */ mem,
// 	/** @type {number} */ ptr,
// 	/** @type {string} */ value,
// ) => {
// 	warn("store_cstring not implemented")
// 	store_u32(mem, ptr, 0)
// }
// /**
//  * @param   {DataView}   mem
//  * @param   {Byte_Cursor} offset
//  * @param   {string}     value
//  * @returns {void}
//  */
// export const cursor_store_cstring = (mem, offset, value) => {
// 	store_cstring(mem, off(offset, 4), value)
// }

/**
 * @param   {ArrayBufferLike} buffer
 * @param   {number}          addr
 * @param   {number}          len
 * @returns {Float32Array}
 */
export const load_f32_array = (buffer, addr, len) => {
	return new Float32Array(buffer, addr, len)
}
/**
 * @param   {ArrayBufferLike} buffer
 * @param   {number}          addr
 * @param   {number}          len
 * @returns {Float64Array}
 */
export const load_f64_array = (buffer, addr, len) => {
	return new Float64Array(buffer, addr, len)
}
/**
 * @param   {ArrayBufferLike} buffer
 * @param   {number}          addr
 * @param   {number}          len
 * @returns {Uint32Array}
 */
export const load_u32_array = (buffer, addr, len) => {
	return new Uint32Array(buffer, addr, len)
}
/**
 * @param   {ArrayBufferLike} buffer
 * @param   {number}          addr
 * @param   {number}          len
 * @returns {Int32Array}
 */
export const load_i32_array = (buffer, addr, len) => {
	return new Int32Array(buffer, addr, len)
}

/**
@param   {u8array} bytes
@param   {rawptr}  [addr]
@param   {bool}    [le]
@returns {u32} */
export function bytes_to_u32(bytes, addr = 0, le = LITTLE_ENDIAN) {
	return load_u32(new DataView(bytes.buffer, bytes.byteOffset, bytes.length), addr, le)
}
/**
@param   {u8array} bytes
@param   {rawptr}  [addr]
@returns {u32} */
export function bytes_to_u32le(bytes, addr = 0) {
	return load_u32(new DataView(bytes.buffer, bytes.byteOffset, bytes.length), addr, true)
}
/**
@param   {u8array} bytes
@param   {rawptr}  [addr]
@returns {u32} */
export function bytes_to_u32be(bytes, addr = 0) {
	return load_u32(new DataView(bytes.buffer, bytes.byteOffset, bytes.length), addr, false)
}



/**
@param   {string} str
@returns {u8array} */
export function string_to_bytes(str) {
	return new TextEncoder().encode(str)
}
export const bytes_from_string = string_to_bytes

/**
@param   {AllowSharedBufferSource} buf
@returns {string} */
export function bytes_to_string(buf) {
	return new TextDecoder().decode(buf)
}
export const string_from_bytes = bytes_to_string

/**
@param   {u8array} a
@param   {u8array} b
@returns {u8array} */
export function concat_bytes_ab(a, b) {
	let c = new Uint8Array(a.length + b.length)
	c.set(a, 0)
	c.set(b, a.length)
	return c
}

/**
@param   {u8array[]} arrays
@param   {number} size
@returns {u8array} */
export function concat_bytes(arrays, size) {
	let result = new Uint8Array(size)
	let next_idx = 0
	for (let buffer of arrays) {
		result.set(buffer, next_idx)
		next_idx += buffer.byteLength
	}
	return result
}

/**
@param   {Iterable<u8array>} iterable
@returns {u8array} */
export function collect_bytes(iterable) {
	let size = 0
	let buffers = []
	for (let value of iterable) {
		buffers.push(value)
		size += value.byteLength
	}
	return concat_bytes(buffers, size)
}

/**
@param   {ArrayBufferLike[]} buffers 
@returns {number} */
export function buffers_length(buffers) {
	let len = 0
	for (let buf of buffers) {
		len += buf.byteLength
	}
	return len
}
