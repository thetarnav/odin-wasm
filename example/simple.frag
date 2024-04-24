#version 300 es
// fragment shaders don't have a default precision so we need
// to pick one. mediump is a good default
precision highp float;

// the varied color passed from the vertex shader
in vec4 v_color;

// we need to declare an output for the fragment shader
// equvalent of gl_FragColor in GLSL 100
out vec4 out_color;

void main() {
	out_color = v_color;
}
