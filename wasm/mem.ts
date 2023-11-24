import {assert, warn} from './env.js'

/**
 * Register size in bytes.
 */
export const REG_SIZE = 4 // 32-bit
/**
 * Max memory alignment in bytes.
 */
export const ALIGNMENT = 8 // 64-bit

export const LITTLE_ENDIAN = /*#__PURE__*/ ((): boolean => {
    const buffer = new ArrayBuffer(2)
    new DataView(buffer).setInt16(0, 256, true)
    // Int16Array uses the platform's endianness
    return new Int16Array(buffer)[0] === 256
})()

export class ByteOffset {
    /**
     * @param offset Initial offset
     * @param alignment Defaults to the minimum of the amount and the register size. Will be rounded up to the nearest multiple of the alignment.
     */
    constructor(
        public offset = 0,
        public alignment = ALIGNMENT,
    ) {}

    /**
     * Move the offset by the given amount.
     *
     * @param amount The amount of bytes to move by
     * @returns The previous offset
     */
    off(amount: number): number {
        const alignment = Math.min(amount, this.alignment)
        if (this.offset % alignment != 0) {
            this.offset += alignment - (this.offset % alignment)
        }
        const x = this.offset
        this.offset += amount
        return x
    }
}

export const load_b8 = (mem: DataView, addr: number): boolean => {
    return mem.getUint8(addr) !== 0
}
export const load_b16 = load_b8
export const load_b32 = load_b8
export const load_b64 = load_b8
export const load_bool = load_b8

export const load_offset_b8 = (mem: DataView, offset: ByteOffset): boolean => {
    return load_b8(mem, offset.off(1))
}
export const load_offset_bool = load_offset_b8
export const load_offset_b16 = (mem: DataView, offset: ByteOffset): boolean => {
    return load_b16(mem, offset.off(2))
}
export const load_offset_b32 = (mem: DataView, offset: ByteOffset): boolean => {
    return load_b32(mem, offset.off(4))
}
export const load_offset_b64 = (mem: DataView, offset: ByteOffset): boolean => {
    return load_b64(mem, offset.off(8))
}

export const store_bool = (mem: DataView, ptr: number, value: boolean): void => {
    mem.setUint8(ptr, value as any)
}
export const store_offset_bool = (mem: DataView, offset: ByteOffset, value: boolean): void => {
    mem.setUint8(offset.off(1), value as any)
}
export const store_b8 = store_bool
export const store_offset_b8 = store_offset_bool
export const store_b16 = store_bool
export const store_offset_b16 = (mem: DataView, offset: ByteOffset, value: boolean): void => {
    mem.setUint8(offset.off(2), value as any)
}
export const store_b32 = store_bool
export const store_offset_b32 = (mem: DataView, offset: ByteOffset, value: boolean): void => {
    mem.setUint8(offset.off(4), value as any)
}
export const store_b64 = store_bool
export const store_offset_b64 = (mem: DataView, offset: ByteOffset, value: boolean): void => {
    mem.setUint8(offset.off(8), value as any)
}

export const load_u8 = (mem: DataView, addr: number): number => {
    return mem.getUint8(addr)
}
export const load_byte = load_u8
export const load_i8 = (mem: DataView, addr: number): number => {
    return mem.getInt8(addr)
}

export const load_offset_u8 = (mem: DataView, offset: ByteOffset): number => {
    return load_u8(mem, offset.off(1))
}
export const load_offset_byte = load_offset_u8
export const load_offset_i8 = (mem: DataView, offset: ByteOffset): number => {
    return load_i8(mem, offset.off(1))
}

export const store_u8 = (mem: DataView, ptr: number, value: number): void => {
    mem.setUint8(ptr, value)
}
export const store_offset_u8 = (mem: DataView, offset: ByteOffset, value: number): void => {
    mem.setUint8(offset.off(1), value)
}
export const store_byte = store_u8
export const store_offset_byte = store_offset_u8
export const store_i8 = (mem: DataView, ptr: number, value: number): void => {
    mem.setInt8(ptr, value)
}
export const store_offset_i8 = (mem: DataView, offset: ByteOffset, value: number): void => {
    mem.setInt8(offset.off(1), value)
}

