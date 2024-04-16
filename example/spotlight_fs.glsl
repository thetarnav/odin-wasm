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

void main() {
	// varrying variables are interpolated
	vec3 normal               = normalize(v_normal);
	vec3 surface_to_light_one = normalize(v_surface_to_light_one);
	vec3 surface_to_light_two = normalize(v_surface_to_light_two);

	float limit = 0.92;
	float light_one = 0.0;
	float light_two = 0.0;

	if (dot(surface_to_light_one, -u_light_one_direction) >= limit) {
		light_one = (dot(normal, surface_to_light_one) - 0.35) * 2.0;
	}

	if (dot(surface_to_light_two, -u_light_two_direction) >= limit) {
		light_two = (dot(normal, surface_to_light_two) - 0.35) * 2.0;
	}

	vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
	out_color = (u_light_one_color * light_one + u_light_two_color * light_two);
	out_color = mix(out_color, white, max((light_one + light_two) / 2.0, 0.0));
}
