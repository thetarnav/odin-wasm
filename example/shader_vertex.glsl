// an attribute will receive data from a buffer
attribute vec2 a_position;
attribute vec4 a_color;

uniform mat3 u_matrix;

// color to pass to the fragment shader
// value in fragment shader will be interpolated
varying vec4 v_color;

void main() {
	// Multiply the position by the matrix.
	gl_Position = vec4((u_matrix * vec3(a_position, 1)).xy, 0, 1);

	v_color = a_color;
}
