#version 300 es
// fragment shaders don't have a default precision so we need
// to pick one. mediump is a good default
precision highp float;

// the varied normal passed from the vertex shader
in vec3 v_normal;

uniform vec3 u_light_dir;
uniform vec4 u_color;

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

	out_color = u_color;

	// Lets multiply just the color portion (not the alpha)
	// by the light
	out_color.rgb *= light;
}