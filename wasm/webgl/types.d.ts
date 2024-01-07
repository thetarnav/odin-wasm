/*
indices will be set to `null` when the buffer is deleted
*/
export type ArrayRecord<T> = Array<null | T>

export interface ProgramInfo {
	uniforms: Record<number | string, null | [number, number]>
	maxUniformLength: number
	maxAttributeLength: number
	maxUniformBlockNameLength: number
}

// prettier-ignore
export interface WebGLInterface {
    element             : HTMLCanvasElement | null,
    ctx                 : WebGLRenderingContext | WebGL2RenderingContext,
    version             : 1 | 2,
    id_counter          : number,
    last_error          : number,
    buffers             : ArrayRecord<WebGLBuffer>,
    programs            : ArrayRecord<WebGLBuffer>,
    program_infos       : ArrayRecord<ProgramInfo>,
    framebuffers        : ArrayRecord<WebGLBuffer>,
    renderbuffers       : ArrayRecord<WebGLBuffer>,
    textures            : ArrayRecord<WebGLBuffer>,
    uniforms            : ArrayRecord<WebGLUniformLocation>,
    shaders             : ArrayRecord<WebGLShader>,
    /*
    WebGL 2
    */
	vaos                : ArrayRecord<WebGLVertexArrayObject>,
    samplers            : ArrayRecord<WebGLSampler>,
    queries             : ArrayRecord<WebGLQuery>,
    transform_feedbacks : ArrayRecord<WebGLTransformFeedback>,
    syncs               : ArrayRecord<WebGLSync>
}
export interface WebGL2Interface extends WebGLInterface {
	ctx: WebGL2RenderingContext
	version: 2
}

// prettier-ignore
declare global {
	interface WebGLProgram           {name: number}
	interface WebGLShader            {name: number}
	interface WebGLBuffer            {name: number}
	interface WebGLTexture           {name: number}
	interface WebGLUniformLocation   {name: number}
	interface WebGLRenderbuffer      {name: number}
	interface WebGLFramebuffer       {name: number}
	interface WebGLVertexArrayObject {name: number}
	interface WebGLSampler           {name: number}
	interface WebGLQuery             {name: number}
	interface WebGLSync              {name: number}
	interface WebGLTransformFeedback {name: number}
}
