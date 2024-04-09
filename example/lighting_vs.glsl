#version 300 es

// an attribute is an input (in) to a vertex shader.
// It will receive data from a buffer
in vec4 a_position;
in vec3 a_normal;

// A matrix to transform the positions by
uniform mat4 u_matrix;

// a varying the color to the fragment shader
out vec3 v_normal;

void main() {
  gl_Position = u_matrix * a_position;

  // Pass the normal to the fragment shader.
  v_normal = a_normal;
}