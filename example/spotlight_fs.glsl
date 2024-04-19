#version 300 es

precision highp float;

in vec3 v_normal;
in vec3 v_surface_to_light[2];

uniform float u_light_add[2];
uniform vec4  u_light_color[2];
uniform vec3  u_light_dir[2];

out vec4 out_color;

#define limit_lower 0.9
#define limit_upper 1.0

#define white vec4(1.0, 1.0, 1.0, 1.0)

/*
float step(a, b) {
	return a < b ? 1.0 : 0.0;
}

smoothstep(a, b, x) {
	float t = clamp((x - a) / (b - a), 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t); // ease in and out
}
*/

void main() {
	// varrying variables are interpolated
	vec3 normal = normalize(v_normal);
	
	vec4  total_light_color    = vec4(0.0, 0.0, 0.0, 0.0);
	float total_light_strength = 0.0;

	for(int i = 0; i < 2; i++) {
		vec3  surface_to_light = normalize(v_surface_to_light[i]);
		float dot_in_light     = dot(surface_to_light, -u_light_dir[i]);
		float in_light         = smoothstep(limit_lower, limit_upper, dot_in_light);
		float dot_in_normal    = dot(normal, surface_to_light);
		float light_strength   = in_light * (dot_in_normal - 0.35) * 2.0;
		float light            = clamp(u_light_add[i] + light_strength, 0.0, 1.0);
		total_light_color     += u_light_color[i] * light;
		total_light_strength  += light;
	}

	out_color = mix(total_light_color, white, max(total_light_strength / 2.0, 0.0));
}
