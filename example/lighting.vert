#version 300 es

// an attribute is an input (in) to a vertex shader.
// It will receive data from a buffer
in vec3 a_position;
in vec3 a_normal;
in vec4 a_color;

uniform mat4 u_view;
uniform mat4 u_local;

// varring passed to the fragment shader
out vec3 v_normal;
out vec4 v_color;

void main() {
	// project the position
	gl_Position = u_view * u_local * vec4(a_position, 1.0);

	/*
	orient the normals and pass to the fragment shader

	mat3() is the upper 3x3 - orientation, no translation

	transpose() + inverse() is to make it work with non-uniform scaling
	*/
	v_normal = mat3(transpose(inverse(u_local))) * a_normal;

	// pass the color to the fragment shader
	v_color = a_color;
}