export const load_u16 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): number => {
    return mem.getUint16(addr, le)
}
export const load_i16 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): number => {
    return mem.getInt16(addr, le)
}
export const load_u16le = (mem: DataView, addr: number): number => {
    return mem.getUint16(addr, true)
}
export const load_i16le = (mem: DataView, addr: number): number => {
    return mem.getInt16(addr, true)
}
export const load_u16be = (mem: DataView, addr: number): number => {
    return mem.getUint16(addr, false)
}
export const load_i16be = (mem: DataView, addr: number): number => {
    return mem.getInt16(addr, false)
}

export const load_offset_u16 = (mem: DataView, offset: ByteOffset): number => {
    return load_u16(mem, offset.off(2))
}
export const load_offset_i16 = (mem: DataView, offset: ByteOffset): number => {
    return load_i16(mem, offset.off(2))
}
export const load_offset_u16le = (mem: DataView, offset: ByteOffset): number => {
    return load_u16le(mem, offset.off(2))
}
export const load_offset_i16le = (mem: DataView, offset: ByteOffset): number => {
    return load_i16le(mem, offset.off(2))
}
export const load_offset_u16be = (mem: DataView, offset: ByteOffset): number => {
    return load_u16be(mem, offset.off(2))
}
export const load_offset_i16be = (mem: DataView, offset: ByteOffset): number => {
    return load_i16be(mem, offset.off(2))
}

export const store_u16 = (mem: DataView, ptr: number, value: number, le = LITTLE_ENDIAN): void => {
    mem.setUint16(ptr, value, le)
}
export const store_offset_u16 = (
    mem: DataView,
    offset: ByteOffset,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    mem.setUint16(offset.off(2), value, le)
}
export const store_i16 = (mem: DataView, ptr: number, value: number, le = LITTLE_ENDIAN): void => {
    mem.setInt16(ptr, value, le)
}
export const store_offset_i16 = (
    mem: DataView,
    offset: ByteOffset,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    mem.setInt16(offset.off(2), value, le)
}

export const load_u32 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): number => {
    return mem.getUint32(addr, le)
}
export const load_i32 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): number => {
    return mem.getInt32(addr, le)
}

export const load_offset_u32 = (mem: DataView, offset: ByteOffset): number => {
    return load_u32(mem, offset.off(4))
}
export const load_offset_i32 = (mem: DataView, offset: ByteOffset): number => {
    return load_i32(mem, offset.off(4))
}

export const store_u32 = (mem: DataView, ptr: number, value: number, le = LITTLE_ENDIAN): void => {
    mem.setUint32(ptr, value, le)
}
export const store_offset_u32 = (
    mem: DataView,
    offset: ByteOffset,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    mem.setUint32(offset.off(4), value, le)
}
export const store_i32 = (mem: DataView, ptr: number, value: number, le = LITTLE_ENDIAN): void => {
    mem.setInt32(ptr, value, le)
}
export const store_offset_i32 = (
    mem: DataView,
    offset: ByteOffset,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    mem.setInt32(offset.off(4), value, le)
}

export const load_uint = (mem: DataView, addr: number): number => {
    return mem.getUint32(addr, LITTLE_ENDIAN)
}
export const load_int = (mem: DataView, addr: number): number => {
    return mem.getInt32(addr, LITTLE_ENDIAN)
}
export const load_ptr = load_uint

export const load_offset_uint = (mem: DataView, offset: ByteOffset): number => {
    return load_uint(mem, offset.off(4))
}
export const load_offset_ptr = load_offset_uint
export const load_offset_int = (mem: DataView, offset: ByteOffset): number => {
    return load_int(mem, offset.off(4))
}

export const store_uint = (mem: DataView, ptr: number, value: number): void => {
    mem.setUint32(ptr, value, LITTLE_ENDIAN)
}
export const store_offset_uint = (mem: DataView, offset: ByteOffset, value: number): void => {
    mem.setUint32(offset.off(4), value, LITTLE_ENDIAN)
}
export const store_ptr = store_uint
export const store_offset_ptr = store_offset_uint
export const store_int = (mem: DataView, ptr: number, value: number): void => {
    mem.setInt32(ptr, value, LITTLE_ENDIAN)
}
export const store_offset_int = (mem: DataView, offset: ByteOffset, value: number): void => {
    mem.setInt32(offset.off(4), value, LITTLE_ENDIAN)
}

