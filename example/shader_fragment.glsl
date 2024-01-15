// fragment shaders don't have a default precision so we need
// to pick one. mediump is a good default
precision mediump float;

// color varying received from vertex shader
varying vec4 v_color;

void main() {
	gl_FragColor = v_color;
}
