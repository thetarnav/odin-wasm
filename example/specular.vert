#version 300 es

in vec3 a_position;
in vec3 a_normal;
in vec4 a_color;

uniform vec3 u_light_pos;
uniform vec3 u_eye_pos;
uniform mat4 u_view;
uniform mat4 u_local;

out vec3 v_normal;
out vec4 v_color;
out vec3 v_surface_to_light;
out vec3 v_surface_to_eye;

void main() {
	vec4 local_pos = u_local * vec4(a_position, 1.0);

	// project the position
	gl_Position = u_view * local_pos;

	/*
	orient the normals and pass to the fragment shader

	mat3() is the upper 3x3 - orientation, no translation

	transpose() + inverse() is to make it work with non-uniform scaling
	*/
	v_normal = mat3(transpose(inverse(u_local))) * a_normal;

	v_surface_to_light = u_light_pos - local_pos.xyz;
	v_surface_to_eye   = u_eye_pos   - local_pos.xyz;

	v_color = a_color;
}
