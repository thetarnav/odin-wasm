#version 300 es

// an attribute is an input (in) to a vertex shader.
// It will receive data from a buffer
in vec3 a_position;
in vec4 a_color;

// A matrix to transform the positions by
uniform mat4 u_matrix;

// a varying the color to the fragment shader
out vec4 v_color;

void main() {
  gl_Position = u_matrix * vec4(a_position, 1.0);

  // Pass the color to the fragment shader.
  v_color = a_color;
}
