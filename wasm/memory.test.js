import * as vi from "vitest"
import * as mem from "./memory.js"

void vi.describe("f16", () => {
	/** @type {[f: number, be_bits: number, le_bits: number][]} */

	// prettier-ignore
	const float_bit_pairs = [
        [  1.2    , 0b00111100_11001101, 0b11001101_00111100],
        [ -1.2    , 0b10111100_11001101, 0b11001101_10111100],
        [  0.0    , 0b00000000_00000000, 0b00000000_00000000],
        [  1.0    , 0b00111100_00000000, 0b00000000_00111100],
        [ -1.0    , 0b10111100_00000000, 0b00000000_10111100],
        [-27.15625, 0b11001110_11001010, 0b11001010_11001110],
        [ Infinity, 0b01111100_00000000, 0b00000000_01111100],
        [-Infinity, 0b11111100_00000000, 0b00000000_11111100],
    ]

	void vi.describe("loads f16", () => {
		const data = new DataView(new ArrayBuffer(2))
		for (const [f, be_bits, le_bits] of float_bit_pairs) {
			vi.it(`le: loads ${f}`, () => {
				data.setUint16(0, le_bits)
				const f16 = mem.load_f16(data, 0, true)
				vi.expect(f16).toBeCloseTo(f, 3)
			})
			vi.it(`be: loads ${f}`, () => {
				data.setUint16(0, be_bits)
				const f16 = mem.load_f16(data, 0, false)
				vi.expect(f16).toBeCloseTo(f, 3)
			})
		}
	})

	void vi.describe("stores f16", () => {
		const data = new DataView(new ArrayBuffer(2))
		for (const [f, be_bits, le_bits] of float_bit_pairs) {
			vi.it(`le: stores ${f}`, () => {
				mem.store_f16(data, 0, f, true)
				const f16 = data.getUint16(0)
				vi.expect(f16).toBe(le_bits)
			})
			vi.it(`be: stores ${f}`, () => {
				mem.store_f16(data, 0, f, false)
				const f16 = data.getUint16(0)
				vi.expect(f16).toBe(be_bits)
			})
		}
	})
})

void vi.describe("u64", () => {
	/** @type {[v: bigint, bits: bigint][]} */
	// prettier-ignore
	const pairs = [
        [  0n             , 0x00_00_00_00_00_00_00_00n],
        [  1n             , 0x00_00_00_00_00_00_00_01n],
        [  2n             , 0x00_00_00_00_00_00_00_02n],
        [  1n << 32n      , 0x00_00_00_01_00_00_00_00n],
        [  2n << 32n      , 0x00_00_00_02_00_00_00_00n],
        [ (2n << 32n) - 1n, 0x00_00_00_01_FF_FF_FF_FFn],
        [  1n << 63n      , 0x80_00_00_00_00_00_00_00n],
        [9007199254740991n, 0x00_1F_FF_FF_FF_FF_FF_FFn],
    ]

	const data = new DataView(new ArrayBuffer(8))

	for (const [v, bits] of pairs) {
		for (const endian of ["le", "be"]) {
			const le = endian === "le"

			vi.it(`${endian}: loads ${v}`, () => {
				data.setBigUint64(0, bits, le)
				const loaded = mem.load_u64(data, 0, le)
				vi.expect(loaded).toBe(v)
			})

			vi.it(`${endian}: stores ${v}`, () => {
				mem.store_u64(data, 0, v, le)
				const loaded = data.getBigUint64(0, le)
				vi.expect(loaded).toBe(bits)
			})
		}
	}
})

