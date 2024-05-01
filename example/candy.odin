//+private file
package example

// import glm "core:math/linalg/glsl"
import "core:math/rand"
import "core:fmt"
import gl  "../wasm/webgl"

@private
State_Candy :: struct {
	using locations: Input_Locations_Candy,
}

Shape :: struct {
	positions: []vec3,
	colors:    []u8vec4,
	vao:       VAO,
}

Object :: struct {
	using uniforms: Uniform_Values_Candy,
	translation:    vec3,
	rotation_speed: [2]vec3,
}

rand_color :: proc() -> u8vec4 {
	color := transmute(u8vec4)rand.uint32()
	color.a = 255
	return color
}

@private
setup_candy :: proc(s: ^State_Candy, program: gl.Program) {

	cube_shape: Shape = {vao = gl.CreateVertexArray()}

	cube_positions := get_cube_positions()
	cube_shape.positions = cube_positions[:]
	
	cube_shape.colors = make([]u8vec4, len(cube_positions))
	for &color in cube_shape.colors {
		color = rand_color()
	}

	fmt.println("cube_shape.positions: ", cube_shape.positions)
	fmt.println("cube_shape.colors: ", cube_shape.colors)

	// s.vao = gl.CreateVertexArray()
	// gl.BindVertexArray(s.vao)

	// input_locations_candy(s, program)

	// gl.Enable(gl.CULL_FACE)
	// gl.Enable(gl.DEPTH_TEST)
}

@private
frame_candy :: proc(s: ^State_Candy, delta: f32) {

}
	