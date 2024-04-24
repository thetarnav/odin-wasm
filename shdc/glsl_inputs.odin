package shdc

import "core:strconv"

Input :: struct {
	name: string,
	kind: Input_Kind,
	type: string,
	len : int, // for arrays
}

Input_Kind :: enum u8 {
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
}

vertex_get_inputs :: proc(src: string, allocator := context.allocator) -> ([]Input, Error) {

	inputs := make([dynamic]Input, 0, 16, allocator)
	defer shrink(&inputs)

	t := Tokenizer{src=src}
	
	input: Input
	
	token: Token
	for {
		token = next_token(&t) or_break

		// Input Kind
		if token.kind != .Word do continue

		switch token_string(token, src) {
		case "uniform":         input = Input{kind=.Uniform}
		case "attribute", "in": input = Input{kind=.Attribute}
		case: continue
		}

		// Input Type
		token = next_token(&t)
		if token.kind != .Word {
			return {}, Error_Invalid_Token{token}
		}

		input.type = token_string(token, src)

		// Input Name
		token = next_token(&t)
		if token.kind != .Word {
			return {}, Error_Invalid_Token{token}
		}

		input.name = token_string(token, src)

		defer append(&inputs, input)

		// Array Length
		token = next_token(&t)
		if token.kind != .Symbol || token_string(token, src) != "[" {
			continue
		}

		token = next_token(&t)
		if token.kind != .Int {
			return {}, Error_Invalid_Token{token}
		}

		input.len, _ = strconv.parse_int(token_string(token, src))

		token = next_token(&t)
		if token.kind != .Symbol || token_string(token, src) != "]" {
			return {}, Error_Invalid_Token{token}
		}
	}

	return inputs[:], Error{}
}