export const load_u64 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): bigint => {
    return mem.getBigUint64(addr, le)
}
export const load_i64 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): bigint => {
    return mem.getBigInt64(addr, le)
}

export const load_offset_u64 = (mem: DataView, offset: ByteOffset): bigint => {
    return load_u64(mem, offset.off(8))
}
export const load_offset_i64 = (mem: DataView, offset: ByteOffset): bigint => {
    return load_i64(mem, offset.off(8))
}

export const store_u64 = (mem: DataView, ptr: number, value: bigint, le = LITTLE_ENDIAN): void => {
    mem.setBigUint64(ptr, value, le)
}
export const store_offset_u64 = (
    mem: DataView,
    offset: ByteOffset,
    value: bigint,
    le = LITTLE_ENDIAN,
): void => {
    mem.setBigUint64(offset.off(8), value, le)
}
export const store_i64 = (mem: DataView, ptr: number, value: bigint, le = LITTLE_ENDIAN): void => {
    mem.setBigInt64(ptr, value, le)
}
export const store_offset_i64 = (
    mem: DataView,
    offset: ByteOffset,
    value: bigint,
    le = LITTLE_ENDIAN,
): void => {
    mem.setBigInt64(offset.off(8), value, le)
}

export const load_u64_number = (mem: DataView, addr: number, le = LITTLE_ENDIAN): number => {
    const lo = mem.getUint32(addr + 4 * (!le as any), le)
    const hi = mem.getUint32(addr + 4 * (le as any), le)
    return lo + hi * 4294967296
}
export const load_i64_number = (mem: DataView, addr: number, le = LITTLE_ENDIAN): number => {
    const lo = mem.getUint32(addr + 4 * (!le as any), le)
    const hi = mem.getInt32(addr + 4 * (le as any), le)
    return lo + hi * 4294967296
}
export const store_u64_number = (
    mem: DataView,
    ptr: number,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    mem.setUint32(ptr + 4 * (!le as any), value, le)
    mem.setUint32(ptr + 4 * (le as any), value / 4294967296, le)
}
export const store_i64_number = (
    mem: DataView,
    ptr: number,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    mem.setUint32(ptr + 4 * (!le as any), value, le)
    mem.setInt32(ptr + 4 * (le as any), Math.floor(value / 4294967296), le)
}

export const load_offset_u64_number = (mem: DataView, offset: ByteOffset): number => {
    return load_u64_number(mem, offset.off(8))
}
export const load_offset_i64_number = (mem: DataView, offset: ByteOffset): number => {
    return load_i64_number(mem, offset.off(8))
}

export const store_offset_u64_number = (
    mem: DataView,
    offset: ByteOffset,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    store_u64_number(mem, offset.off(8), value, le)
}
export const store_offset_i64_number = (
    mem: DataView,
    offset: ByteOffset,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    store_i64_number(mem, offset.off(8), value, le)
}

export const load_u128 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): bigint => {
    const lo = mem.getBigUint64(addr + 8 * (!le as any), le)
    const hi = mem.getBigUint64(addr + 8 * (le as any), le)
    return lo + (hi << 64n)
}
export const load_i128 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): bigint => {
    const lo = mem.getBigUint64(addr + 8 * (!le as any), le)
    const hi = mem.getBigInt64(addr + 8 * (le as any), le)
    return lo + (hi << 64n)
}
export const store_u128 = (mem: DataView, ptr: number, value: bigint, le = LITTLE_ENDIAN): void => {
    mem.setBigUint64(ptr + 8 * (!le as any), value & 0xff_ff_ff_ff_ff_ff_ff_ffn, le)
    mem.setBigUint64(ptr + 8 * (le as any), value >> 64n, le)
}
export const store_i128 = (mem: DataView, ptr: number, value: bigint, le = LITTLE_ENDIAN): void => {
    mem.setBigUint64(ptr + 8 * (!le as any), value & 0xff_ff_ff_ff_ff_ff_ff_ffn, le)
    mem.setBigInt64(ptr + 8 * (le as any), value >> 64n, le)
}

export const load_offset_u128 = (mem: DataView, offset: ByteOffset): bigint => {
    return load_u128(mem, offset.off(16))
}
export const load_offset_i128 = (mem: DataView, offset: ByteOffset): bigint => {
    return load_i128(mem, offset.off(16))
}

