// an attribute will receive data from a buffer
attribute vec2 a_position;
attribute vec4 a_color;

uniform vec2 u_resolution;
uniform mat3 u_matrix;

// color to pass to the fragment shader
// value in fragment shader will be interpolated
varying vec4 v_color;

void main() {
	vec2 pos = (u_matrix * vec3(a_position, 1)).xy;

    // from pixels to 0->1 then to 0->2 then to -1->+1 (clipspace)
	vec2 clip_space = (pos / u_resolution) * 2.0 - 1.0;

	gl_Position = vec4(clip_space * vec2(1, -1), 0, 1);

	v_color = a_color;
}
