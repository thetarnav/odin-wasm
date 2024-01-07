import * as mem from "../memory.js"

// eslint-disable-next-line @typescript-eslint/no-unused-vars
import * as t from "./types.js"

/** @returns {t.WebGLInterface} */
export function makeWebGLInterface() {
	return {
		element: null,
		/* will be set later, most of the time we want to assert that it's not null */
		ctx: /** @type {any} */ (null),
		version: 1,
		id_counter: 1,
		last_error: 0,
		buffers: [],
		programs: [],
		framebuffers: [],
		renderbuffers: [],
		textures: [],
		uniforms: [],
		shaders: [],
		vaos: [],
		queries: [],
		samplers: [],
		transform_feedbacks: [],
		syncs: [],
		program_infos: [],
	}
}

export const EMPTY_U8_ARRAY = new Uint8Array(0)

export const INVALID_VALUE = 0x0501
export const INVALID_OPERATION = 0x0502

/**
 * @param {t.WebGLInterface} webgl
 * @param {?} element
 * @param {WebGLContextAttributes | undefined} context_settings
 * @returns {boolean}
 */
export function setCurrentContext(webgl, element, context_settings) {
	if (!(element instanceof HTMLCanvasElement)) return false
	if (webgl.element === element) return true

	const ctx =
		element.getContext("webgl2", context_settings) ||
		element.getContext("webgl", context_settings)
	if (!ctx) return false

	webgl.ctx = ctx
	webgl.element = element
	webgl.version = webgl.ctx.getParameter(0x1f02).indexOf("WebGL 2.0") !== -1 ? 2 : 1

	return true
}

/**
 * @param {t.WebGLInterface} webgl
 * @returns {number}
 */
export function newId(webgl) {
	return webgl.id_counter++
}
/**
 * @param {t.WebGLInterface} webgl
 * @param {number} error_code
 * @returns {void}
 */
export function recordError(webgl, error_code) {
	if (!webgl.last_error) {
		webgl.last_error = error_code
	}
}
/**
 * @param {t.WebGLInterface} webgl
 * @param {number} program_id
 * @returns {void}
 */
export function populateUniformTable(webgl, program_id) {
	/** @type {t.ProgramInfo} */
	const ptable = {
		uniforms: {},
		maxUniformLength: 0,
		maxAttributeLength: -1,
		maxUniformBlockNameLength: -1,
	}
	webgl.program_infos[program_id] = ptable

	const program = /** @type {WebGLBuffer} */ (webgl.programs[program_id]),
		utable = ptable.uniforms,
		num_uniforms = webgl.ctx.getProgramParameter(program, webgl.ctx.ACTIVE_UNIFORMS)

	for (let i = 0; i < num_uniforms; ++i) {
		const u = webgl.ctx.getActiveUniform(program, i)
		if (!u) continue

		let name = u.name
		if (
			((ptable.maxUniformLength = Math.max(ptable.maxUniformLength, name.length + 1)),
			name.indexOf("]", name.length - 1) !== -1)
		) {
			name = name.slice(0, name.lastIndexOf("["))
		}

		const loc = webgl.ctx.getUniformLocation(program, name)
		if (!loc) continue

		const id = newId(webgl)
		utable[name] = [u.size, id]
		webgl.uniforms[id] = loc

		for (let j = 1; j < u.size; ++j) {
			const n = name + "[" + j + "]"
			const loc = webgl.ctx.getUniformLocation(program, n)
			const id = newId(webgl)
			webgl.uniforms[id] = loc
		}
	}
}
/**
 * @param {ArrayBufferLike} buffer
 * @param {number} strings_ptr
 * @param {number} strings_length
 * @returns {string}
 */
export function getSource(buffer, strings_ptr, strings_length) {
	const data = new DataView(buffer)
	let source = ""
	for (let i = 0; i < strings_length; i++) {
		source += mem.load_string(data, strings_ptr + i * mem.STRING_SIZE)
	}
	return source
}
