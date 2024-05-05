#version 300 es

in vec3 a_position;
in vec4 a_color;
in vec3 a_normal;

uniform vec3 u_light_pos;
uniform mat4 u_view;
uniform mat4 u_world;

out vec3 v_normal;
out vec4 v_color;
out vec3 v_surface_to_light;

void main() {
	vec4 world_pos = u_world * vec4(a_position, 1.0);

	gl_Position = u_view * world_pos;

	/*
	orient the normals and pass to the fragment shader

	mat3() is the upper 3x3 - orientation, no translation

	transpose() + inverse() is to make it work with non-uniform scaling
	*/
	v_normal = mat3(transpose(inverse(u_world))) * a_normal;

	v_surface_to_light = u_light_pos - world_pos.xyz;

	v_color = a_color;
}
