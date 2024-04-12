#version 300 es

precision highp float;

in vec3 v_normal;
in vec4 v_color;
in vec3 v_surface_to_light;

uniform vec4 u_light_color;

out vec4 out_color;

void main() {
	// v_normal and v_surface_to_light are interpolated
	float light = dot(normalize(v_normal), normalize(v_surface_to_light));

	out_color = mix(v_color, u_light_color, light);
}