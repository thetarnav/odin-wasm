#version 300 es

// an attribute is an input (in) to a vertex shader.
// It will receive data from a buffer
in vec4 a_position;
in vec3 a_normal;

uniform mat4 u_matrix;
uniform mat4 u_world;

// a varying the color to the fragment shader
out vec3 v_normal;

void main() {
  gl_Position = u_matrix * a_position;

  // orient the normals and pass to the fragment shader
  // mat3(u_world) is the upper 3x3 of the world matrix
  // it transforms the normal's orientation
  // as opposed to the translation
  v_normal = mat3(u_world) * a_normal;
}