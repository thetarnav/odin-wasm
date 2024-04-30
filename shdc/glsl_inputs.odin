package shdc

import "core:strconv"
import "core:mem"

Shader_Kind :: enum u8 {
	Vert,
	Frag,
}

Shader_Input :: struct {
	name: string,
	kind: Shader_Input_Kind,
	type: string,
	len : int, // for arrays
}

Shader_Input_Kind :: enum u8 {
	Uniform,
	Attribute,
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
	mem.Allocator_Error,
}

shader_inputs_append :: proc(inputs: ^[dynamic]Shader_Input, src: string, shader_kind: Shader_Kind) -> Error {
	t := Tokenizer{src=src}
	input: Shader_Input
	token: Token
	
	for {
		token = next_token(&t) or_break

		// Input Kind
		if token.kind != .Word do continue

		switch token_string(token, src) {
		case "uniform":   input = {kind=.Uniform}
		case "attribute": input = {kind=.Attribute}
		case "in": 
			if shader_kind == .Frag do continue
			input = {kind=.Attribute}
		case: continue
		}

		// Input Type
		token = next_token(&t)
		if token.kind != .Word {
			return Error_Invalid_Token{token}
		}

		input.type = token_string(token, src)

		// Input Name
		token = next_token(&t)
		if token.kind != .Word {
			return Error_Invalid_Token{token}
		}

		input.name = token_string(token, src)

		// Array Length
		token = next_token(&t)
		if token.kind != .Symbol || token_string(token, src) != "[" {
			append(inputs, input) or_return
			continue
		}

		token = next_token(&t)
		if token.kind != .Int {
			return Error_Invalid_Token{token}
		}

		input.len, _ = strconv.parse_int(token_string(token, src))

		token = next_token(&t)
		if token.kind != .Symbol || token_string(token, src) != "]" {
			return Error_Invalid_Token{token}
		}

		append(inputs, input) or_return
	}

	return nil
}

shader_inputs_make :: proc(src: string, shader_kind: Shader_Kind, allocator := context.allocator) -> (inputs: []Shader_Input, err: Error) {
	inputs_dyn := make([dynamic]Shader_Input, 0, 16, allocator)
	defer shrink(&inputs_dyn)

	err    = shader_inputs_append(&inputs_dyn, src, shader_kind)
	inputs = inputs_dyn[:]

	return
}