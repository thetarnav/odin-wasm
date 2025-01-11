#version 300 es

in vec3 a_position;
in vec3 a_normal;
in vec4 a_color;

uniform mat4 u_view;
uniform mat4 u_local;
uniform vec3 u_eye_position;

out vec3 v_normal;
out vec4 v_color;
out vec3 v_surface_to_eye;

void main() {
	vec4 local_pos = u_local * vec4(a_position, 1.0);

	// project the position
	gl_Position = u_view * local_pos;

	/*
	 orient the normals

	 mat3() is the upper 3x3 - orientation, no translation
	*/
	v_normal = mat3(u_local) * a_normal;

	v_surface_to_eye = u_eye_position - local_pos.xyz;

	v_color = a_color;
}
