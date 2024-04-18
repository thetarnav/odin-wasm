#version 300 es

precision highp float;

in vec3 v_normal;
in vec3 v_surface_to_light_one;
in vec3 v_surface_to_light_two;

uniform vec4 u_light_one_color;
uniform vec3 u_light_one_direction;
uniform vec4 u_light_two_color;
uniform vec3 u_light_two_direction;

out vec4 out_color;

#define limit_start 0.9
#define limit_range 0.1

/*
float step(a, b) {
	return a < b ? 1.0 : 0.0;
}
*/

float light_strength(vec3 normal, vec3 surface_to_light, vec3 light_direction) {
	float dot_in_light  = dot(surface_to_light, -light_direction);
	float in_light      = clamp((dot_in_light - limit_start) / limit_range, 0.0, 1.0);
	float dot_in_normal = dot(normal, surface_to_light);

	return in_light * (dot_in_normal - 0.35) * 2.0;
}

void main() {
	// varrying variables are interpolated
	vec3 normal               = normalize(v_normal);
	vec3 surface_to_light_one = normalize(v_surface_to_light_one);
	vec3 surface_to_light_two = normalize(v_surface_to_light_two);
	
	float light_one = light_strength(normal, surface_to_light_one, u_light_one_direction);
	float light_two = light_strength(normal, surface_to_light_two, u_light_two_direction);

	vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
	out_color = (u_light_one_color * light_one + u_light_two_color * light_two);
	out_color = mix(out_color, white, max((light_one + light_two) / 2.0, 0.0));
}