export const store_offset_u128 = (
    mem: DataView,
    offset: ByteOffset,
    value: bigint,
    le = LITTLE_ENDIAN,
): void => {
    store_u128(mem, offset.off(16), value, le)
}
export const store_offset_i128 = (
    mem: DataView,
    offset: ByteOffset,
    value: bigint,
    le = LITTLE_ENDIAN,
): void => {
    store_i128(mem, offset.off(16), value, le)
}

export const load_f16 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): number => {
    const lo = mem.getUint8(addr + (le as any))
    const hi = mem.getUint8(addr + (!le as any))

    const sign = lo >> 7
    const exp = (lo & 0b01111100) >> 2
    const mant = ((lo & 0b00000011) << 8) | hi

    switch (exp) {
        case 0b11111:
            return mant ? NaN : sign ? -Infinity : Infinity
        case 0:
            return Math.pow(-1, sign) * Math.pow(2, -14) * (mant / 1024)
        default:
            return Math.pow(-1, sign) * Math.pow(2, exp - 15) * (1 + mant / 1024)
    }
}
export const load_offset_f16 = (mem: DataView, offset: ByteOffset): number => {
    return load_f16(mem, offset.off(2))
}

export const store_f16 = (mem: DataView, ptr: number, value: number, le = LITTLE_ENDIAN): void => {
    let biased_exponent = 0
    let mantissa = 0
    let sign = 0

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

    mem.setUint8(ptr + 1 * (le as any), lo)
    mem.setUint8(ptr + 1 * (!le as any), hi)
}
export const store_offset_f16 = (
    mem: DataView,
    offset: ByteOffset,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    store_f16(mem, offset.off(2), value, le)
}

export const load_f32 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): number => {
    return mem.getFloat32(addr, le)
}
export const load_offset_f32 = (mem: DataView, offset: ByteOffset): number => {
    return load_f32(mem, offset.off(4))
}

export const store_f32 = (mem: DataView, ptr: number, value: number, le = LITTLE_ENDIAN): void => {
    mem.setFloat32(ptr, value, le)
}
export const store_offset_f32 = (
    mem: DataView,
    offset: ByteOffset,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    mem.setFloat32(offset.off(4), value, le)
}

export const load_f64 = (mem: DataView, addr: number, le = LITTLE_ENDIAN): number => {
    return mem.getFloat64(addr, le)
}
export const load_offset_f64 = (mem: DataView, offset: ByteOffset): number => {
    return load_f64(mem, offset.off(8))
}

export const store_f64 = (mem: DataView, ptr: number, value: number, le = LITTLE_ENDIAN): void => {
    mem.setFloat64(ptr, value, le)
}
export const store_offset_f64 = (
    mem: DataView,
    offset: ByteOffset,
    value: number,
    le = LITTLE_ENDIAN,
): void => {
    mem.setFloat64(offset.off(8), value, le)
}

export const load_slice = <T>(
    mem: DataView,
    slice_ptr: number,
    mapFn: (mem: DataView, offset: ByteOffset) => T,
): T[] => {
    const raw_data_ptr = load_ptr(mem, slice_ptr)
    const raw_data_len = load_int(mem, slice_ptr + REG_SIZE)

    const offset = new ByteOffset(raw_data_ptr)
    const items: T[] = new Array(raw_data_len)
    for (let i = 0; i < raw_data_len; i++) {
        items[i] = mapFn(mem, offset)
    }

    return items
}
export const load_offset_slice = <T>(
    mem: DataView,
    offset: ByteOffset,
    mapFn: (mem: DataView, offset: ByteOffset) => T,
): T[] => {
    return load_slice(mem, offset.off(REG_SIZE + REG_SIZE), mapFn)
}

export const load_bytes = (buffer: ArrayBufferLike, ptr: number, len: number): Uint8Array => {
    return new Uint8Array(buffer, ptr, len)
}

