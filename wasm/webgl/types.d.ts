/*
indices will be set to `0` when the buffer is deleted
*/
export type WebGLBufferArray = Array<WebGLBuffer | 0>
export type WebGLShaderArray = Array<WebGLShader | 0>

export type WebGLInterface = {
	wasm: import("../types.js").WasmInstance
	element: HTMLCanvasElement | null
	ctx: WebGLRenderingContext | WebGL2RenderingContext
	version: 1 | 2
	counter: 1
	last_error: number
	buffers: WebGLBufferArray
	mappedBuffers: {}
	programs: WebGLBufferArray
	framebuffers: WebGLBufferArray
	renderbuffers: WebGLBufferArray
	textures: WebGLBufferArray
	uniforms: WebGLUniformLocation[]
	shaders: WebGLShaderArray
	vaos: []
	contexts: []
	currentContext: null
	offscreenCanvases: {}
	timerQueriesEXT: []
	queries: []
	samplers: []
	transformFeedbacks: []
	syncs: []
	programInfos: {}
}
