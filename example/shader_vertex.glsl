// an attribute will receive data from a buffer
attribute vec2 a_position;
attribute vec4 a_color;
uniform vec2 u_resolution;
// color to pass to the fragment shader
// value in fragment shader will be interpolated
varying vec4 v_color;

void main() {
    // from pixels to 0->1 then to 0->2 then to -1->+1 (clipspace)
    vec2 clip_space = (a_position / u_resolution) * 2.0 - 1.0;

    gl_Position = vec4(clip_space * vec2(1, -1), 0, 1);

    // Convert from clip space to color space.
    // Clip space goes -1.0 to +1.0
    // Color space goes from 0.0 to 1.0
    // v_color = 1.0 - (gl_Position * 0.5 + 0.5);
    v_color = a_color;
}
