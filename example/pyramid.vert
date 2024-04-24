#version 300 es
// will pass vec3, but will be converted to vec4 with w = 1.0
in vec3 a_position;
in vec4 a_color;

uniform mat4 u_matrix;

out vec4 v_color;

void main() {
	// Multiply the position by the matrix.
	vec4 position = u_matrix * vec4(a_position, 1.0);

	// apply "perspective"
	gl_Position = vec4(position.xyz, 1.0 + position.z * 0.5);

	v_color = a_color;
}
