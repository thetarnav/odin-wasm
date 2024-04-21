package shdc

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"
import "base:runtime"

_ :: fmt // prevent unused import error

files: []runtime.Load_Directory_File = #load_directory("../example")

UTF8_Reader :: struct {
	src : string,
	pos : int,
	char: rune,
}

next_char :: proc "contextless" (t: ^UTF8_Reader) -> (char: rune, before_eof: bool) #optional_ok #no_bounds_check {
	if t.pos >= len(t.src) {
		t.char = 0
		t.pos = len(t.src)+1
		return 0, false
	}

	ch, width := utf8.decode_rune_in_string(t.src[t.pos:])
	t.char = ch
	t.pos += width
	return ch, true
}

is_whitespace :: #force_inline proc "contextless" (ch: rune) -> bool {
	switch ch {
	case ' ', '\t', '\n', '\r': return true
	case: return false
	}
}

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

vertex_get_inputs :: proc(src: string, allocator := context.allocator) -> []Input {
	inputs := make([dynamic]Input, 0, 16, allocator)
	defer shrink(&inputs)

	reader := UTF8_Reader{src=src}
	
	word_begin: int
	word_end  : int
	input: Input
	
	for c in next_char(&reader) {
		if is_whitespace(c) do continue

		word_begin = reader.pos-1
		for ch in next_char(&reader) {
			if is_whitespace(ch) do break
		}
		word_end = reader.pos-1

		word := src[word_begin:word_end]

		switch word {
		case "uniform":         input = Input{kind=.Uniform}
		case "attribute", "in": input = Input{kind=.Attribute}
		case: continue
		}

		word_begin = reader.pos
		for ch in next_char(&reader) {
			if is_whitespace(ch) do break
			if ch == ';' do break
		}
		word_end = reader.pos-1

		switch src[word_begin:word_end] {
		case "float": input.type = .Float
		case "vec2":  input.type = .Vec2
		case "vec3":  input.type = .Vec3
		case "vec4":  input.type = .Vec4
		case "mat2":  input.type = .Mat2
		case "mat3":  input.type = .Mat3
		case "mat4":  input.type = .Mat4
		}

		word_begin = reader.pos
		for ch in next_char(&reader) {
			if is_whitespace(ch) do break
			if ch == ';' do break
		}
		word_end = reader.pos-1

		input.name = src[word_begin:word_end]


		fmt.println(input)
	}

	return inputs[:]
}

main :: proc() {
	for file in files {
		strings.has_suffix(file.name, ".glsl") or_continue

		content := string(file.data)
		inputs := vertex_get_inputs(content)

		fmt.printf("file: %s\n", file.name)
		for input in inputs {
			fmt.printf("input: %s\n", input.name)
		}
	}
}