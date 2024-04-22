package shdc

import "core:fmt"
import "core:strings"
import "base:runtime"

_ :: fmt // prevent unused import error

files: []runtime.Load_Directory_File = #load_directory("../example")

Input :: struct {
	name: string,
	kind: Input_Kind,
	type: Input_Type,
	len : int, // for arrays
}

Input_Kind :: enum u8 {
	Uniform,
	Attribute,
}

Input_Type :: enum u8 {
	Float,
	Vec2,
	Vec3,
	Vec4,
	Mat2,
	Mat3,
	Mat4,
}

Error_Invalid_Token :: struct {
	token: Token,
}
Error_Unknown_Type :: struct {
	pos: int,
	len: int,
}
Error :: union {
	Error_Invalid_Token,
	Error_Unknown_Type,
}

vertex_get_inputs :: proc(src: string, allocator := context.allocator) -> ([]Input, Error) {

	inputs := make([dynamic]Input, 0, 16, allocator)
	defer shrink(&inputs)

	t := Tokenizer{src=src}
	
	input: Input
	
	token: Token
	for {
		token = next_token(&t) or_break

		if token.kind != .Word do continue

		switch token_string(token, src) {
		case "uniform":         input = Input{kind=.Uniform}
		case "attribute", "in": input = Input{kind=.Attribute}
		case: continue
		}

		token = next_token(&t)
		if token.kind != .Word do return {}, Error_Invalid_Token{token}

		switch token_string(token, src) {
		case "float": input.type = .Float
		case "vec2":  input.type = .Vec2
		case "vec3":  input.type = .Vec3
		case "vec4":  input.type = .Vec4
		case "mat2":  input.type = .Mat2
		case "mat3":  input.type = .Mat3
		case "mat4":  input.type = .Mat4
		case:
			return {}, Error_Unknown_Type{token.pos, token.len}
		}

		token = next_token(&t)
		if token.kind != .Word do return {}, Error_Invalid_Token{token}

		input.name = token_string(token, src)

		append(&inputs, input)
	}

	return inputs[:], Error{}
}

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
			fmt.printf("kind: %s\n", input.kind)
			fmt.printf("type: %s\n", input.type)
			fmt.printf("\n")
		}
	}
}