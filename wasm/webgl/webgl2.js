import * as mem from "../memory.js"

// eslint-disable-next-line @typescript-eslint/no-unused-vars
import * as t from "./types.js"

import {EMPTY_U8_ARRAY, INVALID_OPERATION, newId, recordError} from "./interface.js"

/**
 * @param {t.WebGLInterface} _webgl
 * @param {import("../types.js").WasmInstance} wasm
 * @returns WebGL 2 bindings for Odin
 */
export function makeOdinWegGL2(_webgl, wasm) {
	const webgl = /** @type {t.WebGL2Interface} */ (_webgl)

	return {
		/*
		Buffer objects
		*/

		/**
		 * @param {number} read_target
		 * @param {number} write_target
		 * @param {number} read_offset
		 * @param {number} write_offset
		 * @param {number} size
		 * @returns {void}
		 */
		CopyBufferSubData: (read_target, write_target, read_offset, write_offset, size) => {
			webgl.ctx.copyBufferSubData(read_target, write_target, read_offset, write_offset, size)
		},
		GetBufferSubData: (
			/** @type {number} */ target,
			/** @type {number} */ src_byte_offset,
			/** @type {number} */ dst_buffer_ptr,
			/** @type {number} */ dst_buffer_len,
			/** @type {number} */ dst_offset,
			/** @type {number} */ length,
		) => {
			webgl.ctx.getBufferSubData(
				target,
				src_byte_offset,
				mem.load_bytes(wasm.memory.buffer, dst_buffer_ptr, dst_buffer_len),
				dst_offset,
				length,
			)
		},

		/*
		Framebuffer objects
		*/
		BlitFramebuffer: (
			/** @type {number} */ src_x0,
			/** @type {number} */ src_y0,
			/** @type {number} */ src_x1,
			/** @type {number} */ src_y1,
			/** @type {number} */ dst_x0,
			/** @type {number} */ dst_y0,
			/** @type {number} */ dst_x1,
			/** @type {number} */ dst_y1,
			/** @type {number} */ mask,
			/** @type {number} */ filter,
		) => {
			webgl.ctx.blitFramebuffer(
				src_x0,
				src_y0,
				src_x1,
				src_y1,
				dst_x0,
				dst_y0,
				dst_x1,
				dst_y1,
				mask,
				filter,
			)
		},
		FramebufferTextureLayer: (
			/** @type {number} */ target,
			/** @type {number} */ attachment,
			/** @type {number} */ texture,
			/** @type {number} */ level,
			/** @type {number} */ layer,
		) => {
			webgl.ctx.framebufferTextureLayer(
				target,
				attachment,
				webgl.textures[texture],
				level,
				layer,
			)
		},
		InvalidateFramebuffer: (
			/** @type {number} */ target,
			/** @type {number} */ attachments_ptr,
			/** @type {number} */ attachments_len,
		) => {
			webgl.ctx.invalidateFramebuffer(
				target,
				new Uint32Array(wasm.memory.buffer, attachments_ptr, attachments_len),
			)
		},
		InvalidateSubFramebuffer: (
			/** @type {number} */ target,
			/** @type {number} */ attachments_ptr,
			/** @type {number} */ attachments_len,
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ width,
			/** @type {number} */ height,
		) => {
			webgl.ctx.invalidateSubFramebuffer(
				target,
				new Uint32Array(wasm.memory.buffer, attachments_ptr, attachments_len),
				x,
				y,
				width,
				height,
			)
		},
		/** @param {number} src */
		ReadBuffer: src => {
			webgl.ctx.readBuffer(src)
		},

		/*
		Renderbuffer objects
		*/
		RenderbufferStorageMultisample: (
			/** @type {number} */ target,
			/** @type {number} */ samples,
			/** @type {number} */ internalformat,
			/** @type {number} */ width,
			/** @type {number} */ height,
		) => {
			webgl.ctx.renderbufferStorageMultisample(target, samples, internalformat, width, height)
		},

		/*
		Texture objects
		*/
		TexStorage3D: (
			/** @type {number} */ target,
			/** @type {number} */ levels,
			/** @type {number} */ internalformat,
			/** @type {number} */ width,
			/** @type {number} */ height,
			/** @type {number} */ depth,
		) => {
			webgl.ctx.texStorage3D(target, levels, internalformat, width, height, depth)
		},
		TexImage3D: (
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ internalformat,
			/** @type {number} */ width,
			/** @type {number} */ height,
			/** @type {number} */ depth,
			/** @type {number} */ border,
			/** @type {number} */ format,
			/** @type {number} */ type,
			/** @type {number} */ size,
			/** @type {number} */ data,
		) => {
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
				data ? mem.load_bytes(wasm.memory.buffer, data, size) : null,
			)
		},
		TexSubImage3D: (
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ xoffset,
			/** @type {number} */ yoffset,
			/** @type {number} */ zoffset,
			/** @type {number} */ width,
			/** @type {number} */ height,
			/** @type {number} */ depth,
			/** @type {number} */ format,
			/** @type {number} */ type,
			/** @type {number} */ size,
			/** @type {number} */ data,
		) => {
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
				data ? mem.load_bytes(wasm.memory.buffer, data, size) : null,
			)
		},
		CompressedTexImage3D: (
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ internalformat,
			/** @type {number} */ width,
			/** @type {number} */ height,
			/** @type {number} */ depth,
			/** @type {number} */ border,
			/** @type {number} */ imageSize,
			/** @type {number} */ data,
		) => {
			webgl.ctx.compressedTexImage3D(
				target,
				level,
				internalformat,
				width,
				height,
				depth,
				border,
				data ? mem.load_bytes(wasm.memory.buffer, data, imageSize) : EMPTY_U8_ARRAY,
			)
		},
		CompressedTexSubImage3D: (
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ xoffset,
			/** @type {number} */ yoffset,
			/** @type {number} */ zoffset,
			/** @type {number} */ width,
			/** @type {number} */ height,
			/** @type {number} */ depth,
			/** @type {number} */ format,
			/** @type {number} */ imageSize,
			/** @type {number} */ data,
		) => {
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
				data ? mem.load_bytes(wasm.memory.buffer, data, imageSize) : EMPTY_U8_ARRAY,
			)
		},
		CopyTexSubImage3D: (
			/** @type {number} */ target,
			/** @type {number} */ level,
			/** @type {number} */ xoffset,
			/** @type {number} */ yoffset,
			/** @type {number} */ zoffset,
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ width,
			/** @type {number} */ height,
		) => {
			webgl.ctx.copyTexSubImage3D(
				target,
				level,
				xoffset,
				yoffset,
				zoffset,
				x,
				y,
				width,
				height,
			)
		},

		/* Programs and shaders */
		GetFragDataLocation: (
			/** @type {number} */ program,
			/** @type {number} */ name_ptr,
			/** @type {number} */ name_len,
		) => {
			return webgl.ctx.getFragDataLocation(
				webgl.programs[program],
				mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len),
			)
		},

		/* Uniforms */
		/**
		 * @param {number} location
		 * @param {number} x
		 * @returns {void}
		 */
		Uniform1ui: (location, x) => {
			webgl.ctx.uniform1ui(webgl.uniforms[location], x)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @param {number} y
		 * @returns {void}
		 */
		Uniform2ui: (location, x, y) => {
			webgl.ctx.uniform2ui(webgl.uniforms[location], x, y)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @param {number} y
		 * @param {number} z
		 * @returns {void}
		 */
		Uniform3ui: (location, x, y, z) => {
			webgl.ctx.uniform3ui(webgl.uniforms[location], x, y, z)
		},
		/**
		 * @param {number} location
		 * @param {number} x
		 * @param {number} y
		 * @param {number} z
		 * @param {number} w
		 * @returns {void}
		 */
		Uniform4ui: (location, x, y, z, w) => {
			webgl.ctx.uniform4ui(webgl.uniforms[location], x, y, z, w)
		},
		/**
		 * @param {number} location
		 * @param {number} addr
		 * @returns {void}
		 */
		UniformMatrix3x2fv: (location, addr) => {
			webgl.ctx.uniformMatrix3x2fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 3 * 2),
			)
		},
		/**
		 * @param {number} location
		 * @param {number} addr
		 * @returns {void}
		 */
		UniformMatrix4x2fv: (location, addr) => {
			webgl.ctx.uniformMatrix4x2fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 4 * 2),
			)
		},
		/**
		 * @param {number} location
		 * @param {number} addr
		 * @returns {void}
		 */
		UniformMatrix2x3fv: (location, addr) => {
			webgl.ctx.uniformMatrix2x3fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 2 * 3),
			)
		},
		/**
		 * @param {number} location
		 * @param {number} addr
		 * @returns {void}
		 */
		UniformMatrix4x3fv: (location, addr) => {
			webgl.ctx.uniformMatrix4x3fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 4 * 3),
			)
		},
		/**
		 * @param {number} location
		 * @param {number} addr
		 * @returns {void}
		 */
		UniformMatrix2x4fv: (location, addr) => {
			webgl.ctx.uniformMatrix2x4fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 2 * 4),
			)
		},
		/**
		 * @param {number} location
		 * @param {number} addr
		 * @returns {void}
		 */
		UniformMatrix3x4fv: (location, addr) => {
			webgl.ctx.uniformMatrix3x4fv(
				webgl.uniforms[location],
				false,
				new Float32Array(wasm.memory.buffer, addr, 3 * 4),
			)
		},

		/*
		Vertex attribs
		*/

		VertexAttribI4i: (
			/** @type {number} */ index,
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ z,
			/** @type {number} */ w,
		) => {
			webgl.ctx.vertexAttribI4i(index, x, y, z, w)
		},
		VertexAttribI4ui: (
			/** @type {number} */ index,
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ z,
			/** @type {number} */ w,
		) => {
			webgl.ctx.vertexAttribI4ui(index, x, y, z, w)
		},
		VertexAttribIPointer: (
			/** @type {number} */ index,
			/** @type {number} */ size,
			/** @type {number} */ type,
			/** @type {number} */ stride,
			/** @type {number} */ offset,
		) => {
			webgl.ctx.vertexAttribIPointer(index, size, type, stride, offset)
		},

		/* Writing to the drawing buffer */
		VertexAttribDivisor: (/** @type {number} */ index, /** @type {number} */ divisor) => {
			webgl.ctx.vertexAttribDivisor(index, divisor)
		},
		DrawArraysInstanced: (
			/** @type {number} */ mode,
			/** @type {number} */ first,
			/** @type {number} */ count,
			/** @type {number} */ instance_count,
		) => {
			webgl.ctx.drawArraysInstanced(mode, first, count, instance_count)
		},
		DrawElementsInstanced: (
			/** @type {number} */ mode,
			/** @type {number} */ count,
			/** @type {number} */ type,
			/** @type {number} */ offset,
			/** @type {number} */ instance_count,
		) => {
			webgl.ctx.drawElementsInstanced(mode, count, type, offset, instance_count)
		},
		DrawRangeElements: (
			/** @type {number} */ mode,
			/** @type {number} */ start,
			/** @type {number} */ end,
			/** @type {number} */ count,
			/** @type {number} */ type,
			/** @type {number} */ offset,
		) => {
			webgl.ctx.drawRangeElements(mode, start, end, count, type, offset)
		},

		/* Multiple Render Targets */
		DrawBuffers: (/** @type {number} */ buffers_ptr, /** @type {number} */ buffers_len) => {
			webgl.ctx.drawBuffers(mem.load_u32_array(wasm.memory.buffer, buffers_ptr, buffers_len))
		},
		ClearBufferfv: (
			/** @type {number} */ buffer,
			/** @type {number} */ drawbuffer,
			/** @type {number} */ values_ptr,
			/** @type {number} */ values_len,
		) => {
			webgl.ctx.clearBufferfv(
				buffer,
				drawbuffer,
				mem.load_f32_array(wasm.memory.buffer, values_ptr, values_len),
			)
		},
		ClearBufferiv: (
			/** @type {number} */ buffer,
			/** @type {number} */ drawbuffer,
			/** @type {number} */ values_ptr,
			/** @type {number} */ values_len,
		) => {
			webgl.ctx.clearBufferiv(
				buffer,
				drawbuffer,
				mem.load_i32_array(wasm.memory.buffer, values_ptr, values_len),
			)
		},
		ClearBufferuiv: (
			/** @type {number} */ buffer,
			/** @type {number} */ drawbuffer,
			/** @type {number} */ values_ptr,
			/** @type {number} */ values_len,
		) => {
			webgl.ctx.clearBufferuiv(
				buffer,
				drawbuffer,
				mem.load_u32_array(wasm.memory.buffer, values_ptr, values_len),
			)
		},
		ClearBufferfi: (
			/** @type {number} */ buffer,
			/** @type {number} */ drawbuffer,
			/** @type {number} */ depth,
			/** @type {number} */ stencil,
		) => {
			webgl.ctx.clearBufferfi(buffer, drawbuffer, depth, stencil)
		},

		/*
		Query Objects
		*/

		/** @returns {number} */
		CreateQuery: () => {
			const query = webgl.ctx.createQuery()
			if (!query) {
				recordError(webgl, INVALID_OPERATION)
				return 0
			}

			const id = newId(webgl)
			query.name = id
			webgl.queries[id] = query
			return id
		},
		/** @param {number} id */
		DeleteQuery: id => {
			const obj = webgl.queries[id]
			if (obj && id != 0) {
				webgl.ctx.deleteQuery(obj)
				webgl.queries[id] = null
			}
		},
		/**
		 * @param {number} query
		 * @returns {boolean}
		 */
		IsQuery: query => {
			return webgl.ctx.isQuery(webgl.queries[query])
		},
		/**
		 * @param {number} target
		 * @param {number} query
		 */
		BeginQuery: (target, query) => {
			webgl.ctx.beginQuery(target, webgl.queries[query])
		},
		/** @param {number} target */
		EndQuery: target => {
			webgl.ctx.endQuery(target)
		},
		/**
		 * @param {number} target
		 * @param {number} pname
		 * @returns {number}
		 */
		GetQuery: (target, pname) => {
			const query = webgl.ctx.getQuery(target, pname)
			if (!query) return 0

			if (webgl.queries.includes(query)) {
				return query.name
			}

			const id = newId(webgl)
			query.name = id
			webgl.queries[id] = query
			return id
		},

		/*
		Sampler Objects
		*/

		/** @returns {number} */
		CreateSampler: () => {
			const sampler = webgl.ctx.createSampler()
			if (!sampler) {
				recordError(webgl, INVALID_OPERATION)
				return 0
			}

			const id = newId(webgl)
			sampler.name = id
			webgl.samplers[id] = sampler
			return id
		},
		/** @param {number} id */
		DeleteSampler: id => {
			const obj = webgl.samplers[id]
			if (obj && id != 0) {
				webgl.ctx.deleteSampler(obj)
				webgl.samplers[id] = null
			}
		},
		/**
		 * @param {number} sampler
		 * @returns {boolean}
		 */
		IsSampler: sampler => {
			return webgl.ctx.isSampler(webgl.samplers[sampler])
		},
		/**
		 * @param {number} unit
		 * @param {number} sampler
		 * @returns {void}
		 */
		BindSampler: (unit, sampler) => {
			webgl.ctx.bindSampler(unit, webgl.samplers[sampler])
		},
		/**
		 * @param {number} sampler
		 * @param {number} pname
		 * @param {number} param
		 * @returns {void}
		 */
		SamplerParameteri: (sampler, pname, param) => {
			webgl.ctx.samplerParameteri(webgl.samplers[sampler], pname, param)
		},
		/**
		 * @param {number} sampler
		 * @param {number} pname
		 * @param {number} param
		 * @returns {void}
		 */
		SamplerParameterf: (sampler, pname, param) => {
			webgl.ctx.samplerParameterf(webgl.samplers[sampler], pname, param)
		},

		/*
		Sync objects
		*/

		/**
		 * @param {number} condition
		 * @param {number} flags
		 * @returns {number}
		 */
		FenceSync: (condition, flags) => {
			const sync = webgl.ctx.fenceSync(condition, flags)
			if (!sync) return 0

			const id = newId(webgl)
			sync.name = id
			webgl.syncs[id] = sync
			return id
		},
		/**
		 * @param {number} sync
		 * @returns {boolean}
		 */
		IsSync: sync => {
			return webgl.ctx.isSync(webgl.syncs[sync])
		},
		/**
		 * @param {number} id
		 * @returns {void}
		 */
		DeleteSync: id => {
			const obj = webgl.syncs[id]
			if (obj && id != 0) {
				webgl.ctx.deleteSampler(obj)
				webgl.syncs[id] = null
			}
		},
		/**
		 * @param {number} sync
		 * @param {number} flags
		 * @param {number} timeout
		 * @returns {number}
		 */
		ClientWaitSync: (sync, flags, timeout) => {
			return webgl.ctx.clientWaitSync(webgl.syncs[sync], flags, timeout)
		},
		/**
		 * @param {number} sync
		 * @param {number} flags
		 * @param {number} timeout
		 * @returns {void}
		 */
		WaitSync: (sync, flags, timeout) => {
			webgl.ctx.waitSync(webgl.syncs[sync], flags, timeout)
		},

		/*
		Transform Feedback
		*/

		/** @returns {number} */
		CreateTransformFeedback: () => {
			const transform_feedback = webgl.ctx.createTransformFeedback()
			if (!transform_feedback) {
				recordError(webgl, INVALID_OPERATION)
				return 0
			}

			const id = newId(webgl)
			transform_feedback.name = id
			webgl.transform_feedbacks[id] = transform_feedback
			return id
		},
		/** @returns {void} */
		DeleteTransformFeedback: (/** @type {number} */ id) => {
			if (id === 0) return

			const obj = webgl.transform_feedbacks[id]
			if (obj) {
				webgl.ctx.deleteTransformFeedback(obj)
				webgl.transform_feedbacks[id] = null
			}
		},
		/** @returns {boolean} */
		IsTransformFeedback: (/** @type {number} */ tf) => {
			return webgl.ctx.isTransformFeedback(webgl.transform_feedbacks[tf])
		},
		/** @returns {void} */
		BindTransformFeedback: (/** @type {number} */ target, /** @type {number} */ tf) => {
			webgl.ctx.bindTransformFeedback(target, webgl.transform_feedbacks[tf])
		},
		/** @returns {void} */
		BeginTransformFeedback: (/** @type {number} */ primitive_mode) => {
			webgl.ctx.beginTransformFeedback(primitive_mode)
		},
		/** @returns {void} */
		EndTransformFeedback: () => {
			webgl.ctx.endTransformFeedback()
		},
		/** @returns {void} */
		TransformFeedbackVaryings: (
			/** @type {number} */ program,
			/** @type {number} */ varyings_ptr,
			/** @type {number} */ varyings_len,
			/** @type {number} */ buffer_mode,
		) => {
			const varyings = []
			for (let i = 0; i < varyings_len; i++) {
				const ptr = webgl.mem.loadPtr(varyings_ptr + i * STRING_SIZE + 0 * 4)
				const len = webgl.mem.loadPtr(varyings_ptr + i * STRING_SIZE + 1 * 4)
				varyings.push(webgl.mem.loadString(ptr, len))
			}
			webgl.ctx.transformFeedbackVaryings(webgl.programs[program], varyings, buffer_mode)
		},
		/** @returns {void} */
		PauseTransformFeedback: () => {
			webgl.ctx.pauseTransformFeedback()
		},
		/** @returns {void} */
		ResumeTransformFeedback: () => {
			webgl.ctx.resumeTransformFeedback()
		},

		/*
		Uniform Buffer Objects and Transform Feedback Buffers
		*/

		/** @returns {void} */
		BindBufferBase: (
			/** @type {number} */ target,
			/** @type {number} */ index,
			/** @type {number} */ buffer,
		) => {
			webgl.ctx.bindBufferBase(target, index, webgl.buffers[buffer])
		},
		/** @returns {void} */
		BindBufferRange: (
			/** @type {number} */ target,
			/** @type {number} */ index,
			/** @type {number} */ buffer,
			/** @type {number} */ offset,
			/** @type {number} */ size,
		) => {
			webgl.ctx.bindBufferRange(target, index, webgl.buffers[buffer], offset, size)
		},
		/** @returns {number} */
		GetUniformBlockIndex: (
			/** @type {number} */ program,
			/** @type {number} */ name_ptr,
			/** @type {number} */ name_len,
		) => {
			return webgl.ctx.getUniformBlockIndex(
				webgl.programs[program],
				mem.load_string_raw(wasm.memory.buffer, name_ptr, name_len),
			)
		},
		/** @returns {void} */
		GetActiveUniformBlockName: (
			/** @type {number} */ program,
			/** @type {number} */ uniform_block_index,
			/** @type {number} */ buf_ptr,
			/** @type {number} */ buf_len,
			/** @type {number} */ length_ptr,
		) => {
			const name = webgl.ctx.getActiveUniformBlockName(
				webgl.programs[program],
				uniform_block_index,
			)
			if (!name) {
				recordError(webgl, INVALID_OPERATION)
				return
			}
			const n = mem.store_string_raw(wasm.memory.buffer, buf_ptr, buf_len, name)
			mem.store_int(new DataView(wasm.memory.buffer), length_ptr, n)
		},
		/** @returns {void} */
		UniformBlockBinding: (
			/** @type {number} */ program,
			/** @type {number} */ uniformBlockIndex,
			/** @type {number} */ uniformBlockBinding,
		) => {
			webgl.ctx.uniformBlockBinding(
				webgl.programs[program],
				uniformBlockIndex,
				uniformBlockBinding,
			)
		},

		/*
		Vertex Array Objects
		*/

		/** @returns {number} */
		CreateVertexArray: () => {
			const vao = webgl.ctx.createVertexArray()
			if (!vao) {
				recordError(webgl, INVALID_OPERATION)
				return 0
			}

			const id = newId(webgl)
			vao.name = id
			webgl.vaos[id] = vao
			return id
		},
		/** @returns {void} */
		DeleteVertexArray: (/** @type {number} */ id) => {
			const obj = webgl.vaos[id]
			if (obj && id != 0) {
				webgl.ctx.deleteVertexArray(obj)
				webgl.vaos[id] = null
			}
		},
		/** @returns {boolean} */
		IsVertexArray: (/** @type {number} */ vertex_array) => {
			return webgl.ctx.isVertexArray(webgl.vaos[vertex_array])
		},
		/** @returns {void} */
		BindVertexArray: (/** @type {number} */ vertex_array) => {
			webgl.ctx.bindVertexArray(webgl.vaos[vertex_array])
		},
	}
}
