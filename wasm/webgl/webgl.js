import * as mem from "../memory.js"

// eslint-disable-next-line @typescript-eslint/no-unused-vars
import * as t from "./types.js"

import {
	setCurrentContext,
	EMPTY_U8_ARRAY,
	recordError,
	newId,
	populateUniformTable,
	getSource,
	INVALID_VALUE,
	INVALID_OPERATION,
} from "./interface.js"

/** @typedef{import("../types.js").WasmState}WasmInstance */

/**
 * @param   {t.WebGLState} webgl
 * @param   {WasmInstance} wasm
 * @returns       WebGL bindings for Odin.
 */
export function makeOdinWebGL(webgl, wasm) {
	return {
		/**
		 * @param   {number}  name_ptr
		 * @param   {number}  name_len
		 * @returns {boolean}
		 */
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
		 * @param   {number}  name_ptr ElementId
		 * @param   {number}  name_len
		 * @param   {number}  attrs    Bitset
		 * @returns {boolean}
		 */
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
		/** @returns {number} */
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
		/** @returns {number} */
		DrawingBufferWidth: () => webgl.ctx.drawingBufferWidth,
		/** @returns {number} */
		DrawingBufferHeight: () => webgl.ctx.drawingBufferHeight,
		/**
		 * @param   {number}  name_ptr ExtensionName
		 * @param   {number}  name_len
		 * @returns {boolean}
		 */
		IsExtensionSupported: (name_ptr, name_len) => {
			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			const extensions = webgl.ctx.getSupportedExtensions()
			return extensions ? extensions.indexOf(name) !== -1 : false
		},
		/** @returns {number} */
		GetError: () => {
			if (webgl.last_error) {
				const err = webgl.last_error
				webgl.last_error = 0
				return err
			}
			return webgl.ctx.getError()
		},
		/**
		 * @param   {number} major_ptr
		 * @param   {number} minor_ptr
		 * @returns {void}
		 */
		GetWebGLVersion: (major_ptr, minor_ptr) => {
			const data = new DataView(wasm.memory.buffer)
			mem.store_i32(data, major_ptr, webgl.version)
			mem.store_i32(data, minor_ptr, 0)
		},
		/**
		 * @param   {number} major_ptr
		 * @param   {number} minor_ptr
		 * @returns {void}
		 */
		GetESVersion: (major_ptr, minor_ptr) => {
			const major =
				webgl.ctx.getParameter(0x1f02 /*VERSION*/).indexOf("OpenGL ES 3.0") !== -1 ? 3 : 2
			const data = new DataView(wasm.memory.buffer)
			mem.store_i32(data, major_ptr, major)
			mem.store_i32(data, minor_ptr, 0)
		},
		/**
		 * @param   {number} texture
		 * @returns {void}
		 */
		ActiveTexture: texture => {
			webgl.ctx.activeTexture(texture)
		},
		/** @returns {void} */
		AttachShader: (/** @type {number} */ program, /** @type {number} */ shader) => {
			webgl.ctx.attachShader(
				/** @type {WebGLProgram} */ (webgl.programs[program]),
				/** @type {WebGLShader} */ (webgl.shaders[shader]),
			)
		},
		/**
		 * @param   {number} program
		 * @param   {number} index
		 * @param   {number} name_ptr
		 * @param   {number} name_len
		 * @returns {void}
		 */
		BindAttribLocation: (program, index, name_ptr, name_len) => {
			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			webgl.ctx.bindAttribLocation(
				/** @type {WebGLProgram} */ (webgl.programs[program]),
				index,
				name,
			)
		},
		/**
		 * @param   {number} target
		 * @param   {number} buffer
		 * @returns {void}
		 */
		BindBuffer: (target, buffer) => {
			/*
			https://gist.github.com/floooh/ae2250dce2dfd700eb959b802d7d247a#file-clear-emsc-js-L985
			*/

			if (target === 0x88eb /*GL_PIXEL_PACK_BUFFER*/) {
				/*
				In WebGL 2 glReadPixels entry point,
				we need to use a different WebGL 2 API function call
				when a buffer is bound to GL_PIXEL_PACK_BUFFER_BINDING point,
				so must keep track whether that binding point is non-null
				to know what is the proper API function to call.
				*/
				// @ts-expect-error
				webgl.ctx.currentPixelPackBufferBinding = buffer
			} else if (target === 0x88ec /*GL_PIXEL_UNPACK_BUFFER*/) {
				/*
				In WebGL 2 gl(Compressed)Tex(Sub)Image[23]D entry points,
				we need to use a different WebGL 2 API function call
				when a buffer is bound to GL_PIXEL_UNPACK_BUFFER_BINDING point,
				so must keep track whether that binding point is non-null
				to know what is the proper API function to call.
				*/
				// @ts-expect-error
				webgl.ctx.currentPixelUnpackBufferBinding = buffer
			}
			webgl.ctx.bindBuffer(target, webgl.buffers[buffer])
		},
		/**
		 * @param   {number} target
		 * @param   {number} framebuffer
		 * @returns {void}
		 */
		BindFramebuffer: (target, framebuffer) => {
			webgl.ctx.bindFramebuffer(target, framebuffer ? webgl.framebuffers[framebuffer] : null)
		},
		/**
		 * @param   {number} target
		 * @param   {number} texture
		 * @returns {void}
		 */
		BindTexture: (target, texture) => {
			webgl.ctx.bindTexture(target, texture ? webgl.textures[texture] : null)
		},
		/**
		 * @param   {number} r
		 * @param   {number} g
		 * @param   {number} b
		 * @param   {number} a
		 * @returns {void}
		 */
		BlendColor: (r, g, b, a) => {
			webgl.ctx.blendColor(r, g, b, a)
		},
		/**
		 * @param   {number} mode
		 * @returns {void}
		 */
		BlendEquation: mode => {
			webgl.ctx.blendEquation(mode)
		},
		/**
		 * @param   {number} sfactor
		 * @param   {number} dfactor
		 * @returns {void}
		 */
		BlendFunc: (sfactor, dfactor) => {
			webgl.ctx.blendFunc(sfactor, dfactor)
		},
		/**
		 * @param   {number} srcRGB
		 * @param   {number} dstRGB
		 * @param   {number} srcAlpha
		 * @param   {number} dstAlpha
		 * @returns {void}
		 */
		BlendFuncSeparate: (srcRGB, dstRGB, srcAlpha, dstAlpha) => {
			webgl.ctx.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha)
		},
		/**
		 * @param   {number} target
		 * @param   {number} size
		 * @param   {number} data
		 * @param   {number} usage
		 * @returns {void}
		 */
		BufferData: (target, size, data, usage) => {
			if (data) {
				webgl.ctx.bufferData(target, mem.load_bytes(wasm.memory.buffer, data, size), usage)
			} else {
				webgl.ctx.bufferData(target, size, usage)
			}
		},
		/**
		 * @param   {number} target
		 * @param   {number} offset
		 * @param   {number} size
		 * @param   {number} data
		 * @returns {void}
		 */
		BufferSubData: (target, offset, size, data) => {
			webgl.ctx.bufferSubData(
				target,
				offset,
				data ? mem.load_bytes(wasm.memory.buffer, data, size) : EMPTY_U8_ARRAY,
			)
		},
		/**
		 * @param   {number} mask
		 * @returns {void}
		 */
		Clear: mask => {
			webgl.ctx.clear(mask)
		},
		/**
		 * @param   {number} r
		 * @param   {number} g
		 * @param   {number} b
		 * @param   {number} a
		 * @returns {void}
		 */
		ClearColor: (r, g, b, a) => {
			webgl.ctx.clearColor(r, g, b, a)
		},
		/**
		 * @param   {number} depth
		 * @returns {void}
		 */
		ClearDepth: depth => {
			webgl.ctx.clearDepth(depth)
		},
		/**
		 * @param   {number} s
		 * @returns {void}
		 */
		ClearStencil: s => {
			webgl.ctx.clearStencil(s)
		},
		/**
		 * @param   {number} r
		 * @param   {number} g
		 * @param   {number} b
		 * @param   {number} a
		 * @returns {void}
		 */
		ColorMask: (r, g, b, a) => {
			webgl.ctx.colorMask(!!r, !!g, !!b, !!a)
		},
		/**
		 * @param   {number} shader
		 * @returns {void}
		 */
		CompileShader: shader => {
			webgl.ctx.compileShader(/** @type {WebGLShader} */ (webgl.shaders[shader]))
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
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ internalformat,
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ width,
			/** @type {number} */ height,
			/** @type {number} */ border,
		) => {
			webgl.ctx.copyTexImage2D(target, level, internalformat, x, y, width, height, border)
		},
		CopyTexSubImage2D: (
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ xoffset,
			/** @type {number} */ yoffset,
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ width,
			/** @type {number} */ height,
		) => {
			webgl.ctx.copyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height)
		},
		/** @returns {number} */
		CreateBuffer: () => {
			const buffer = webgl.ctx.createBuffer()
			if (!buffer) {
				recordError(webgl, INVALID_OPERATION)
				return 0
			}
			const id = newId(webgl)
			buffer.name = id
			webgl.buffers[id] = buffer
			return id
		},
		/** @returns {number} */
		CreateFramebuffer: () => {
			const buffer = webgl.ctx.createFramebuffer()
			if (!buffer) {
				recordError(webgl, INVALID_OPERATION)
				return 0
			}
			const id = newId(webgl)
			buffer.name = id
			webgl.framebuffers[id] = buffer
			return id
		},
		/** @returns {number} */
		CreateRenderbuffer: () => {
			const buffer = webgl.ctx.createRenderbuffer()
			if (!buffer) {
				recordError(webgl, INVALID_OPERATION)
				return 0
			}
			const id = newId(webgl)
			buffer.name = id
			webgl.renderbuffers[id] = buffer
			return id
		},
		/** @returns {number} */
		CreateProgram: () => {
			const program = webgl.ctx.createProgram()
			if (!program) {
				recordError(webgl, INVALID_OPERATION)
				return 0
			}
			const id = newId(webgl)
			program.name = id
			webgl.programs[id] = program
			return id
		},
		/**
		 * @param   {number} shaderType
		 * @returns {number}
		 */
		CreateShader: shaderType => {
			const shader = webgl.ctx.createShader(shaderType)
			if (!shader) {
				recordError(webgl, INVALID_OPERATION)
				return 0
			}
			const id = newId(webgl)
			shader.name = id
			webgl.shaders[id] = shader
			return id
		},
		/** @returns {number} */
		CreateTexture: () => {
			const texture = webgl.ctx.createTexture()
			if (!texture) {
				recordError(webgl, INVALID_OPERATION)
				return 0
			}
			const id = newId(webgl)
			texture.name = id
			webgl.textures[id] = texture
			return id
		},
		/**
		 * @param   {number} mode
		 * @returns {void}
		 */
		CullFace: mode => {
			webgl.ctx.cullFace(mode)
		},
		/**
		 * @param   {number} id
		 * @returns {void}
		 */
		DeleteBuffer: id => {
			if (id === 0) return

			const obj = webgl.buffers[id]
			if (obj) {
				webgl.ctx.deleteBuffer(obj)
				webgl.buffers[id] = null
			}
		},
		/**
		 * @param   {number} id
		 * @returns {void}
		 */
		DeleteFramebuffer: id => {
			if (id === 0) return

			const obj = webgl.framebuffers[id]
			if (obj) {
				webgl.ctx.deleteFramebuffer(obj)
				webgl.framebuffers[id] = null
			}
		},
		/**
		 * @param   {number} id
		 * @returns {void}
		 */
		DeleteProgram: id => {
			if (id === 0) return

			const obj = webgl.programs[id]
			if (obj) {
				webgl.ctx.deleteProgram(obj)
				webgl.programs[id] = null
			}
		},
		/**
		 * @param   {number} id
		 * @returns {void}
		 */
		DeleteRenderbuffer: id => {
			if (id === 0) return

			const obj = webgl.renderbuffers[id]
			if (obj) {
				webgl.ctx.deleteRenderbuffer(obj)
				webgl.renderbuffers[id] = null
			}
		},
		/**
		 * @param   {number} id
		 * @returns {void}
		 */
		DeleteShader: id => {
			if (id === 0) return

			const obj = webgl.shaders[id]
			if (obj) {
				webgl.ctx.deleteShader(obj)
				webgl.shaders[id] = null
			}
		},
		/**
		 * @param   {number} id
		 * @returns {void}
		 */
		DeleteTexture: id => {
			if (id === 0) return

			const obj = webgl.textures[id]
			if (obj) {
				webgl.ctx.deleteTexture(obj)
				webgl.textures[id] = null
			}
		},
		/**
		 * @param   {number} func
		 * @returns {void}
		 */
		DepthFunc: func => {
			webgl.ctx.depthFunc(func)
		},
		/**
		 * @param   {boolean} flag
		 * @returns {void}
		 */
		DepthMask: flag => {
			webgl.ctx.depthMask(flag)
		},
		/**
		 * @param   {number} zNear
		 * @param   {number} zFar
		 * @returns {void}
		 */
		DepthRange: (zNear, zFar) => {
			webgl.ctx.depthRange(zNear, zFar)
		},
		/**
		 * @param   {number} program
		 * @param   {number} shader
		 * @returns {void}
		 */
		DetachShader: (program, shader) => {
			webgl.ctx.detachShader(
				/** @type {WebGLProgram} */ (webgl.programs[program]),
				/** @type {WebGLShader} */ (webgl.shaders[shader]),
			)
		},
		/**
		 * @param   {number} cap
		 * @returns {void}
		 */
		Disable: cap => {
			webgl.ctx.disable(cap)
		},
		/**
		 * @param   {number} index
		 * @returns {void}
		 */
		DisableVertexAttribArray: index => {
			webgl.ctx.disableVertexAttribArray(index)
		},
		/** @returns {void} */
		DrawArrays: (
			/** @type {number} */ mode,
			/** @type {number} */ first,
			/** @type {number} */ count,
		) => {
			webgl.ctx.drawArrays(mode, first, count)
		},
		/** @returns {void} */
		DrawElements: (
			/** @type {number} */ mode,
			/** @type {number} */ count,
			/** @type {number} */ type,
			/** @type {number} */ indices,
		) => {
			webgl.ctx.drawElements(mode, count, type, indices)
		},
		/**
		 * @param   {number} cap
		 * @returns {void}
		 */
		Enable: cap => {
			webgl.ctx.enable(cap)
		},
		/**
		 * @param   {number} index
		 * @returns {void}
		 */
		EnableVertexAttribArray: index => {
			webgl.ctx.enableVertexAttribArray(index)
		},
		/** @returns {void} */
		Finish: () => {
			webgl.ctx.finish()
		},
		/** @returns {void} */
		Flush: () => {
			webgl.ctx.flush()
		},
		/**
		 * @param   {number} target
		 * @param   {number} attachment
		 * @param   {number} renderbuffertarget
		 * @param   {number} renderbuffer
		 * @returns {void}
		 */
		FramebufferRenderbuffer: (target, attachment, renderbuffertarget, renderbuffer) => {
			webgl.ctx.framebufferRenderbuffer(
				target,
				attachment,
				renderbuffertarget,
				webgl.renderbuffers[renderbuffer],
			)
		},
		/**
		 * @param   {number} target
		 * @param   {number} attachment
		 * @param   {number} textarget
		 * @param   {number} texture
		 * @param   {number} level
		 * @returns {void}
		 */
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
		 * @param   {number} mode
		 * @returns {void}
		 */
		FrontFace: mode => {
			webgl.ctx.frontFace(mode)
		},
		/**
		 * @param   {number} target
		 * @returns {void}
		 */
		GenerateMipmap: target => {
			webgl.ctx.generateMipmap(target)
		},
		/**
		 * @param   {number} program
		 * @param   {number} name_ptr
		 * @param   {number} name_len
		 * @returns {number}
		 */
		GetAttribLocation: (program, name_ptr, name_len) => {
			const name = mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len)
			return webgl.ctx.getAttribLocation(
				/** @type {WebGLProgram} */ (webgl.programs[program]),
				name,
			)
		},
		/**
		 * @param   {number} pname
		 * @returns {number}
		 */
		GetParameter: pname => {
			return webgl.ctx.getParameter(pname)
		},
		/**
		 * @param   {number} program
		 * @param   {number} pname
		 * @returns {number}
		 */
		GetProgramParameter: (program, pname) => {
			return webgl.ctx.getProgramParameter(
				/** @type {WebGLProgram} */ (webgl.programs[program]),
				pname,
			)
		},
		/**
		 * @param   {number} program
		 * @param   {number} buf_ptr
		 * @param   {number} buf_len
		 * @param   {number} length_ptr
		 * @returns {void}
		 */
		GetProgramInfoLog: (program, buf_ptr, buf_len, length_ptr) => {
			if (buf_len <= 0 || !buf_ptr) return

			const log =
				webgl.ctx.getProgramInfoLog(
					/** @type {WebGLProgram} */ (webgl.programs[program]),
				) ?? "(unknown error)"
			const n = mem.store_string_raw(wasm.memory.buffer, buf_ptr, buf_len, log)
			mem.store_int(new DataView(wasm.memory.buffer), length_ptr, n)
		},
		/**
		 * @param   {number} shader
		 * @param   {number} buf_ptr
		 * @param   {number} buf_len
		 * @param   {number} length_ptr
		 * @returns {void}
		 */
		GetShaderInfoLog: (shader, buf_ptr, buf_len, length_ptr) => {
			if (buf_len <= 0 || !buf_ptr) return

			const log =
				webgl.ctx.getShaderInfoLog(/** @type {WebGLShader} */ (webgl.shaders[shader])) ??
				"(unknown error)"
			const n = mem.store_string_raw(wasm.memory.buffer, buf_ptr, buf_len, log)
			mem.store_int(new DataView(wasm.memory.buffer), length_ptr, n)
		},
		/**
		 * @param   {number} shader_id
		 * @param   {number} pname
		 * @param   {number} p
		 * @returns {void}
		 */
		GetShaderiv: (shader_id, pname, p) => {
			if (!p) {
				recordError(webgl, INVALID_VALUE)
				return
			}

			const shader = webgl.shaders[shader_id]
			if (!shader) {
				recordError(webgl, INVALID_VALUE)
				return
			}

			const data = new DataView(wasm.memory.buffer)

			switch (pname) {
				case 0x8b84: {
					const log = webgl.ctx.getShaderInfoLog(shader) ?? "(unknown error)"
					mem.store_int(data, p, log.length + 1)
					break
				}
				case 0x8b88: {
					const source = webgl.ctx.getShaderSource(shader)
					const sourceLength =
						source === null || source.length === 0 ? 0 : source.length + 1
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
		 * @param   {number} program
		 * @param   {number} name_ptr
		 * @param   {number} name_len
		 * @returns {number}
		 */
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

			const ptable = webgl.program_infos[program]
			if (!ptable) return -1

			const uniform_info = ptable.uniforms[name]
			return uniform_info && array_offset < uniform_info[0]
				? uniform_info[1] + array_offset
				: -1
		},
		/**
		 * @param   {number} index
		 * @param   {number} pname
		 * @returns {number}
		 */
		GetVertexAttribOffset: (index, pname) => {
			return webgl.ctx.getVertexAttribOffset(index, pname)
		},
		/**
		 * @param   {number} target
		 * @param   {number} mode
		 * @returns {void}
		 */
		Hint: (target, mode) => {
			webgl.ctx.hint(target, mode)
		},
		/**
		 * @param   {number}  buffer
		 * @returns {boolean}
		 */
		IsBuffer: buffer => webgl.ctx.isBuffer(webgl.buffers[buffer]),
		/**
		 * @param   {number}  cap
		 * @returns {boolean}
		 */
		IsEnabled: cap => webgl.ctx.isEnabled(cap),
		/**
		 * @param   {number}  framebuffer
		 * @returns {boolean}
		 */
		IsFramebuffer: framebuffer => webgl.ctx.isFramebuffer(webgl.framebuffers[framebuffer]),
		/**
		 * @param   {number}  program
		 * @returns {boolean}
		 */
		IsProgram: program => webgl.ctx.isProgram(webgl.programs[program]),
		/**
		 * @param   {number}  renderbuffer
		 * @returns {boolean}
		 */
		IsRenderbuffer: renderbuffer => webgl.ctx.isRenderbuffer(webgl.renderbuffers[renderbuffer]),
		/**
		 * @param   {number}  shader
		 * @returns {boolean}
		 */
		IsShader: shader => webgl.ctx.isShader(webgl.shaders[shader]),
		/**
		 * @param   {number}  texture
		 * @returns {boolean}
		 */
		IsTexture: texture => webgl.ctx.isTexture(webgl.textures[texture]),
		/** @param{number}width */
		LineWidth: width => {
			webgl.ctx.lineWidth(width)
		},
		/**
		 * @param   {number} program
		 * @returns {void}
		 */
		LinkProgram: program => {
			webgl.ctx.linkProgram(/** @type {WebGLProgram} */ (webgl.programs[program]))
			webgl.program_infos[program] = null
			populateUniformTable(webgl, program)
		},
		/**
		 * @param   {number} pname
		 * @param   {number} param
		 * @returns {void}
		 */
		PixelStorei: (pname, param) => {
			webgl.ctx.pixelStorei(pname, param)
		},
		/**
		 * @param   {number} factor
		 * @param   {number} units
		 * @returns {void}
		 */
		PolygonOffset: (factor, units) => {
			webgl.ctx.polygonOffset(factor, units)
		},
		/**
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} width
		 * @param   {number} height
		 * @param   {number} format
		 * @param   {number} type
		 * @param   {number} data_len
		 * @param   {number} data_ptr
		 * @returns {void}
		 */
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
		 * @param   {number} target
		 * @param   {number} internalformat
		 * @param   {number} width
		 * @param   {number} height
		 * @returns {void}
		 */
		RenderbufferStorage: (target, internalformat, width, height) => {
			webgl.ctx.renderbufferStorage(target, internalformat, width, height)
		},
		/**
		 * @param   {number}  value
		 * @param   {boolean} invert
		 * @returns {void}
		 */
		SampleCoverage: (value, invert) => {
			webgl.ctx.sampleCoverage(value, invert)
		},
		/**
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} width
		 * @param   {number} height
		 * @returns {void}
		 */
		Scissor: (x, y, width, height) => {
			webgl.ctx.scissor(x, y, width, height)
		},
		/**
		 * @param   {number} shader
		 * @param   {number} strings_ptr
		 * @param   {number} strings_length
		 * @returns {void}
		 */
		ShaderSource: (shader, strings_ptr, strings_length) => {
			const source = getSource(wasm.memory.buffer, strings_ptr, strings_length)
			webgl.ctx.shaderSource(/** @type {WebGLShader} */ (webgl.shaders[shader]), source)
		},
		/**
		 * @param   {number} func
		 * @param   {number} ref
		 * @param   {number} mask
		 * @returns {void}
		 */
		StencilFunc: (func, ref, mask) => {
			webgl.ctx.stencilFunc(func, ref, mask)
		},
		/**
		 * @param   {number} face
		 * @param   {number} func
		 * @param   {number} ref
		 * @param   {number} mask
		 * @returns {void}
		 */
		StencilFuncSeparate: (face, func, ref, mask) => {
			webgl.ctx.stencilFuncSeparate(face, func, ref, mask)
		},
		/**
		 * @param   {number} mask
		 * @returns {void}
		 */
		StencilMask: mask => {
			webgl.ctx.stencilMask(mask)
		},
		/**
		 * @param   {number} face
		 * @param   {number} mask
		 * @returns {void}
		 */
		StencilMaskSeparate: (face, mask) => {
			webgl.ctx.stencilMaskSeparate(face, mask)
		},
		/**
		 * @param   {number} fail
		 * @param   {number} zfail
		 * @param   {number} zpass
		 * @returns {void}
		 */
		StencilOp: (fail, zfail, zpass) => {
			webgl.ctx.stencilOp(fail, zfail, zpass)
		},
		/**
		 * @param   {number} face
		 * @param   {number} fail
		 * @param   {number} zfail
		 * @param   {number} zpass
		 * @returns {void}
		 */
		StencilOpSeparate: (face, fail, zfail, zpass) => {
			webgl.ctx.stencilOpSeparate(face, fail, zfail, zpass)
		},
		TexImage2D: (
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ internalformat,
			/** @type {number} */ width,
			/** @type {number} */ height,
			/** @type {number} */ border,
			/** @type {number} */ format,
			/** @type {number} */ type,
			/** @type {number} */ size,
			/** @type {number} */ data,
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
		 * @param   {number} target
		 * @param   {number} pname
		 * @param   {number} param
		 * @returns {void}
		 */
		TexParameterf: (target, pname, param) => {
			webgl.ctx.texParameterf(target, pname, param)
		},
		/**
		 * @param   {number} target
		 * @param   {number} pname
		 * @param   {number} param
		 * @returns {void}
		 */
		TexParameteri: (target, pname, param) => {
			webgl.ctx.texParameteri(target, pname, param)
		},
		TexSubImage2D: (
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ xoffset,
			/** @type {number} */ yoffset,
			/** @type {number} */ width,
			/** @type {number} */ height,
			/** @type {number} */ format,
			/** @type {number} */ type,
			/** @type {number} */ size,
			/** @type {number} */ data,
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
		 * @param   {number} location
		 * @param   {number} x
		 * @returns {void}
		 */
		Uniform1f: (location, x) => {
			webgl.ctx.uniform1f(webgl.uniforms[location], x)
		},
		/**
		 * @param   {number} location
		 * @param   {number} x
		 * @param   {number} y
		 * @returns {void}
		 */
		Uniform2f: (location, x, y) => {
			webgl.ctx.uniform2f(webgl.uniforms[location], x, y)
		},
		/**
		 * @param   {number} location
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} z
		 * @returns {void}
		 */
		Uniform3f: (location, x, y, z) => {
			webgl.ctx.uniform3f(webgl.uniforms[location], x, y, z)
		},
		/**
		 * @param   {number} location
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} z
		 * @param   {number} w
		 * @returns {void}
		 */
		Uniform4f: (location, x, y, z, w) => {
			webgl.ctx.uniform4f(webgl.uniforms[location], x, y, z, w)
		},
		/**
		 * @param   {number} location
		 * @param   {number} x
		 * @returns {void}
		 */
		Uniform1i: (location, x) => {
			webgl.ctx.uniform1i(webgl.uniforms[location], x)
		},
		/**
		 * @param   {number} location
		 * @param   {number} x
		 * @param   {number} y
		 * @returns {void}
		 */
		Uniform2i: (location, x, y) => {
			webgl.ctx.uniform2i(webgl.uniforms[location], x, y)
		},
		/**
		 * @param   {number} location
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} z
		 * @returns {void}
		 */
		Uniform3i: (location, x, y, z) => {
			webgl.ctx.uniform3i(webgl.uniforms[location], x, y, z)
		},
		/**
		 * @param   {number} location
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} z
		 * @param   {number} w
		 * @returns {void}
		 */
		Uniform4i: (location, x, y, z, w) => {
			webgl.ctx.uniform4i(webgl.uniforms[location], x, y, z, w)
		},
		/**
		 * @param   {number} location
		 * @param   {number} addr
		 * @returns {void}
		 */
		UniformMatrix2fv: (location, addr) => {
			webgl.ctx.uniformMatrix2fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 2 * 2),
			)
		},
		/**
		 * @param   {number} location
		 * @param   {number} addr
		 * @returns {void}
		 */
		UniformMatrix3fv: (location, addr) => {
			webgl.ctx.uniformMatrix3fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 3 * 3),
			)
		},
		/**
		 * @param   {number} location
		 * @param   {number} addr
		 * @returns {void}
		 */
		UniformMatrix4fv: (location, addr) => {
			webgl.ctx.uniformMatrix4fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 4 * 4),
			)
		},
		/**
		 * @param   {number} program
		 * @returns {void}
		 */
		UseProgram: program => {
			webgl.ctx.useProgram(webgl.programs[program])
		},
		/**
		 * @param   {number} program
		 * @returns {void}
		 */
		ValidateProgram: program => {
			webgl.ctx.validateProgram(/** @type {WebGLProgram} */ (webgl.programs[program]))
		},
		/**
		 * @param   {number} index
		 * @param   {number} x
		 * @returns {void}
		 */
		VertexAttrib1f: (index, x) => {
			webgl.ctx.vertexAttrib1f(index, x)
		},
		/**
		 * @param   {number} index
		 * @param   {number} x
		 * @param   {number} y
		 * @returns {void}
		 */
		VertexAttrib2f: (index, x, y) => {
			webgl.ctx.vertexAttrib2f(index, x, y)
		},
		/**
		 * @param   {number} index
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} z
		 * @returns {void}
		 */
		VertexAttrib3f: (index, x, y, z) => {
			webgl.ctx.vertexAttrib3f(index, x, y, z)
		},
		/**
		 * @param   {number} index
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} z
		 * @param   {number} w
		 * @returns {void}
		 */
		VertexAttrib4f: (index, x, y, z, w) => {
			webgl.ctx.vertexAttrib4f(index, x, y, z, w)
		},
		/**
		 * @param   {number}  index
		 * @param   {number}  size
		 * @param   {number}  type
		 * @param   {boolean} normalized
		 * @param   {number}  stride
		 * @param   {number}  ptr
		 * @returns {void}
		 */
		VertexAttribPointer: (index, size, type, normalized, stride, ptr) => {
			webgl.ctx.vertexAttribPointer(index, size, type, !!normalized, stride, ptr)
		},
		/**
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} w
		 * @param   {number} h
		 * @returns {void}
		 */
		Viewport: (x, y, w, h) => {
			webgl.ctx.viewport(x, y, w, h)
		},
	}
}
