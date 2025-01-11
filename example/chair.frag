#version 300 es

precision highp float;

in vec3 v_normal;
in vec4 v_color;
in vec3 v_surface_to_eye;

uniform vec3  u_diffuse;
uniform vec3  u_ambient;
uniform vec3  u_emissive;
uniform vec3  u_specular;
uniform float u_shininess;
uniform float u_opacity;
uniform vec3  u_light_dir;
uniform vec3  u_light_ambient;

out vec4 out_color;

void main() {
	// varying variables are interpolated
	vec3 normal          = normalize(v_normal);
	vec3 surface_to_eye  = normalize(v_surface_to_eye);
	vec3 half_vector     = normalize(surface_to_eye + u_light_dir);

	float light_fake     = dot(u_light_dir, normal) * .5 + .5;
	float light_specular = clamp(dot(normal, half_vector), 0.0, 1.0);

	vec3 effective_diffuse = u_diffuse * v_color.rgb;
	float effective_opacity = u_opacity * v_color.a;

	out_color = vec4(
		(
			u_emissive +
			u_ambient * u_light_ambient +
			effective_diffuse * light_fake +
			u_specular * pow(light_specular, u_shininess)
		),
		effective_opacity);
}
