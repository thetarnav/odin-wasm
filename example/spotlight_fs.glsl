#version 300 es

precision highp float;

in vec3 v_normal;
in vec4 v_color;
in vec3 v_surface_to_light;

uniform vec4 u_light_color;
uniform vec3 u_light_direction;

out vec4 out_color;

void main() {
	// varrying variables are interpolated
	vec3 normal           = normalize(v_normal);
	vec3 surface_to_light = normalize(v_surface_to_light);

	float limit = 0.9;
	float light = 0.0;

	if (dot(surface_to_light, -u_light_direction) >= limit) {
		light = dot(normal, surface_to_light);
	}

	// out_color = mix(v_color, u_light_color, light);
	// out_color = out_color * light;
	out_color = v_color * light;
	out_color = mix(out_color, u_light_color, light);
}
