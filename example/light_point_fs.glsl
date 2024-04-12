#version 300 es

precision highp float;

in vec3 v_normal;
in vec4 v_color;
in vec3 v_surface_to_light;
in vec3 v_surface_to_eye;

uniform vec4 u_light_color;

out vec4 out_color;

void main() {
	// varrying variables are interpolated
	vec3 normal           = normalize(v_normal);
	vec3 surface_to_light = normalize(v_surface_to_light);
	vec3 surface_to_eye   = normalize(v_surface_to_eye);
	vec3 half_vector      = normalize(surface_to_light + surface_to_eye);

	// v_normal and v_surface_to_light are interpolated
	float light    = dot(normal, surface_to_light);
	float specular = dot(normal, half_vector);

	out_color = mix(v_color, u_light_color, specular);
	out_color.rgb *= light * 0.5 + 0.5;
}