export const load_string_bytes = (buffer: ArrayBufferLike, ptr: number, len: number): string => {
    const bytes = new Uint8Array(buffer, ptr, len)
    return String.fromCharCode(...bytes)
}
export const load_string_raw = (buffer: ArrayBufferLike, ptr: number, len: number): string => {
    const bytes = new Uint8Array(buffer, ptr, len)
    return new TextDecoder().decode(bytes)
}
export const load_string = (mem: DataView, ptr: number): string => {
    const len = load_u32(mem, ptr + REG_SIZE)
    ptr = load_ptr(mem, ptr)
    return load_string_raw(mem.buffer, ptr, len)
}
export const load_cstring_raw = (mem: DataView, ptr: number): string => {
    let str = '',
        c: number
    while ((c = mem.getUint8(ptr))) {
        str += String.fromCharCode(c)
        ptr++
    }
    return str
}
export const load_cstring = (mem: DataView, ptr: number): string => {
    ptr = load_ptr(mem, ptr)
    return load_cstring_raw(mem, ptr)
}
export const load_rune = (mem: DataView, ptr: number): string => {
    const code = load_u32(mem, ptr)
    return String.fromCharCode(code)
}

/*
    lbp slice length will be always 64-bit (for consistency)
*/
export const load_string_lbp = (mem: DataView, ptr: number): string => {
    const len = load_u64_number(mem, ptr)
    return load_string_raw(mem.buffer, ptr, len)
}
export const load_offset_string_lbp = (mem: DataView, offset: ByteOffset): string => {
    assert(offset.alignment === 1, 'Alignment must be 1 for LBP strings')
    const len = load_u64_number(mem, offset.off(8))
    return load_string_raw(mem.buffer, offset.off(len), len)
}

export const load_offset_string = (mem: DataView, offset: ByteOffset): string => {
    return load_string(mem, offset.off(8))
}
export const load_offset_cstring = (mem: DataView, offset: ByteOffset): string => {
    return load_cstring(mem, offset.off(4))
}
export const load_offset_rune = (mem: DataView, offset: ByteOffset): string => {
    return load_rune(mem, offset.off(4))
}

export const store_string_bytes = (
    buffer: ArrayBufferLike,
    addr: number,
    length: number,
    value: string,
): number => {
    length = Math.min(length, value.length)
    const bytes = new Uint8Array(buffer, addr, length)
    for (let i = 0; i < value.length; i++) {
        bytes[i] = value.charCodeAt(i)
    }
    return length
}
export const store_string_raw = (
    buffer: ArrayBufferLike,
    addr: number,
    length: number,
    value: string,
): number => {
    length = Math.min(length, value.length)
    const bytes = load_bytes(buffer, addr, length)
    void new TextEncoder().encodeInto(value, bytes)
    return length
}
export const store_string = (mem: DataView, ptr: number, value: string): void => {
    warn('store_string not implemented')
    store_u32(mem, ptr, 0)
    store_u32(mem, ptr + 4, 0)
}
export const store_offset_string = (mem: DataView, offset: ByteOffset, value: string): void => {
    store_string(mem, offset.off(8), value)
}
export const store_cstring_raw = (mem: DataView, ptr: number, value: string): void => {
    void store_string_raw(mem.buffer, ptr, value.length, value)
    mem.setUint8(ptr + value.length, 0)
}
export const store_cstring = (mem: DataView, ptr: number, value: string): void => {
    warn('store_cstring not implemented')
    store_u32(mem, ptr, 0)
}
export const store_offset_cstring = (mem: DataView, offset: ByteOffset, value: string): void => {
    store_cstring(mem, offset.off(4), value)
}
export const store_rune = (mem: DataView, ptr: number, value: string): void => {
    store_u32(mem, ptr, value.charCodeAt(0))
}
export const store_offset_rune = (mem: DataView, offset: ByteOffset, value: string): void => {
    store_rune(mem, offset.off(4), value)
}

export const load_f32_array = (
    buffer: ArrayBufferLike,
    addr: number,
    len: number,
): Float32Array => {
    return new Float32Array(buffer, addr, len)
}
export const load_f64_array = (
    buffer: ArrayBufferLike,
    addr: number,
    len: number,
): Float64Array => {
    return new Float64Array(buffer, addr, len)
}
export const load_u32_array = (buffer: ArrayBufferLike, addr: number, len: number): Uint32Array => {
    return new Uint32Array(buffer, addr, len)
}
export const load_i32_array = (buffer: ArrayBufferLike, addr: number, len: number): Int32Array => {
    return new Int32Array(buffer, addr, len)
}