void vi.describe("u64 number", () => {
	/** @type {[v: number, bits: bigint][]} */
	// prettier-ignore
	const pairs = [
        [0               , 0x00_00_00_00_00_00_00_00n],
        [1               , 0x00_00_00_00_00_00_00_01n],
        [256             , 0x00_00_00_00_00_00_01_00n],
        [1697990142353   , 0x00_00_01_8B_58_19_69_91n],
        [9007199254740991, 0x00_1F_FF_FF_FF_FF_FF_FFn],
    ]

	const data = new DataView(new ArrayBuffer(8))

	for (const [v, bits] of pairs) {
		for (const endian of ["le", "be"]) {
			const le = endian === "le"

			vi.it(`${endian}: loads ${v}`, () => {
				data.setBigUint64(0, bits, le)
				const loaded = mem.load_u64_number(data, 0, le)
				vi.expect(loaded).toBe(v)
			})

			vi.it(`${endian}: stores ${v}`, () => {
				mem.store_u64_number(data, 0, v, le)
				const loaded = data.getBigUint64(0, le)
				vi.expect(loaded).toBe(bits)
			})
		}
	}
})

void vi.describe("i64", () => {
	/** @type {[v: bigint, bits: bigint][]} */
	// prettier-ignore
	const pairs = [
        [  0n             , 0x00_00_00_00_00_00_00_00n],
        [  1n             , 0x00_00_00_00_00_00_00_01n],
        [ -1n             , 0xFF_FF_FF_FF_FF_FF_FF_FFn],
        [  2n             , 0x00_00_00_00_00_00_00_02n],
        [ -2n             , 0xFF_FF_FF_FF_FF_FF_FF_FEn],
        [  1n << 32n      , 0x00_00_00_01_00_00_00_00n],
        [  2n << 32n      , 0x00_00_00_02_00_00_00_00n],
        [ (2n << 32n) - 1n, 0x00_00_00_01_FF_FF_FF_FFn],
        [-(1n << 32n)     , 0xFF_FF_FF_FF_00_00_00_00n],
        [-(2n << 32n) + 1n, 0xFF_FF_FF_FE_00_00_00_01n],
        [-(2n << 32n) - 1n, 0xFF_FF_FF_FD_FF_FF_FF_FFn],
    ]

	const data = new DataView(new ArrayBuffer(8))

	for (const [v, bits] of pairs) {
		for (const endian of ["le", "be"]) {
			const le = endian === "le"

			vi.it(`${endian}: loads ${v}`, () => {
				data.setBigUint64(0, bits, le)
				const loaded = mem.load_i64(data, 0, le)
				vi.expect(loaded).toBe(v)
			})

			vi.it(`${endian}: stores ${v}`, () => {
				mem.store_i64(data, 0, v, le)
				const loaded = data.getBigUint64(0, le)
				vi.expect(loaded).toBe(bits)
			})
		}
	}
})

void vi.describe("i64 number", () => {
	/** @type {[v: number, bits: bigint][]} */
	// prettier-ignore
	const pairs = [
        [ 0               , 0x00_00_00_00_00_00_00_00n],
        [ 1               , 0x00_00_00_00_00_00_00_01n],
        [-1               , 0xFF_FF_FF_FF_FF_FF_FF_FFn],
        [ 2               , 0x00_00_00_00_00_00_00_02n],
        [-2               , 0xFF_FF_FF_FF_FF_FF_FF_FEn],
        [ 256             , 0x00_00_00_00_00_00_01_00n],
        [-256             , 0xFF_FF_FF_FF_FF_FF_FF_00n],
        [ 1697990142353   , 0x00_00_01_8B_58_19_69_91n],
        [-1697990142353   , 0xFF_FF_FE_74_A7_E6_96_6Fn],
        [ 9007199254740980, 0x00_1F_FF_FF_FF_FF_FF_F4n],
        [-9007199254740980, 0xFF_E0_00_00_00_00_00_0Cn],
    ]

	const data = new DataView(new ArrayBuffer(8))

	for (const [v, bits] of pairs) {
		for (const endian of ["le", "be"]) {
			const le = endian === "le"

			vi.it(`${endian}: loads ${v}`, () => {
				data.setBigUint64(0, bits, le)
				const loaded = mem.load_i64_number(data, 0, le)
				vi.expect(loaded).toBe(v)
			})

			vi.it(`${endian}: stores ${v}`, () => {
				mem.store_i64_number(data, 0, v, le)
				const loaded = data.getBigUint64(0, le)
				vi.expect(loaded).toBe(bits)
			})
		}
	}
})

