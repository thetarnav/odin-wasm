import * as mem from "../memory.js"

/**
 * @typedef {import('../types.js').WasmInstance} WasmInstance
 * @typedef {import('./types.js').WebGLInterface} WebGLInterface
 */

/**
 * @param {WasmInstance} wasm
 * @returns {WebGLInterface}
 */
function makeWebGLInterface(wasm) {
	return {
		wasm: wasm,
		element: null,
		/* will be set later, most of the time we want to assert that it's not null */
		ctx: /**@type {*}*/ (null),
		version: 1,
		counter: 1,
		last_error: 0,
		buffers: [],
		mappedBuffers: {},
		programs: [],
		framebuffers: [],
		renderbuffers: [],
		textures: [],
		uniforms: [],
		shaders: [],
		vaos: [],
		contexts: [],
		currentContext: null,
		offscreenCanvases: {},
		timerQueriesEXT: [],
		queries: [],
		samplers: [],
		transformFeedbacks: [],
		syncs: [],
		programInfos: {},
	}
}

const EMPTY_U8_ARRAY = new Uint8Array(0)

/**
 * @param {WebGLInterface} webgl
 * @param {?} element
 * @param {WebGLContextAttributes | undefined} context_settings
 * @returns {boolean} */
function setCurrentContext(webgl, element, context_settings) {
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
 * @param {WebGLInterface} webgl
 * @returns {void | never} */
function assertWebGL2(webgl) {
	if (webgl.version < 2) {
		throw new Error("WebGL2 procedure called in a canvas without a WebGL2 context")
	}
}
/**
 * @param {WebGLInterface} webgl
 * @returns {number} */
function getNewId(webgl, table) {
	for (var ret = webgl.counter++, i = table.length; i < ret; i++) {
		table[i] = null
	}
	return ret
}
/**
 * @param {WebGLInterface} webgl
 * @param {number} error_code
 * @returns {void} */
function recordError(webgl, error_code) {
	if (!webgl.last_error) {
		webgl.last_error = error_code
	}
}
/**
 * @param {WebGLInterface} webgl
 * @param {number} program_id
 * @returns {void} */
function populateUniformTable(webgl, program_id) {
	const program = webgl.programs[program_id]
	webgl.programInfos[program_id] = {
		uniforms: {},
		maxUniformLength: 0,
		maxAttributeLength: -1,
		maxUniformBlockNameLength: -1,
	}
	for (
		let ptable = webgl.programInfos[program_id],
			utable = ptable.uniforms,
			numUniforms = webgl.ctx.getProgramParameter(program, webgl.ctx.ACTIVE_UNIFORMS),
			i = 0;
		i < numUniforms;
		++i
	) {
		const u = webgl.ctx.getActiveUniform(program, i)
		if (!u) continue

		let name = u.name
		if (
			((ptable.maxUniformLength = Math.max(ptable.maxUniformLength, name.length + 1)),
			name.indexOf("]", name.length - 1) !== -1)
		) {
			name = name.slice(0, name.lastIndexOf("["))
		}

		let loc = webgl.ctx.getUniformLocation(program, name)
		if (!loc) continue

		let id = getNewId(webgl, webgl.uniforms)
		;(utable[name] = [u.size, id]), (webgl.uniforms[id] = loc)
		for (let j = 1; j < u.size; ++j) {
			let n = name + "[" + j + "]"
			let loc = webgl.ctx.getUniformLocation(program, n)
			let id = getNewId(webgl, webgl.uniforms)
			webgl.uniforms[id] = loc
		}
	}
}
/**
 * @param {WebGLInterface} webgl
 * @param {number} strings_ptr
 * @param {number} strings_length
 * @returns {string} */
function getSource(webgl, strings_ptr, strings_length) {
	const data = new DataView(webgl.wasm.memory.buffer)
	const STRING_SIZE = 2 * 4
	let source = ""
	for (let i = 0; i < strings_length; i++) {
		source += mem.load_string(data, strings_ptr + i * STRING_SIZE)
	}
	return source
}

/**
 * @param {import('../types.js').WasmInstance} wasm
 * @returns WebGL bindings for Odin
 */
export function makeOdinWebGl(wasm) {
	const webgl = makeWebGLInterface(wasm)

	return {
		/**
		 * @param {number} name_ptr
		 * @param {number} name_len
		 * @returns {boolean} */
		SetCurrentContextById: (name_ptr, name_len) => {
			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			const element = document.getElementById(name)

			return setCurrentContext(webgl, element, {
				alpha: true,
				antialias: true,
				depth: true,
				premultipliedAlpha: true,
			})
		},
		/**
		 * @param {number} name_ptr element id
		 * @param {number} name_len
		 * @param {number} attrs bitset
		 * @returns {boolean} */
		CreateCurrentContextById: (name_ptr, name_len, attrs) => {
			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			const element = document.getElementById(name)

			return setCurrentContext(
				webgl,
				element,
				// prettier-ignore
				{
				alpha: 						   !(attrs & (1 << 0)),
				antialias: 					   !(attrs & (1 << 1)),
				depth: 						   !(attrs & (1 << 2)),
				failIfMajorPerformanceCaveat: !!(attrs & (1 << 3)),
				premultipliedAlpha: 		   !(attrs & (1 << 4)),
				preserveDrawingBuffer: 		  !!(attrs & (1 << 5)),
				stencil: 					  !!(attrs & (1 << 6)),
				desynchronized: 			  !!(attrs & (1 << 7)),
				},
			)
		},
		/**
		 * @returns {number} */
		// prettier-ignore
		GetCurrentContextAttributes() {
			// eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
			if (!webgl.ctx) return 0

			const attrs = webgl.ctx.getContextAttributes()
			if (!attrs) return 0

			let res = 0
			if (!attrs.alpha) 						 res |= 1 << 0
			if (!attrs.antialias) 					 res |= 1 << 1
			if (!attrs.depth) 						 res |= 1 << 2
			if ( attrs.failIfMajorPerformanceCaveat) res |= 1 << 3
			if (!attrs.premultipliedAlpha) 			 res |= 1 << 4
			if ( attrs.preserveDrawingBuffer) 		 res |= 1 << 5
			if ( attrs.stencil) 					 res |= 1 << 6
			if ( attrs.desynchronized) 				 res |= 1 << 7

			return res
		},
		/**
		 * @returns {number} */
		DrawingBufferWidth: () => webgl.ctx.drawingBufferWidth,
		/**
		 * @returns {number} */
		DrawingBufferHeight: () => webgl.ctx.drawingBufferHeight,
		/**
		 * @param {number} name_ptr extension name
		 * @param {number} name_len
		 * @returns {boolean} */
		IsExtensionSupported(name_ptr, name_len) {
			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			const extensions = webgl.ctx.getSupportedExtensions()
			return extensions ? extensions.indexOf(name) !== -1 : false
		},
		/**
		 * @returns {number} */
		GetError() {
			if (webgl.last_error) {
				const err = webgl.last_error
				webgl.last_error = 0
				return err
			}
			return webgl.ctx.getError()
		},
		/**
		 * @param {number} major_ptr
		 * @param {number} minor_ptr
		 * @returns {void} */
		GetWebGLVersion(major_ptr, minor_ptr) {
			const data = new DataView(wasm.memory.buffer)
			mem.store_i32(data, major_ptr, webgl.version)
			mem.store_i32(data, minor_ptr, 0)
		},
		/**
		 * @param {number} major_ptr
		 * @param {number} minor_ptr
		 * @returns {void} */
		GetESVersion(major_ptr, minor_ptr) {
			const major = webgl.ctx.getParameter(0x1f02).indexOf("OpenGL ES 3.0") !== -1 ? 3 : 2
			const data = new DataView(wasm.memory.buffer)
			mem.store_i32(data, major_ptr, major)
			mem.store_i32(data, minor_ptr, 0)
		},
		/**
		 * @param {number} texture
		 * @returns {void} */
		ActiveTexture(texture) {
			webgl.ctx.activeTexture(texture)
		},
		/**
		 * @param {number} program
		 * @param {number} shader
		 * @returns {void} */
		AttachShader(program, shader) {
			webgl.ctx.attachShader(webgl.programs[program], webgl.shaders[shader])
		},
		/**
		 * @param {number} program
		 * @param {number} index
		 * @param {number} name_ptr
		 * @param {number} name_len
		 * @returns {void} */
		BindAttribLocation(program, index, name_ptr, name_len) {
			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			webgl.ctx.bindAttribLocation(webgl.programs[program], index, name)
		},
		/**
		 * @param {number} target
		 * @param {number} buffer
		 * @returns {void} */
		BindBuffer(target, buffer) {
			const bufferObj = buffer ? webgl.buffers[buffer] : null
			if (target == 35051) {
				webgl.ctx.currentPixelPackBufferBinding = buffer
			} else {
				if (target == 35052) {
					webgl.ctx.currentPixelUnpackBufferBinding = buffer
				}
				webgl.ctx.bindBuffer(target, bufferObj)
			}
		},
		/**
		 * @param {number} target
		 * @param {number} framebuffer
		 * @returns {void} */
		BindFramebuffer(target, framebuffer) {
			webgl.ctx.bindFramebuffer(target, framebuffer ? webgl.framebuffers[framebuffer] : null)
		},
		/**
		 * @param {number} target
		 * @param {number} texture
		 * @returns {void} */
		BindTexture(target, texture) {
			webgl.ctx.bindTexture(target, texture ? webgl.textures[texture] : null)
		},
		/**
		 * @param {number} r
		 * @param {number} g
		 * @param {number} b
		 * @param {number} a
		 * @returns {void} */
		BlendColor(r, g, b, a) {
			webgl.ctx.blendColor(r, g, b, a)
		},
		/**
		 * @param {number} mode
		 * @returns {void} */
		BlendEquation(mode) {
			webgl.ctx.blendEquation(mode)
		},
		/**
		 * @param {number} sfactor
		 * @param {number} dfactor
		 * @returns {void} */
		BlendFunc(sfactor, dfactor) {
			webgl.ctx.blendFunc(sfactor, dfactor)
		},
		/**
		 * @param {number} srcRGB
		 * @param {number} dstRGB
		 * @param {number} srcAlpha
		 * @param {number} dstAlpha
		 * @returns {void} */
		BlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha) {
			webgl.ctx.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha)
		},
		/**
		 * @param {number} target
		 * @param {number} size
		 * @param {number} data
		 * @param {number} usage
		 * @returns {void} */
		BufferData: (target, size, data, usage) => {
			if (data) {
				webgl.ctx.bufferData(target, mem.load_bytes(wasm.memory.buffer, data, size), usage)
			} else {
				webgl.ctx.bufferData(target, size, usage)
			}
		},
		/**
		 * @param {number} target
		 * @param {number} offset
		 * @param {number} size
		 * @param {number} data
		 * @returns {void} */
		BufferSubData: (target, offset, size, data) => {
			webgl.ctx.bufferSubData(
				target,
				offset,
				data ? mem.load_bytes(wasm.memory.buffer, data, size) : EMPTY_U8_ARRAY,
			)
		},
		/**
		 * @param {number} mask
		 * @returns {void} */
		Clear: mask => {
			webgl.ctx.clear(mask)
		},
		/**
		 *
		 * @param {number} r
		 * @param {number} g
		 * @param {number} b
		 * @param {number} a
		 * @returns {void} */
		ClearColor: (r, g, b, a) => {
			webgl.ctx.clearColor(r, g, b, a)
		},
		/**
		 * @param {number} depth
		 * @returns {void} */
		ClearDepth: depth => {
			webgl.ctx.clearDepth(depth)
		},
		/**
		 * @param {number} s
		 * @returns {void} */
		ClearStencil: s => {
			webgl.ctx.clearStencil(s)
		},
		/**
		 *
		 * @param {number} r
		 * @param {number} g
		 * @param {number} b
		 * @param {number} a
		 * @returns {void} */
		ColorMask: (r, g, b, a) => {
			webgl.ctx.colorMask(!!r, !!g, !!b, !!a)
		},
		/**
		 * @param {number} shader
		 * @returns {void} */
		CompileShader: shader => {
			webgl.ctx.compileShader(webgl.shaders[shader])
		},
		CompressedTexImage2D: (
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ internalformat,
			/** @type {number} */ width,
			/** @type {number} */ height,
			/** @type {number} */ border,
			/** @type {number} */ imageSize,
			/** @type {number} */ data,
		) => {
			webgl.ctx.compressedTexImage2D(
				target,
				level,
				internalformat,
				width,
				height,
				border,
				data ? mem.load_bytes(wasm.memory.buffer, data, imageSize) : EMPTY_U8_ARRAY,
			)
		},
		CompressedTexSubImage2D: (
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ xoffset,
			/** @type {number} */ yoffset,
			/** @type {number} */ width,
			/** @type {number} */ height,
			/** @type {number} */ format,
			/** @type {number} */ imageSize,
			/** @type {number} */ data,
		) => {
			webgl.ctx.compressedTexSubImage2D(
				target,
				level,
				xoffset,
				yoffset,
				width,
				height,
				format,
				data ? mem.load_bytes(wasm.memory.buffer, data, imageSize) : EMPTY_U8_ARRAY,
			)
		},
		CopyTexImage2D: (
			/**@type {number}*/ target,
			/**@type {number}*/ level,
			/**@type {number}*/ internalformat,
			/**@type {number}*/ x,
			/**@type {number}*/ y,
			/**@type {number}*/ width,
			/**@type {number}*/ height,
			/**@type {number}*/ border,
		) => {
			webgl.ctx.copyTexImage2D(target, level, internalformat, x, y, width, height, border)
		},
		CopyTexSubImage2D: (
			/**@type {number}*/ target,
			/**@type {number}*/ level,
			/**@type {number}*/ xoffset,
			/**@type {number}*/ yoffset,
			/**@type {number}*/ x,
			/**@type {number}*/ y,
			/**@type {number}*/ width,
			/**@type {number}*/ height,
		) => {
			webgl.ctx.copyTexImage2D(target, level, xoffset, yoffset, x, y, width, height)
		},
		/**
		 * @returns {number} */
		CreateBuffer: () => {
			const buffer = webgl.ctx.createBuffer()
			if (!buffer) {
				recordError(webgl, 1282)
				return 0
			}
			const id = getNewId(webgl, webgl.buffers)
			buffer.name = id
			webgl.buffers[id] = buffer
			return id
		},
		/**
		 * @returns {number} */
		CreateFramebuffer: () => {
			const buffer = webgl.ctx.createFramebuffer()
			if (!buffer) {
				recordError(webgl, 1282)
				return 0
			}
			const id = getNewId(webgl, webgl.framebuffers)
			buffer.name = id
			webgl.framebuffers[id] = buffer
			return id
		},
		/**
		 * @returns {number} */
		CreateRenderbuffer: () => {
			const buffer = webgl.ctx.createRenderbuffer()
			if (!buffer) {
				recordError(webgl, 1282)
				return 0
			}
			const id = getNewId(webgl, webgl.renderbuffers)
			buffer.name = id
			webgl.renderbuffers[id] = buffer
			return id
		},
		/**
		 * @returns {number} */
		CreateProgram: () => {
			const program = webgl.ctx.createProgram()
			if (!program) {
				recordError(webgl, 1282)
				return 0
			}
			const id = getNewId(webgl, webgl.programs)
			program.name = id
			webgl.programs[id] = program
			return id
		},
		/**
		 * @param {number} shaderType
		 * @returns {number} */
		CreateShader: shaderType => {
			const shader = webgl.ctx.createShader(shaderType)
			if (!shader) {
				recordError(webgl, 1282)
				return 0
			}
			const id = getNewId(webgl, webgl.shaders)
			shader.name = id
			webgl.shaders[id] = shader
			return id
		},
		/**
		 * @returns {number} */
		CreateTexture: () => {
			const texture = webgl.ctx.createTexture()
			if (!texture) {
				recordError(webgl, 1282)
				return 0
			}
			const id = getNewId(webgl, webgl.textures)
			texture.name = id
			webgl.textures[id] = texture
			return id
		},
		/**
		 * @param {number} mode
		 * @returns {void} */
		CullFace: mode => {
			webgl.ctx.cullFace(mode)
		},
		/**
		 * @param {number} id
		 * @returns {void} */
		DeleteBuffer: id => {
			if (id === 0) return

			const obj = webgl.buffers[id]
			if (obj) {
				webgl.ctx.deleteBuffer(obj)
				webgl.buffers[id] = 0
			}
		},
		/**
		 * @param {number} id
		 * @returns {void} */
		DeleteFramebuffer: id => {
			if (id === 0) return

			const obj = webgl.framebuffers[id]
			if (obj) {
				webgl.ctx.deleteFramebuffer(obj)
				webgl.framebuffers[id] = 0
			}
		},
		/**
		 * @param {number} id
		 * @returns {void} */
		DeleteProgram: id => {
			if (id === 0) return

			const obj = webgl.programs[id]
			if (obj) {
				webgl.ctx.deleteProgram(obj)
				webgl.programs[id] = 0
			}
		},
		/**
		 * @param {number} id
		 * @returns {void} */
		DeleteRenderbuffer: id => {
			if (id === 0) return

			const obj = webgl.renderbuffers[id]
			if (obj) {
				webgl.ctx.deleteRenderbuffer(obj)
				webgl.renderbuffers[id] = 0
			}
		},
		/**
		 * @param {number} id
		 * @returns {void} */
		DeleteShader: id => {
			if (id === 0) return

			const obj = webgl.shaders[id]
			if (obj) {
				webgl.ctx.deleteShader(obj)
				webgl.shaders[id] = 0
			}
		},
		/**
		 * @param {number} id
		 * @returns {void} */
		DeleteTexture: id => {
			if (id === 0) return

			const obj = webgl.textures[id]
			if (obj) {
				webgl.ctx.deleteTexture(obj)
				webgl.textures[id] = 0
			}
		},
		/**
		 * @param {number} func
		 * @returns {void} */
		DepthFunc: func => {
			webgl.ctx.depthFunc(func)
		},
		/**
		 * @param {boolean} flag
		 * @returns {void} */
		DepthMask: flag => {
			webgl.ctx.depthMask(flag)
		},
		/**
		 * @param {number} zNear
		 * @param {number} zFar
		 * @returns {void} */
		DepthRange: (zNear, zFar) => {
			webgl.ctx.depthRange(zNear, zFar)
		},
		/**
		 * @param {number} program
		 * @param {number} shader
		 * @returns {void} */
		DetachShader: (program, shader) => {
			webgl.ctx.detachShader(webgl.programs[program], webgl.shaders[shader])
		},
		/**
		 * @param {number} cap
		 * @returns {void} */
		Disable: cap => {
			webgl.ctx.disable(cap)
		},
		/**
		 * @param {number} index
		 * @returns {void} */
		DisableVertexAttribArray: index => {
			webgl.ctx.disableVertexAttribArray(index)
		},
		/**
		 * @param {number} mode
		 * @param {number} first
		 * @param {number} count
		 * @returns {void} */
		DrawArrays: (mode, first, count) => {
			webgl.ctx.drawArrays(mode, first, count)
		},
		/**
		 * @param {number} mode
		 * @param {number} count
		 * @param {number} type
		 * @param {number} indices
		 * @returns {void} */
		DrawElements: (mode, count, type, indices) => {
			webgl.ctx.drawElements(mode, count, type, indices)
		},
		/**
		 * @param {number} cap
		 * @returns {void} */
		Enable: cap => {
			webgl.ctx.enable(cap)
		},
		/**
		 * @param {number} index
		 * @returns {void} */
		EnableVertexAttribArray: index => {
			webgl.ctx.enableVertexAttribArray(index)
		},
		/**
		 * @returns {void} */
		Finish: () => {
			webgl.ctx.finish()
		},
		/**
		 * @returns {void} */
		Flush: () => {
			webgl.ctx.flush()
		},
		/**
		 * @param {number} target
		 * @param {number} attachment
		 * @param {number} renderbuffertarget
		 * @param {number} renderbuffer
		 * @returns {void} */
		FramebufferRenderbuffer: (target, attachment, renderbuffertarget, renderbuffer) => {
			webgl.ctx.framebufferRenderbuffer(
				target,
				attachment,
				renderbuffertarget,
				webgl.renderbuffers[renderbuffer],
			)
		},
		/**
		 * @param {number} target
		 * @param {number} attachment
		 * @param {number} textarget
		 * @param {number} texture
		 * @param {number} level
		 * @returns {void} */
		FramebufferTexture2D: (target, attachment, textarget, texture, level) => {
			webgl.ctx.framebufferTexture2D(
				target,
				attachment,
				textarget,
				webgl.textures[texture],
				level,
			)
		},
		/**
		 * @param {number} mode
		 * @returns {void} */
		FrontFace: mode => {
			webgl.ctx.frontFace(mode)
		},
		/**
		 * @param {number} target
		 * @returns {void} */
		GenerateMipmap: target => {
			webgl.ctx.generateMipmap(target)
		},
		/**
		 * @param {number} program
		 * @param {number} name_ptr
		 * @param {number} name_len
		 * @returns {number} */
		GetAttribLocation: (program, name_ptr, name_len) => {
			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			return webgl.ctx.getAttribLocation(webgl.programs[program], name)
		},
		/**
		 * @param {number} pname
		 * @returns {number} */
		GetParameter: pname => {
			return webgl.ctx.getParameter(pname)
		},
		/**
		 * @param {number} program
		 * @param {number} pname
		 * @returns {number} */
		GetProgramParameter: (program, pname) => {
			return webgl.ctx.getProgramParameter(webgl.programs[program], pname)
		},
		/**
		 * @param {number} program
		 * @param {number} buf_ptr
		 * @param {number} buf_len
		 * @param {number} length_ptr
		 * @returns {void} */
		GetProgramInfoLog: (program, buf_ptr, buf_len, length_ptr) => {
			if (buf_len <= 0 || !buf_ptr) return

			const log = webgl.ctx.getProgramInfoLog(webgl.programs[program]) ?? "(unknown error)"
			const n = mem.store_string_raw(wasm.memory.buffer, buf_ptr, buf_len, log)
			mem.store_int(new DataView(wasm.memory.buffer), length_ptr, n)
		},
		/**
		 * @param {number} shader
		 * @param {number} buf_ptr
		 * @param {number} buf_len
		 * @param {number} length_ptr
		 * @returns {void} */
		GetShaderInfoLog: (shader, buf_ptr, buf_len, length_ptr) => {
			if (buf_len <= 0 || !buf_ptr) return

			const log = webgl.ctx.getShaderInfoLog(webgl.shaders[shader]) ?? "(unknown error)"
			const n = mem.store_string_raw(wasm.memory.buffer, buf_ptr, buf_len, log)
			mem.store_int(new DataView(wasm.memory.buffer), length_ptr, n)
		},
		/**
		 * @param {number} shader_id
		 * @param {number} pname
		 * @param {number} p
		 * @returns {void} */
		GetShaderiv: (shader_id, pname, p) => {
			if (!p) {
				recordError(webgl, 1281)
				return
			}

			const data = new DataView(wasm.memory.buffer)
			const shader = webgl.shaders[shader_id]

			switch (pname) {
				case 35716: {
					const log = webgl.ctx.getShaderInfoLog(shader) ?? "(unknown error)"
					mem.store_int(data, p, log.length + 1)
					break
				}
				case 35720: {
					const source = webgl.ctx.getShaderSource(shader)
					const sourceLength =
						source === null || source.length == 0 ? 0 : source.length + 1
					mem.store_int(data, p, sourceLength)
					break
				}
				default: {
					const param = webgl.ctx.getShaderParameter(shader, pname)
					mem.store_i32(data, p, param)
					break
				}
			}
		},
		/**
		 * @param {number} program
		 * @param {number} name_ptr
		 * @param {number} name_len
		 * @returns {number} */
		GetUniformLocation: (program, name_ptr, name_len) => {
			let name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			let array_offset = 0

			if (name.indexOf("]", name.length - 1) !== -1) {
				const ls = name.lastIndexOf("["),
					array_index = name.slice(ls + 1, -1)

				if (array_index.length > 0 && (array_offset = parseInt(array_index)) < 0) {
					return -1
				}

				name = name.slice(0, ls)
			}

			const ptable = webgl.programInfos[program]
			if (!ptable) return -1

			const uniform_info = ptable.uniforms[name]
			return uniform_info && array_offset < uniform_info[0]
				? uniform_info[1] + array_offset
				: -1
		},
		/**
		 * @param {number} index
		 * @param {number} pname
		 * @returns {number} */
		GetVertexAttribOffset: (index, pname) => {
			return webgl.ctx.getVertexAttribOffset(index, pname)
		},
		/**
		 * @param {number} target
		 * @param {number} mode
		 * @returns {void} */
		Hint: (target, mode) => {
			webgl.ctx.hint(target, mode)
		},
		/**
		 * @param {number} buffer
		 * @returns {boolean} */
		IsBuffer: buffer => webgl.ctx.isBuffer(webgl.buffers[buffer]),
		/**
		 * @param {number} cap
		 * @returns {boolean} */
		IsEnabled: cap => webgl.ctx.isEnabled(cap),
		/**
		 * @param {number} framebuffer
		 * @returns {boolean} */
		IsFramebuffer: framebuffer => webgl.ctx.isFramebuffer(webgl.framebuffers[framebuffer]),
		/**
		 * @param {number} program
		 * @returns {boolean} */
		IsProgram: program => webgl.ctx.isProgram(webgl.programs[program]),
		/**
		 * @param {number} renderbuffer
		 * @returns {boolean} */
		IsRenderbuffer: renderbuffer => webgl.ctx.isRenderbuffer(webgl.renderbuffers[renderbuffer]),
		/**
		 * @param {number} shader
		 * @returns {boolean} */
		IsShader: shader => webgl.ctx.isShader(webgl.shaders[shader]),
		/**
		 * @param {number} texture
		 * @returns {boolean} */
		IsTexture: texture => webgl.ctx.isTexture(webgl.textures[texture]),
		/**
		 * @param {number} width
		 */
		LineWidth: width => {
			webgl.ctx.lineWidth(width)
		},
		/**
		 * @param {number} program
		 * @returns {void} */
		LinkProgram: program => {
			webgl.ctx.linkProgram(webgl.programs[program])
			webgl.programInfos[program] = null
			populateUniformTable(webgl, program)
		},
		/**
		 * @param {number} pname
		 * @param {number} param
		 * @returns {void} */
		PixelStorei: (pname, param) => {
			webgl.ctx.pixelStorei(pname, param)
		},
		/**
		 * @param {number} factor
		 * @param {number} units
		 * @returns {void} */
		PolygonOffset: (factor, units) => {
			webgl.ctx.polygonOffset(factor, units)
		},
		/**
		 * @param {number} x
		 * @param {number} y
		 * @param {number} width
		 * @param {number} height
		 * @param {number} format
		 * @param {number} type
		 * @param {number} data_len
		 * @param {number} data_ptr
		 * @returns {void} */
		ReadnPixels: (x, y, width, height, format, type, data_len, data_ptr) => {
			webgl.ctx.readPixels(
				x,
				y,
				width,
				height,
				format,
				type,
				mem.load_bytes(wasm.memory.buffer, data_ptr, data_len),
			)
		},
		/**
		 * @param {number} target
		 * @param {number} internalformat
		 * @param {number} width
		 * @param {number} height
		 * @returns {void} */
		RenderbufferStorage: (target, internalformat, width, height) => {
			webgl.ctx.renderbufferStorage(target, internalformat, width, height)
		},
		/**
		 * @param {number} value
		 * @param {boolean} invert
		 * @returns {void} */
		SampleCoverage: (value, invert) => {
			webgl.ctx.sampleCoverage(value, invert)
		},
		/**
		 * @param {number} x
		 * @param {number} y
		 * @param {number} width
		 * @param {number} height
		 * @returns {void} */
		Scissor: (x, y, width, height) => {
			webgl.ctx.scissor(x, y, width, height)
		},
		/**
		 * @param {number} shader
		 * @param {number} strings_ptr
		 * @param {number} strings_length
		 * @returns {void} */
		ShaderSource: (shader, strings_ptr, strings_length) => {
			const source = getSource(webgl, strings_ptr, strings_length)
			webgl.ctx.shaderSource(webgl.shaders[shader], source)
		},
		/**
		 * @param {number} func
		 * @param {number} ref
		 * @param {number} mask
		 * @returns {void} */
		StencilFunc: (func, ref, mask) => {
			webgl.ctx.stencilFunc(func, ref, mask)
		},
		/**
		 * @param {number} face
		 * @param {number} func
		 * @param {number} ref
		 * @param {number} mask
		 * @returns {void} */
		StencilFuncSeparate: (face, func, ref, mask) => {
			webgl.ctx.stencilFuncSeparate(face, func, ref, mask)
		},
		/**
		 * @param {number} mask
		 * @returns {void} */
		StencilMask: mask => {
			webgl.ctx.stencilMask(mask)
		},
		/**
		 * @param {number} face
		 * @param {number} mask
		 * @returns {void} */
		StencilMaskSeparate: (face, mask) => {
			webgl.ctx.stencilMaskSeparate(face, mask)
		},
		/**
		 * @param {number} fail
		 * @param {number} zfail
		 * @param {number} zpass
		 * @returns {void} */
		StencilOp: (fail, zfail, zpass) => {
			webgl.ctx.stencilOp(fail, zfail, zpass)
		},
		/**
		 * @param {number} face
		 * @param {number} fail
		 * @param {number} zfail
		 * @param {number} zpass
		 * @returns {void} */
		StencilOpSeparate: (face, fail, zfail, zpass) => {
			webgl.ctx.stencilOpSeparate(face, fail, zfail, zpass)
		},
		TexImage2D: (
			/**@type {number}*/ target,
			/**@type {number}*/ level,
			/**@type {number}*/ internalformat,
			/**@type {number}*/ width,
			/**@type {number}*/ height,
			/**@type {number}*/ border,
			/**@type {number}*/ format,
			/**@type {number}*/ type,
			/**@type {number}*/ size,
			/**@type {number}*/ data,
		) => {
			webgl.ctx.texImage2D(
				target,
				level,
				internalformat,
				width,
				height,
				border,
				format,
				type,
				data ? mem.load_bytes(wasm.memory.buffer, data, size) : EMPTY_U8_ARRAY,
			)
		},
		/**
		 * @param {number} target
		 * @param {number} pname
		 * @param {number} param
		 * @returns {void} */
		TexParameterf: (target, pname, param) => {
			webgl.ctx.texParameterf(target, pname, param)
		},
		/**
		 * @param {number} target
		 * @param {number} pname
		 * @param {number} param
		 * @returns {void} */
		TexParameteri: (target, pname, param) => {
			webgl.ctx.texParameteri(target, pname, param)
		},
		TexSubImage2D: (
			/**@type {number}*/ target,
			/**@type {number}*/ level,
			/**@type {number}*/ xoffset,
			/**@type {number}*/ yoffset,
			/**@type {number}*/ width,
			/**@type {number}*/ height,
			/**@type {number}*/ format,
			/**@type {number}*/ type,
			/**@type {number}*/ size,
			/**@type {number}*/ data,
		) => {
			webgl.ctx.texSubImage2D(
				target,
				level,
				xoffset,
				yoffset,
				width,
				height,
				format,
				type,
				data ? mem.load_bytes(wasm.memory.buffer, data, size) : EMPTY_U8_ARRAY,
			)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @returns {void} */
		Uniform1f: (location, x) => {
			webgl.ctx.uniform1f(webgl.uniforms[location], x)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @param {number} y
		 * @returns {void} */
		Uniform2f: (location, x, y) => {
			webgl.ctx.uniform2f(webgl.uniforms[location], x, y)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @param {number} y
		 * @param {number} z
		 * @returns {void} */
		Uniform3f: (location, x, y, z) => {
			webgl.ctx.uniform3f(webgl.uniforms[location], x, y, z)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @param {number} y
		 * @param {number} z
		 * @param {number} w
		 * @returns {void} */
		Uniform4f: (location, x, y, z, w) => {
			webgl.ctx.uniform4f(webgl.uniforms[location], x, y, z, w)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @returns {void} */
		Uniform1i: (location, x) => {
			webgl.ctx.uniform1i(webgl.uniforms[location], x)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @param {number} y
		 * @returns {void} */
		Uniform2i: (location, x, y) => {
			webgl.ctx.uniform2i(webgl.uniforms[location], x, y)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @param {number} y
		 * @param {number} z
		 * @returns {void} */
		Uniform3i: (location, x, y, z) => {
			webgl.ctx.uniform3i(webgl.uniforms[location], x, y, z)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @param {number} y
		 * @param {number} z
		 * @param {number} w
		 * @returns {void} */
		Uniform4i: (location, x, y, z, w) => {
			webgl.ctx.uniform4i(webgl.uniforms[location], x, y, z, w)
		},
		/**
		 * @param {number} location
		 * @param {number} addr
		 * @returns {void} */
		UniformMatrix2fv: (location, addr) => {
			webgl.ctx.uniformMatrix4fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 2 * 2),
			)
		},
		/**
		 * @param {number} location
		 * @param {number} addr
		 * @returns {void} */
		UniformMatrix3fv: (location, addr) => {
			webgl.ctx.uniformMatrix4fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 3 * 3),
			)
		},
		/**
		 * @param {number} location
		 * @param {number} addr
		 * @returns {void} */
		UniformMatrix4fv: (location, addr) => {
			webgl.ctx.uniformMatrix4fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 4 * 4),
			)
		},

		UseProgram: program => {
			if (program) webgl.ctx.useProgram(webgl.programs[program])
		},
		ValidateProgram: program => {
			if (program) webgl.ctx.validateProgram(webgl.programs[program])
		},

		VertexAttrib1f: (index, x) => {
			webgl.ctx.vertexAttrib1f(index, x)
		},
		VertexAttrib2f: (index, x, y) => {
			webgl.ctx.vertexAttrib2f(index, x, y)
		},
		VertexAttrib3f: (index, x, y, z) => {
			webgl.ctx.vertexAttrib3f(index, x, y, z)
		},
		VertexAttrib4f: (index, x, y, z, w) => {
			webgl.ctx.vertexAttrib4f(index, x, y, z, w)
		},
		VertexAttribPointer: (index, size, type, normalized, stride, ptr) => {
			webgl.ctx.vertexAttribPointer(index, size, type, !!normalized, stride, ptr)
		},

		Viewport: (x, y, w, h) => {
			webgl.ctx.viewport(x, y, w, h)
		},
	}
}

/**
 * @param {import('../types.js').WasmInstance} wasm
 * @returns WebGL bindings for Odin
 */
export function makeOdinWegGl2(wasm) {
	return {
		/* Buffer objects */
		CopyBufferSubData: (readTarget, writeTarget, readOffset, writeOffset, size) => {
			webgl.assertWebGL2()
			webgl.ctx.copyBufferSubData(readTarget, writeTarget, readOffset, writeOffset, size)
		},
		GetBufferSubData: (
			target,
			srcByteOffset,
			dst_buffer_ptr,
			dst_buffer_len,
			dstOffset,
			length,
		) => {
			webgl.assertWebGL2()
			webgl.ctx.getBufferSubData(
				target,
				srcByteOffset,
				webgl.mem.loadBytes(dst_buffer_ptr, dst_buffer_len),
				dstOffset,
				length,
			)
		},

		/* Framebuffer objects */
		BlitFramebuffer: (srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter) => {
			webgl.assertWebGL2()
			webgl.ctx.glitFramebuffer(
				srcX0,
				srcY0,
				srcX1,
				srcY1,
				dstX0,
				dstY0,
				dstX1,
				dstY1,
				mask,
				filter,
			)
		},
		FramebufferTextureLayer: (target, attachment, texture, level, layer) => {
			webgl.assertWebGL2()
			webgl.ctx.framebufferTextureLayer(
				target,
				attachment,
				webgl.textures[texture],
				level,
				layer,
			)
		},
		InvalidateFramebuffer: (target, attachments_ptr, attachments_len) => {
			webgl.assertWebGL2()
			let attachments = webgl.mem.loadU32Array(attachments_ptr, attachments_len)
			webgl.ctx.invalidateFramebuffer(target, attachments)
		},
		InvalidateSubFramebuffer: (
			target,
			attachments_ptr,
			attachments_len,
			x,
			y,
			width,
			height,
		) => {
			webgl.assertWebGL2()
			let attachments = webgl.mem.loadU32Array(attachments_ptr, attachments_len)
			webgl.ctx.invalidateSubFramebuffer(target, attachments, x, y, width, height)
		},
		ReadBuffer: src => {
			webgl.assertWebGL2()
			webgl.ctx.readBuffer(src)
		},

		/* Renderbuffer objects */
		RenderbufferStorageMultisample: (target, samples, internalformat, width, height) => {
			webgl.assertWebGL2()
			webgl.ctx.renderbufferStorageMultisample(target, samples, internalformat, width, height)
		},

		/* Texture objects */

		TexStorage3D: (target, levels, internalformat, width, height, depth) => {
			webgl.assertWebGL2()
			webgl.ctx.texStorage3D(target, level, internalformat, width, heigh, depth)
		},
		TexImage3D: (
			target,
			level,
			internalformat,
			width,
			height,
			depth,
			border,
			format,
			type,
			size,
			data,
		) => {
			webgl.assertWebGL2()
			if (data) {
				webgl.ctx.texImage3D(
					target,
					level,
					internalformat,
					width,
					height,
					depth,
					border,
					format,
					type,
					webgl.mem.loadBytes(data, size),
				)
			} else {
				webgl.ctx.texImage3D(
					target,
					level,
					internalformat,
					width,
					height,
					depth,
					border,
					format,
					type,
					null,
				)
			}
		},
		TexSubImage3D: (
			target,
			level,
			xoffset,
			yoffset,
			zoffset,
			width,
			height,
			depth,
			format,
			type,
			size,
			data,
		) => {
			webgl.assertWebGL2()
			webgl.ctx.texSubImage3D(
				target,
				level,
				xoffset,
				yoffset,
				zoffset,
				width,
				height,
				depth,
				format,
				type,
				webgl.mem.loadBytes(data, size),
			)
		},
		CompressedTexImage3D: (
			target,
			level,
			internalformat,
			width,
			height,
			depth,
			border,
			imageSize,
			data,
		) => {
			webgl.assertWebGL2()
			if (data) {
				webgl.ctx.compressedTexImage3D(
					target,
					level,
					internalformat,
					width,
					height,
					depth,
					border,
					webgl.mem.loadBytes(data, imageSize),
				)
			} else {
				webgl.ctx.compressedTexImage3D(
					target,
					level,
					internalformat,
					width,
					height,
					depth,
					border,
					null,
				)
			}
		},
		CompressedTexSubImage3D: (
			target,
			level,
			xoffset,
			yoffset,
			zoffset,
			width,
			height,
			depth,
			format,
			imageSize,
			data,
		) => {
			webgl.assertWebGL2()
			if (data) {
				webgl.ctx.compressedTexSubImage3D(
					target,
					level,
					xoffset,
					yoffset,
					zoffset,
					width,
					height,
					depth,
					format,
					webgl.mem.loadBytes(data, imageSize),
				)
			} else {
				webgl.ctx.compressedTexSubImage3D(
					target,
					level,
					xoffset,
					yoffset,
					zoffset,
					width,
					height,
					depth,
					format,
					null,
				)
			}
		},

		CopyTexSubImage3D: (target, level, xoffset, yoffset, zoffset, x, y, width, height) => {
			webgl.assertWebGL2()
			webgl.ctx.copyTexImage3D(target, level, xoffset, yoffset, zoffset, x, y, width, height)
		},

		/* Programs and shaders */
		GetFragDataLocation: (program, name_ptr, name_len) => {
			webgl.assertWebGL2()
			return webgl.ctx.getFragDataLocation(
				webgl.programs[program],
				webgl.mem.loadString(name_ptr, name_len),
			)
		},

		/* Uniforms */
		Uniform1ui: (location, v0) => {
			webgl.assertWebGL2()
			webgl.ctx.uniform1ui(webgl.uniforms[location], v0)
		},
		Uniform2ui: (location, v0, v1) => {
			webgl.assertWebGL2()
			webgl.ctx.uniform2ui(webgl.uniforms[location], v0, v1)
		},
		Uniform3ui: (location, v0, v1, v2) => {
			webgl.assertWebGL2()
			webgl.ctx.uniform3ui(webgl.uniforms[location], v0, v1, v2)
		},
		Uniform4ui: (location, v0, v1, v2, v3) => {
			webgl.assertWebGL2()
			webgl.ctx.uniform4ui(webgl.uniforms[location], v0, v1, v2, v3)
		},

		UniformMatrix3x2fv: (location, addr) => {
			webgl.assertWebGL2()
			let array = webgl.mem.loadF32Array(addr, 3 * 2)
			webgl.ctx.uniformMatrix3x2fv(webgl.uniforms[location], false, array)
		},
		UniformMatrix4x2fv: (location, addr) => {
			webgl.assertWebGL2()
			let array = webgl.mem.loadF32Array(addr, 4 * 2)
			webgl.ctx.uniformMatrix4x2fv(webgl.uniforms[location], false, array)
		},
		UniformMatrix2x3fv: (location, addr) => {
			webgl.assertWebGL2()
			let array = webgl.mem.loadF32Array(addr, 2 * 3)
			webgl.ctx.uniformMatrix2x3fv(webgl.uniforms[location], false, array)
		},
		UniformMatrix4x3fv: (location, addr) => {
			webgl.assertWebGL2()
			let array = webgl.mem.loadF32Array(addr, 4 * 3)
			webgl.ctx.uniformMatrix4x3fv(webgl.uniforms[location], false, array)
		},
		UniformMatrix2x4fv: (location, addr) => {
			webgl.assertWebGL2()
			let array = webgl.mem.loadF32Array(addr, 2 * 4)
			webgl.ctx.uniformMatrix2x4fv(webgl.uniforms[location], false, array)
		},
		UniformMatrix3x4fv: (location, addr) => {
			webgl.assertWebGL2()
			let array = webgl.mem.loadF32Array(addr, 3 * 4)
			webgl.ctx.uniformMatrix3x4fv(webgl.uniforms[location], false, array)
		},

		/* Vertex attribs */
		VertexAttribI4i: (index, x, y, z, w) => {
			webgl.assertWebGL2()
			webgl.ctx.vertexAttribI4i(index, x, y, z, w)
		},
		VertexAttribI4ui: (index, x, y, z, w) => {
			webgl.assertWebGL2()
			webgl.ctx.vertexAttribI4ui(index, x, y, z, w)
		},
		VertexAttribIPointer: (index, size, type, stride, offset) => {
			webgl.assertWebGL2()
			webgl.ctx.vertexAttribIPointer(index, size, type, stride, offset)
		},

		/* Writing to the drawing buffer */
		VertexAttribDivisor: (index, divisor) => {
			webgl.assertWebGL2()
			webgl.ctx.vertexAttribDivisor(index, divisor)
		},
		DrawArraysInstanced: (mode, first, count, instanceCount) => {
			webgl.assertWebGL2()
			webgl.ctx.drawArraysInstanced(mode, first, count, instanceCount)
		},
		DrawElementsInstanced: (mode, count, type, offset, instanceCount) => {
			webgl.assertWebGL2()
			webgl.ctx.drawElementsInstanced(mode, count, type, offset, instanceCount)
		},
		DrawRangeElements: (mode, start, end, count, type, offset) => {
			webgl.assertWebGL2()
			webgl.ctx.drawRangeElements(mode, start, end, count, type, offset)
		},

		/* Multiple Render Targets */
		DrawBuffers: (buffers_ptr, buffers_len) => {
			webgl.assertWebGL2()
			let array = webgl.mem.loadU32Array(buffers_ptr, buffers_len)
			webgl.ctx.drawBuffers(array)
		},
		ClearBufferfv: (buffer, drawbuffer, values_ptr, values_len) => {
			webgl.assertWebGL2()
			let array = webgl.mem.loadF32Array(values_ptr, values_len)
			webgl.ctx.clearBufferfv(buffer, drawbuffer, array)
		},
		ClearBufferiv: (buffer, drawbuffer, values_ptr, values_len) => {
			webgl.assertWebGL2()
			let array = webgl.mem.loadI32Array(values_ptr, values_len)
			webgl.ctx.clearBufferiv(buffer, drawbuffer, array)
		},
		ClearBufferuiv: (buffer, drawbuffer, values_ptr, values_len) => {
			webgl.assertWebGL2()
			let array = webgl.mem.loadU32Array(values_ptr, values_len)
			webgl.ctx.clearBufferuiv(buffer, drawbuffer, array)
		},
		ClearBufferfi: (buffer, drawbuffer, depth, stencil) => {
			webgl.assertWebGL2()
			webgl.ctx.clearBufferfi(buffer, drawbuffer, depth, stencil)
		},

		/* Query Objects */
		CreateQuery: () => {
			webgl.assertWebGL2()
			let query = webgl.ctx.createQuery()
			let id = getNewId(webgl, webgl.queries)
			query.name = id
			webgl.queries[id] = query
			return id
		},
		DeleteQuery: id => {
			webgl.assertWebGL2()
			let obj = webgl.querys[id]
			if (obj && id != 0) {
				webgl.ctx.deleteQuery(obj)
				webgl.querys[id] = null
			}
		},
		IsQuery: query => {
			webgl.assertWebGL2()
			return webgl.ctx.isQuery(webgl.queries[query])
		},
		BeginQuery: (target, query) => {
			webgl.assertWebGL2()
			webgl.ctx.beginQuery(target, webgl.queries[query])
		},
		EndQuery: target => {
			webgl.assertWebGL2()
			webgl.ctx.endQuery(target)
		},
		GetQuery: (target, pname) => {
			webgl.assertWebGL2()
			let query = webgl.ctx.getQuery(target, pname)
			if (!query) {
				return 0
			}
			if (webgl.queries.indexOf(query) !== -1) {
				return query.name
			}
			let id = getNewId(webgl, webgl.queries)
			query.name = id
			webgl.queries[id] = query
			return id
		},

		/* Sampler Objects */
		CreateSampler: () => {
			webgl.assertWebGL2()
			let sampler = webgl.ctx.createSampler()
			let id = getNewId(webgl, webgl.samplers)
			sampler.name = id
			webgl.samplers[id] = sampler
			return id
		},
		DeleteSampler: id => {
			webgl.assertWebGL2()
			let obj = webgl.samplers[id]
			if (obj && id != 0) {
				webgl.ctx.deleteSampler(obj)
				webgl.samplers[id] = null
			}
		},
		IsSampler: sampler => {
			webgl.assertWebGL2()
			return webgl.ctx.isSampler(webgl.samplers[sampler])
		},
		BindSampler: (unit, sampler) => {
			webgl.assertWebGL2()
			webgl.ctx.bindSampler(unit, webgl.samplers[Sampler])
		},
		SamplerParameteri: (sampler, pname, param) => {
			webgl.assertWebGL2()
			webgl.ctx.samplerParameteri(webgl.samplers[sampler], pname, param)
		},
		SamplerParameterf: (sampler, pname, param) => {
			webgl.assertWebGL2()
			webgl.ctx.samplerParameterf(webgl.samplers[sampler], pname, param)
		},

		/* Sync objects */
		FenceSync: (condition, flags) => {
			webgl.assertWebGL2()
			let sync = webgl.ctx.fenceSync(condition, flags)
			let id = getNewId(webgl, webgl.syncs)
			sync.name = id
			webgl.syncs[id] = sync
			return id
		},
		IsSync: sync => {
			webgl.assertWebGL2()
			return webgl.ctx.isSync(webgl.syncs[sync])
		},
		DeleteSync: id => {
			webgl.assertWebGL2()
			let obj = webgl.syncs[id]
			if (obj && id != 0) {
				webgl.ctx.deleteSampler(obj)
				webgl.syncs[id] = null
			}
		},
		ClientWaitSync: (sync, flags, timeout) => {
			webgl.assertWebGL2()
			return webgl.ctx.clientWaitSync(webgl.syncs[sync], flags, timeout)
		},
		WaitSync: (sync, flags, timeout) => {
			webgl.assertWebGL2()
			webgl.ctx.waitSync(webgl.syncs[sync], flags, timeout)
		},

		/* Transform Feedback */
		CreateTransformFeedback: () => {
			webgl.assertWebGL2()
			let transformFeedback = webgl.ctx.createtransformFeedback()
			let id = getNewId(webgl, webgl.transformFeedbacks)
			transformFeedback.name = id
			webgl.transformFeedbacks[id] = transformFeedback
			return id
		},
		DeleteTransformFeedback: id => {
			webgl.assertWebGL2()
			let obj = webgl.transformFeedbacks[id]
			if (obj && id != 0) {
				webgl.ctx.deleteTransformFeedback(obj)
				webgl.transformFeedbacks[id] = null
			}
		},
		IsTransformFeedback: tf => {
			webgl.assertWebGL2()
			return webgl.ctx.isTransformFeedback(webgl.transformFeedbacks[tf])
		},
		BindTransformFeedback: (target, tf) => {
			webgl.assertWebGL2()
			webgl.ctx.bindTransformFeedback(target, webgl.transformFeedbacks[tf])
		},
		BeginTransformFeedback: primitiveMode => {
			webgl.assertWebGL2()
			webgl.ctx.beginTransformFeedback(primitiveMode)
		},
		EndTransformFeedback: () => {
			webgl.assertWebGL2()
			webgl.ctx.endTransformFeedback()
		},
		TransformFeedbackVaryings: (program, varyings_ptr, varyings_len, bufferMode) => {
			webgl.assertWebGL2()
			let varyings = []
			for (let i = 0; i < varyings_len; i++) {
				let ptr = webgl.mem.loadPtr(varyings_ptr + i * STRING_SIZE + 0 * 4)
				let len = webgl.mem.loadPtr(varyings_ptr + i * STRING_SIZE + 1 * 4)
				varyings.push(webgl.mem.loadString(ptr, len))
			}
			webgl.ctx.transformFeedbackVaryings(webgl.programs[program], varyings, bufferMode)
		},
		PauseTransformFeedback: () => {
			webgl.assertWebGL2()
			webgl.ctx.pauseTransformFeedback()
		},
		ResumeTransformFeedback: () => {
			webgl.assertWebGL2()
			webgl.ctx.resumeTransformFeedback()
		},

		/* Uniform Buffer Objects and Transform Feedback Buffers */
		BindBufferBase: (target, index, buffer) => {
			webgl.assertWebGL2()
			webgl.ctx.bindBufferBase(target, index, webgl.buffers[buffer])
		},
		BindBufferRange: (target, index, buffer, offset, size) => {
			webgl.assertWebGL2()
			webgl.ctx.bindBufferRange(target, index, webgl.buffers[buffer], offset, size)
		},
		GetUniformBlockIndex: (program, uniformBlockName_ptr, uniformBlockName_len) => {
			webgl.assertWebGL2()
			return webgl.ctx.getUniformBlockIndex(
				webgl.programs[program],
				webgl.mem.loadString(uniformBlockName_ptr, uniformBlockName_len),
			)
		},
		// any getActiveUniformBlockParameter(WebGLProgram program, GLuint uniformBlockIndex, GLenum pname);
		GetActiveUniformBlockName: (program, uniformBlockIndex, buf_ptr, buf_len, length_ptr) => {
			webgl.assertWebGL2()
			let name = webgl.ctx.getActiveUniformBlockName(
				webgl.programs[program],
				uniformBlockIndex,
			)

			let n = Math.min(buf_len, name.length)
			name = name.substring(0, n)
			webgl.mem.loadBytes(buf_ptr, buf_len).set(new TextEncoder().encode(name))
			webgl.mem.storeInt(length_ptr, n)
		},
		UniformBlockBinding: (program, uniformBlockIndex, uniformBlockBinding) => {
			webgl.assertWebGL2()
			webgl.ctx.uniformBlockBinding(
				webgl.programs[program],
				uniformBlockIndex,
				uniformBlockBinding,
			)
		},

		/* Vertex Array Objects */
		CreateVertexArray: () => {
			webgl.assertWebGL2()
			let vao = webgl.ctx.createVertexArray()
			let id = getNewId(webgl, webgl.vaos)
			vao.name = id
			webgl.vaos[id] = vao
			return id
		},
		DeleteVertexArray: id => {
			webgl.assertWebGL2()
			let obj = webgl.vaos[id]
			if (obj && id != 0) {
				webgl.ctx.deleteVertexArray(obj)
				webgl.vaos[id] = null
			}
		},
		IsVertexArray: vertexArray => {
			webgl.assertWebGL2()
			return webgl.ctx.isVertexArray(webgl.vaos[vertexArray])
		},
		BindVertexArray: vertexArray => {
			webgl.assertWebGL2()
			webgl.ctx.bindVertexArray(webgl.vaos[vertexArray])
		},
	}
}
