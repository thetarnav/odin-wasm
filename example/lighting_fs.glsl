#version 300 es
precision highp float;

// varring passed from the vertex shader
in vec3 v_normal;
in vec4 v_color;

uniform vec3 u_light_dir; // reversed (dir to light)
uniform vec4 u_light_color;

// we need to declare an output for the fragment shader
// equvalent of gl_FragColor in GLSL 100
out vec4 out_color;

void main() {
	// because v_normal is a varying it's interpolated
	// so it will not be a uint vector. Normalizing it
	// will make it a unit vector again
	vec3 normal = normalize(v_normal);

	// compute the light by taking the dot product
	// of the normal to the light's reverse direction
	float light = dot(normal, u_light_dir);

	out_color = mix(v_color, u_light_color, light);
}
