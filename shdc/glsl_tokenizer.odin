package shdc

import "core:unicode/utf8"


Tokenizer :: struct {
	src      : string,
	pos_write: int,
	pos_read : int,
	char     : rune,
	width    : int, // width of the last char
}

Token_Kind :: enum {
	Invalid,
	EOF,
	Word,
	Int,
	Float,
	Symbol,
}

Token :: struct {
	kind: Token_Kind,
	pos : int,
	len : int,
}

next_char :: proc "contextless" (t: ^Tokenizer) -> (char: rune, before_eof: bool) #optional_ok #no_bounds_check {
	if t.pos_read >= len(t.src) {
		t.char = 0
		t.pos_read = len(t.src)+1
		t.width = 0
		return 0, false
	}

	ch, width := utf8.decode_rune_in_string(t.src[t.pos_read:])
	t.char = ch
	t.pos_read += width
	t.width = width
	return ch, true
}

unget_char :: #force_inline proc "contextless" (t: ^Tokenizer) {
	t.pos_read -= t.width
	t.width = 0
}

@(require_results)
next_token :: proc "contextless" (t: ^Tokenizer) -> (token: Token, before_eof: bool) #optional_ok {
	
	make_token :: proc "contextless" (t: ^Tokenizer, kind: Token_Kind) -> (token: Token) #no_bounds_check {
		token.kind  = kind
		token.pos   = t.pos_write
		token.len   = t.pos_read - t.pos_write
		t.pos_write = t.pos_read
		next_char(t)
		return
	}
	make_token_ignore_last_char :: proc "contextless" (t: ^Tokenizer, kind: Token_Kind) -> (token: Token) #no_bounds_check {
		token.kind  = kind
		token.pos   = t.pos_write
		token.len   = t.pos_read - t.pos_write - t.width
		t.pos_write = t.pos_read - t.width
		return
	}

	if t.pos_read >= len(t.src) {
		return make_token(t, .EOF), false
	}
	before_eof = true

	switch t.char {
	// Ignore Whitespace
	case ' ', '\t', '\n', '\r':
		t.pos_write = t.pos_read
		next_char(t)
		return next_token(t)
	// Ignore Comment
	case '/':
		switch next_char(t) {
		// Line Comment
		case '/':
			for {
				switch next_char(t) {
				case '\n', 0:
					t.pos_write = t.pos_read
					next_char(t)
					return next_token(t)
				}
			}
		// Block Comment
		case '*':
			escaping := false
			for {
				switch next_char(t) {
				case 0:
					return make_token_ignore_last_char(t, .Invalid), true
				case '\\':
					escaping = !escaping
				case '*':
					if !escaping && '/' == next_char(t) {
						t.pos_write = t.pos_read
						next_char(t)
						return next_token(t)
					}
					escaping = false
				case:
					escaping = false
				}
			}
		case:
			return make_token_ignore_last_char(t, .Symbol), true
		}
	// 0.123
	// 0
	case '0':
		switch next_char(t) {
		case '.':
			return scan_fraction(t)
		case '0'..='9', 'a'..='z', 'A'..='Z', '_':
			return make_token_ignore_last_char(t, .Invalid), true
		case:
			return make_token_ignore_last_char(t, .Int), true
		}
	// 123
	// 123.456
	case '1'..='9':
		for {
			switch next_char(t) {
			case '0'..='9': // continue
			case '.':
				return scan_fraction(t)
			case 'a'..='z', 'A'..='Z', '_':
				return make_token_ignore_last_char(t, .Invalid), true
			case:
				return make_token_ignore_last_char(t, .Int), true
			}
		}
	// Keywords and Identifiers
	case 'a'..='z', 'A'..='Z', '_':
		for {
			switch next_char(t) {
			case 'a'..='z', 'A'..='Z', '0'..='9', '_': continue
			}
			break
		}
		token = make_token_ignore_last_char(t, .Word)
	case:
		token = make_token(t, .Symbol)
	}

	scan_fraction :: proc "contextless" (t: ^Tokenizer) -> (token: Token, before_eof: bool) #optional_ok {
		switch next_char(t) {
		case '0'..='9': // continue
		case: return make_token_ignore_last_char(t, .Invalid), true
		}
		for {
			switch next_char(t) {
			case '0'..='9': // continue
			case 'a'..='z', 'A'..='Z', '_':
				return make_token_ignore_last_char(t, .Invalid), true
			case:
				return make_token_ignore_last_char(t, .Float), true
			}
		}
	}

	return
}

token_string :: #force_inline proc "contextless" (t: Token, src: string) -> string {
	return src[t.pos:][:t.len]
}
