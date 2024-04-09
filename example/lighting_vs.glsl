#version 300 es

// an attribute is an input (in) to a vertex shader.
// It will receive data from a buffer
in vec4 a_position;
in vec3 a_normal;

uniform mat4 u_view;
uniform mat4 u_local;

// a varying the color to the fragment shader
out vec3 v_normal;

void main() {
	// project the position
	gl_Position = u_view * u_local * a_position;

	// orient the normals and pass to the fragment shader
	// mat3(u_local) is the upper 3x3 of the local matrix
	// it transforms the normal's orientation
	// as opposed to the translation
	v_normal = mat3(u_local) * a_normal;
}