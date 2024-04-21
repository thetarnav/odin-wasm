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
	width: int, // width of the last char
}

@(require_results)
next_char :: proc "contextless" (t: ^UTF8_Reader) -> (char: rune, before_eof: bool) #optional_ok #no_bounds_check {
	if t.pos >= len(t.src) {
		t.char = 0
		t.pos = len(t.src)+1
		return 0, false
	}

	ch, width := utf8.decode_rune_in_string(t.src[t.pos:])
	t.char = ch
	t.pos += width
	t.width = width
	return ch, true
}

unget_char :: #force_inline proc "contextless" (t: ^UTF8_Reader) {
	t.pos -= t.width
	t.width = 0
}

@(require_results)
skip_whitespace_and_comments :: proc "contextless" (t: ^UTF8_Reader) -> (before_eof: bool) {
	loop: for ch in next_char(t) {
		switch ch {
		case ' ', '\t', '\n', '\r': continue
		case '/':
			(next_char(t) == '/') or_continue
			for c in next_char(t) {
				switch c {
				case '\n', 0: continue loop
				}
			}
		case 0:
			return false
		case:
			unget_char(t)
			return true
		}
	}

	return false
}

@(require_results)
scan_word :: proc "contextless" (t: ^UTF8_Reader) -> string #no_bounds_check {
	word_begin := t.pos

	loop: for ch in next_char(t) {
		switch ch {
		case 'a'..='z', 'A'..='Z', '0'..='9', '_':
			continue
		case: 
			unget_char(t)
			break loop
		}
	}

	return t.src[word_begin:t.pos]
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

Error_Kind :: enum {
	None,
	Unknown_Type,
	Missing_Input_Name,
}

Error :: struct {
	kind: Error_Kind,
	pos : int,
}

vertex_get_inputs :: proc(src: string, allocator := context.allocator) -> ([]Input, Error) {

	inputs := make([dynamic]Input, 0, 16, allocator)
	defer shrink(&inputs)

	reader := UTF8_Reader{src=src}
	
	input: Input
	
	for _ in next_char(&reader) {
		unget_char(&reader)

		skip_whitespace_and_comments(&reader) or_break

		modifier := scan_word(&reader)

		switch modifier {
		case "uniform":         input = Input{kind=.Uniform}
		case "attribute", "in": input = Input{kind=.Attribute}
		case: continue
		}

		skip_whitespace_and_comments(&reader) or_break

		switch type_name := scan_word(&reader); type_name {
		case "float": input.type = .Float
		case "vec2":  input.type = .Vec2
		case "vec3":  input.type = .Vec3
		case "vec4":  input.type = .Vec4
		case "mat2":  input.type = .Mat2
		case "mat3":  input.type = .Mat3
		case "mat4":  input.type = .Mat4
		case:
			return {}, Error{.Unknown_Type, reader.pos}
		}

		skip_whitespace_and_comments(&reader) or_break

		input.name = scan_word(&reader)
		if input.name == "" do return {}, Error{.Missing_Input_Name, reader.pos}

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

		if err.kind != .None {
			fmt.printf("error: %s at pos %d\n", err.kind, err.pos)
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