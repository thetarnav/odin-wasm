// will pass vec3, but will be converted to vec4 with w = 1.0
attribute vec4 a_position;
attribute vec4 a_color;

uniform mat4 u_matrix;

varying vec4 v_color;

void main() {
	gl_Position = u_matrix * a_position;

	v_color = a_color;
}
