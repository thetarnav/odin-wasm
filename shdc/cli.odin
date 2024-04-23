package shdc

import "core:fmt"
import "core:strings"
import "base:runtime"
import "core:os"

_ :: fmt // prevent unused import error

files: []runtime.Load_Directory_File = #load_directory("../example")

generated_footer: string : `package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"


Attribute_Float :: distinct i32
Attribute_Vec2  :: distinct i32
Attribute_Vec3  :: distinct i32
Attribute_Vec4  :: distinct i32
Attribute_Mat2  :: distinct i32
Attribute_Mat3  :: distinct i32
Attribute_Mat4  :: distinct i32

Uniform_Float   :: distinct i32
Uniform_Vec2    :: distinct i32
Uniform_Vec3    :: distinct i32
Uniform_Vec4    :: distinct i32
Uniform_Mat2    :: distinct i32
Uniform_Mat3    :: distinct i32
Uniform_Mat4    :: distinct i32

set_uniform_1fv :: proc(loc: Uniform_Float, v: f32 ) {
	gl.Uniform1fv(loc, v)
}
set_uniform_2fv :: proc(loc: Uniform_Vec2,  v: vec2) {
	gl.Uniform2fv(loc, v)
}
set_uniform_3fv :: proc(loc: Uniform_Vec3,  v: vec3) {
	gl.Uniform3fv(loc, v)
}
set_uniform_4fv :: proc(loc: Uniform_Vec4,  v: vec4) {
	gl.Uniform4fv(loc, v)
}
`

main :: proc() {
	context.allocator = context.temp_allocator

	for file in files {
		strings.has_suffix(file.name, ".glsl") or_continue

		content := string(file.data)
		inputs, err := vertex_get_inputs(content)

		fmt.printf("file: %s\n", file.name)

		if err != nil {
			fmt.printf("error: %v\n", err)
			continue
		}
		
		for input in inputs {
			fmt.printf("input: %s\n", input.name)
			fmt.printf("kind : %s\n", input.kind)
			fmt.printf("type : %s\n", input.type)
			fmt.printf("len  : %d\n", input.len)
			fmt.printf("\n")
		}
	}

	data_str := "hello\n"
	data := transmute([]byte)(data_str)

	ok := os.write_entire_file("example/shader_generated.odin", data)
	if !ok {
		fmt.printf("failed to write file\n")
	}
}