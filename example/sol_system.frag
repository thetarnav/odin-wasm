#version 300 es
precision highp float;

in vec3 v_normal;
in vec3 v_surface_to_light;

uniform vec4  u_color;
uniform float u_light_factor;

out vec4 out_color;

void main() {
	vec3 normal = normalize(v_normal);
	vec3 surface_to_light = normalize(v_surface_to_light);

	float light = dot(normal, surface_to_light);

	vec4 dark_color = mix(vec4(0, 0, 0, 0), u_color, u_light_factor);
	out_color = mix(dark_color, u_color, light);
}
