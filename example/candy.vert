#version 300 es

in vec3 a_position;
in vec4 a_color;

uniform mat4 u_view;
uniform mat4 u_local;

out vec4 v_color;

void main() {
	vec4 local_pos = u_local * vec4(a_position, 1.0);
	gl_Position = u_view * local_pos;

	v_color = a_color;
}