void vi.describe("u128", () => {
	/** @type {[v: bigint, bits: [bigint, bigint]][]} */
	// prettier-ignore
	const pairs = [
        [0n       , [0x00_00_00_00_00_00_00_00n, 0x00_00_00_00_00_00_00_00n]],
        [1n       , [0x00_00_00_00_00_00_00_00n, 0x00_00_00_00_00_00_00_01n]],
        [256n     , [0x00_00_00_00_00_00_00_00n, 0x00_00_00_00_00_00_01_00n]],
        [1n << 64n, [0x00_00_00_00_00_00_00_01n, 0x00_00_00_00_00_00_00_00n]],
    ]

	const data = new DataView(new ArrayBuffer(16))

	for (const [v, [bits_a, bits_b]] of pairs) {
		for (const endian of ["le", "be"]) {
			const le = endian === "le"

			vi.it(`${endian}: loads ${v}`, () => {
				data.setBigUint64(0 + 8 * /** @type {any} */ (le), bits_a, le)
				data.setBigUint64(0 + 8 * /** @type {any} */ (!le), bits_b, le)
				const loaded = mem.load_u128(data, 0, le)
				vi.expect(loaded).toBe(v)
			})

			vi.it(`${endian}: stores ${v}`, () => {
				mem.store_u128(data, 0, v, le)
				const loaded_a = data.getBigUint64(0 + 8 * /** @type {any} */ (le), le)
				const loaded_b = data.getBigUint64(0 + 8 * /** @type {any} */ (!le), le)
				vi.expect(loaded_a).toBe(bits_a)
				vi.expect(loaded_b).toBe(bits_b)
			})
		}
	}
})

void vi.describe("i128", () => {
	/** @type {[v: bigint, bits: [bigint, bigint]][]} */
	// prettier-ignore
	const pairs = [
        [0n          , [0x00_00_00_00_00_00_00_00n, 0x00_00_00_00_00_00_00_00n]],
        [1n          , [0x00_00_00_00_00_00_00_00n, 0x00_00_00_00_00_00_00_01n]],
        [-1n         , [0xFF_FF_FF_FF_FF_FF_FF_FFn, 0xFF_FF_FF_FF_FF_FF_FF_FFn]],
        [2n          , [0x00_00_00_00_00_00_00_00n, 0x00_00_00_00_00_00_00_02n]],
        [-2n         , [0xFF_FF_FF_FF_FF_FF_FF_FFn, 0xFF_FF_FF_FF_FF_FF_FF_FEn]],
        [1n << 64n   , [0x00_00_00_00_00_00_00_01n, 0x00_00_00_00_00_00_00_00n]],
        [2n << 64n   , [0x00_00_00_00_00_00_00_02n, 0x00_00_00_00_00_00_00_00n]],
        [-(1n << 64n), [0xFF_FF_FF_FF_FF_FF_FF_FFn, 0x00_00_00_00_00_00_00_00n]],
        [-(2n << 64n), [0xFF_FF_FF_FF_FF_FF_FF_FEn, 0x00_00_00_00_00_00_00_00n]],
    ]

	const data = new DataView(new ArrayBuffer(16))

	for (const [v, [bits_a, bits_b]] of pairs) {
		for (const endian of ["le", "be"]) {
			const le = endian === "le"

			vi.it(`${endian}: loads ${v}`, () => {
				data.setBigUint64(0 + 8 * /** @type {any} */ (le), bits_a, le)
				data.setBigUint64(0 + 8 * /** @type {any} */ (!le), bits_b, le)
				const loaded = mem.load_i128(data, 0, le)
				vi.expect(loaded).toBe(v)
			})

			vi.it(`${endian}: stores ${v}`, () => {
				mem.store_i128(data, 0, v, le)
				const loaded_a = data.getBigUint64(0 + 8 * /** @type {any} */ (le), le)
				const loaded_b = data.getBigUint64(0 + 8 * /** @type {any} */ (!le), le)
				vi.expect(loaded_a).toBe(bits_a)
				vi.expect(loaded_b).toBe(bits_b)
			})
		}
	}
})
