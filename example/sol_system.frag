#version 300 es
precision highp float;

in vec4 v_color;

uniform vec4 u_color_mult;

out vec4 out_color;

void main() {
   out_color = v_color * u_color_mult;
}
