#version 300 es

precision highp float;

in vec3 v_normal;
in vec3 v_surface_to_light_one;
in vec3 v_surface_to_light_two;

uniform float u_light_add_one;
uniform float u_light_add_two;

uniform vec4 u_light_color_one;
uniform vec3 u_light_dir_one;
uniform vec4 u_light_color_two;
uniform vec3 u_light_dir_two;

out vec4 out_color;

#define limit_lower 0.9
#define limit_upper 1.0

/*
float step(a, b) {
	return a < b ? 1.0 : 0.0;
}

smoothstep(a, b, x) {
	float t = clamp((x - a) / (b - a), 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t); // ease in and out
}
*/

float light_strength(vec3 normal, vec3 surface_to_light, vec3 light_normal) {
	float dot_in_light  = dot(surface_to_light, -light_normal);
	float in_light      = smoothstep(limit_lower, limit_upper, dot_in_light);
	float dot_in_normal = dot(normal, surface_to_light);

	return in_light * (dot_in_normal - 0.35) * 2.0;
}

void main() {
	// varrying variables are interpolated
	vec3 normal               = normalize(v_normal);
	vec3 surface_to_light_one = normalize(v_surface_to_light_one);
	vec3 surface_to_light_two = normalize(v_surface_to_light_two);
	
	float light_one = clamp(u_light_add_one + light_strength(normal, surface_to_light_one, u_light_dir_one), 0.0, 1.0);
	float light_two = clamp(u_light_add_two + light_strength(normal, surface_to_light_two, u_light_dir_two), 0.0, 1.0);

	vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
	out_color = (u_light_color_one * light_one + u_light_color_two * light_two);
	out_color = mix(out_color, white, max((light_one + light_two) / 2.0, 0.0));
}
