package shdc

import "core:fmt"
import "core:strings"
import "base:runtime"
import "core:os"

write :: strings.write_string

files: []runtime.Load_Directory_File = #load_directory("../example")

output_header: string : `package example

import gl  "../wasm/webgl"


`

main :: proc() {
	context.allocator = context.temp_allocator

	b := strings.builder_make_len_cap(0, 10000)
	write(&b, output_header)

	for file in files {
		strings.has_suffix(file.name, ".glsl") or_continue

		content := string(file.data)
		inputs, err := vertex_get_inputs(content)

		fmt.printf("file: %s\n", file.name)

		if err != nil {
			fmt.printf("error: %v\n", err)
			continue
		}

		shader_name_snake := strings.to_snake_case(file.name[:len(file.name)-5])
		shader_name_ada   := strings.to_ada_case  (file.name[:len(file.name)-5])

		/* Type */
		write(&b, "Inputs_")
		write(&b, shader_name_ada)
		write(&b, " :: struct {\n")
		
		for input in inputs {
			fmt.printf("input: %s\n", input.name)
			fmt.printf("kind : %s\n", input.kind)
			fmt.printf("type : %s\n", input.type)
			fmt.printf("len  : %d\n", input.len)
			fmt.printf("\n")

			write(&b, "\t")
			write(&b, input.name)
			write(&b, ": ")
			if input.len > 1 {
				write(&b, "[")
				strings.write_int(&b, input.len)
				write(&b, "]")
			}
			write(&b, input.kind == .Uniform ? "Uniform_" : "Attribute_")
			write(&b, input.type)
			write(&b, ",\n")
		}

		write(&b, "}\n\n")

		/* Locations */
		write(&b, "input_locations_")
		write(&b, shader_name_snake)
		write(&b, " :: proc(s: ^Inputs_")
		write(&b, shader_name_ada)
		write(&b, ", program: gl.Program) {\n")

		for input in inputs {
			if input.len == 0 {
				write(&b, "\ts.")
				write(&b, input.name)
				write(&b, " = ")
				write(&b, input.kind == .Uniform ? "uniform_location_" : "attribute_location_")
				write(&b, input.type)
				write(&b, "(program, \"")
				write(&b, input.name)
				write(&b, "\")\n")
			} else {
				for i in 0..<input.len {
					write(&b, "\ts.")
					write(&b, input.name)
					write(&b, "[")
					strings.write_int(&b, i)
					write(&b, "] = ")
					write(&b, input.kind == .Uniform ? "uniform_location_" : "attribute_location_")
					write(&b, input.type)
					write(&b, "(program, \"")
					write(&b, input.name)
					write(&b, "[")
					strings.write_int(&b, i)
					write(&b, "]\")\n")
				}
			}
		}

		write(&b, "}\n\n")
	}

	ok := os.write_entire_file("example/_shaders.odin", b.buf[:])
	if !ok {
		fmt.printf("failed to write file\n")
	}
}
