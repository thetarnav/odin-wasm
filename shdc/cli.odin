package shdc

import "core:fmt"
import "core:strings"
import "base:runtime"
import "core:os"

_ :: fmt // prevent unused import error

files: []runtime.Load_Directory_File = #load_directory("../example")

main :: proc() {
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