/*
https://paulbourke.net/dataformats/obj

https://github.com/thisistherk/fast_obj
*/

package obj

import "base:runtime"
import "core:strings"

vec3   :: [3]f32
vec2   :: [2]f32

Vertex :: struct {
	position: vec3,
	color:    vec3,
}
Vertices :: #soa[]Vertex

// Texture :: struct {
// 	name: string, // Texture name from .mtl file
// 	path: string, // Resolved path to texture
// }

// Group :: struct {
// 	name        : string,
// 	face_count  : int, // Number of faces
// 	face_offset : int, // First face in fastObjMesh face_* arrays
// 	index_offset: int, // First index in fastObjMesh indices array
// }

// Face :: struct {
// 	verticis, material: int,
// }

// Mesh :: struct {
// 	/* Vertex data */
// 	positions : [dynamic]f32,
// 	texcoords : [dynamic]f32,
// 	normals   : [dynamic]f32,
// 	colors    : [dynamic]f32,

// 	// // Face data: one element for each face
// 	// faces     : #soa[dynamic]Face,

// 	// Index data: one element for each face vertex
// 	indices   : [dynamic]Index,
// }

Object :: struct {
	name:      string,
	material:  string,
	vertices:  #soa[dynamic]Vertex,
}

Data :: struct {
	objects:   [dynamic]Object,
	positions: [dynamic]vec3,
	texcoords: [dynamic]vec2,
	normals:   [dynamic]vec3,
	colors:    [dynamic]vec3,
	// mesh    : Mesh,   // Final mesh
	// object  : Group,  // Current object
	// group   : Group,  // Current group
	// material: int,    // Current material index
	// base    : string, // Base path for materials/textures
}

// flush_object :: proc (data: ^Data)
// {
//     /* Add object if not empty */
//     if data.object.face_count > 0 {
//         append(&data.objects, data.object)
// 	}

//     /* Reset for more data */
//     data.object = {
// 		face_offset  = len(data.faces),
// 		index_offset = len(data.indices),
// 	}
// }

// flush_group :: proc (data: ^Data)
// {
//     /* Add group if not empty */
//     if (data.group.face_count > 0) {
//         append(&data.groups, data.group)
// 	}

//     /* Reset for more data */
//     data.group = {
// 		face_offset  = len(data.faces),
// 		index_offset = len(data.indices),
// 	}
// }

object_make :: proc (data: ^Data) -> (g: Object) {
	g.vertices = make(#soa[dynamic]Vertex, 0, 32, data.objects.allocator)
	return
}

object_last :: proc (data: ^Data) -> (g: ^Object) {
	return &data.objects[len(data.objects)-1]
}

@private move :: #force_inline proc (ptr: ^[^]byte, amount := 1) {
	ptr ^= ([^]byte)(uintptr(ptr^) + uintptr(amount))
}


is_whitespace :: proc (c: byte) -> bool {return c == ' ' || c == '\t' || c == '\r'}
is_newline    :: proc (c: byte) -> bool {return c == '\n' || c == 0}
is_digit      :: proc (c: byte) -> bool {return c >= '0' && c <= '9'}
is_exponent   :: proc (c: byte) -> bool {return c == 'e' || c == 'E'}

skip_name :: proc (ptr: ^[^]byte)
{
	start := ptr^

	for !is_newline(ptr[0]) {
		move(ptr)
	}

	for ptr^ > start && is_whitespace(ptr[-1]) {
		move(ptr, -1)
	}
}


skip_whitespace :: proc (ptr: ^[^]byte)
{
	for is_whitespace(ptr[0]) {
		move(ptr)
	}
}


skip_line :: proc (ptr: ^[^]byte)
{
	for !is_newline(ptr[0]) {
		move(ptr)
	}
	move(ptr)
}

parse_name :: proc (ptr: ^[^]byte) -> string
{
	start := ptr^
	skip_name(ptr)
	end   := ptr^

	return string(start[:uintptr(end)-uintptr(start)])
}

parse_int :: proc (ptr: ^[^]byte) -> (val: int)
{
	sign, num: int

	if ptr[0] == '-' {
		sign = -1
		move(ptr)
	}
	else {
		sign = +1
	}

	num = 0
	for is_digit(ptr[0]) {
		num = 10 * num + int(ptr[0] - '0')
		move(ptr)
	}

	return sign * num
}

parse_float :: proc (ptr: ^[^]byte) -> f32
{
	skip_whitespace(ptr)

	sign: f64
	switch ptr[0] {
	case '+':
		sign = 1.0
		move(ptr)
	case '-':
		sign = -1.0
		move(ptr)
	case:
		sign = 1.0
	}


	num := 0.0
	for is_digit(ptr[0]) {
		num = 10 * num + f64(ptr[0] - '0')
		move(ptr)
	}

	if ptr[0] == '.' {
		move(ptr)
	}

	fra := 0.0
	div := 1.0

	for is_digit(ptr[0]) {
		fra  = 10 * fra + f64(ptr[0] - '0')
		div *= 10
		move(ptr)
	}

	num += fra / div

	if is_exponent(ptr[0]) {
		move(ptr)

		MAX_POWER    :: 20
		POWER_10_POS :: [MAX_POWER]f64{1.0e0, 1.0e1,  1.0e2,  1.0e3,  1.0e4,  1.0e5,  1.0e6,  1.0e7,  1.0e8,  1.0e9,  1.0e10,  1.0e11,  1.0e12,  1.0e13,  1.0e14,  1.0e15,  1.0e16,  1.0e17,  1.0e18,  1.0e19}
		POWER_10_NEG :: [MAX_POWER]f64{1.0e0, 1.0e-1, 1.0e-2, 1.0e-3, 1.0e-4, 1.0e-5, 1.0e-6, 1.0e-7, 1.0e-8, 1.0e-9, 1.0e-10, 1.0e-11, 1.0e-12, 1.0e-13, 1.0e-14, 1.0e-15, 1.0e-16, 1.0e-17, 1.0e-18, 1.0e-19}

		powers: [MAX_POWER]f64
		switch ptr[0] {
		case '+':
			powers = POWER_10_POS
			move(ptr)
		case '-':
			powers = POWER_10_NEG
			move(ptr)
		case:
			powers = POWER_10_POS
		}

		eval := 0
		for is_digit(ptr[0]) {
			eval = 10 * eval + int(ptr[0] - '0')
			move(ptr)
		}

		num *= eval >= MAX_POWER ? 0.0 : powers[eval]
	}

	return f32(sign * num)
}

parse_vec3 :: proc(ptr: ^[^]byte) -> vec3 {
	return {parse_float(ptr), parse_float(ptr), parse_float(ptr)}
}
parse_vec2 :: proc(ptr: ^[^]byte) -> vec2 {
	return {parse_float(ptr), parse_float(ptr)}
}

parse_vertex :: proc(data: ^Data, ptr: ^[^]byte) -> (err: runtime.Allocator_Error) {

	append(&data.positions, parse_vec3(ptr)) or_return

	skip_whitespace(ptr)
	if is_newline(ptr[0]) do return

	/* Fill the colors array until it matches the size of the positions array */
	for _ in len(data.colors) ..< len(data.positions)-1 {
		append(&data.colors, vec3{1, 1, 1}) or_return
	}

	append(&data.colors, parse_vec3(ptr)) or_return

	return
}

parse_texcoord :: proc (data: ^Data, ptr: ^[^]byte) -> (err: runtime.Allocator_Error) {

	append(&data.texcoords, parse_vec2(ptr)) or_return

	return
}

parse_normal :: proc (data: ^Data, ptr: ^[^]byte) -> (err: runtime.Allocator_Error) {

	append(&data.normals, parse_vec3(ptr)) or_return

	return
}

parse_face :: proc (data: ^Data, ptr: ^[^]byte) -> (err: runtime.Allocator_Error) {

	g := object_last(data)

	/*          1.
	             >----\               
	            x x    ---------\     
	           x   x             ----> 2.
	          x     x             -/  
	         x       x         --/    
	        x         x     --/       a b c
	       x           x  -/          1 2 3
	      <-------------</            1 3 4
		4.               3.           ...
	*/

	Index :: struct {
		// indices are base-1
		position, texcoord, normal: int,
	}
	indices: [3]Index
	
	for i := 0;; i += 1 {
		skip_whitespace(ptr)
		if is_newline(ptr[0]) do break

		index: Index

		index.position = parse_int(ptr)

		if ptr[0] == '/' {
			move(ptr)

			if ptr[0] != '/' {
				index.texcoord = parse_int(ptr)
			}

			if (ptr[0] == '/') {
				move(ptr)
				index.normal = parse_int(ptr)
			}
		}

		if index.position == 0 {
			return /* Skip lines with no valid vertex idx */
		}
		if index.position < 0 do index.position += len(data.positions)
		if index.texcoord < 0 do index.texcoord += len(data.texcoords)
		if index.normal   < 0 do index.normal   += len(data.normals)

		if i == 0 {
			indices[0] = index
		} else {
			indices[1] = indices[2]
			indices[2] = index
		}
		
		if i >= 2 {
			vertices: [3]Vertex
			for &v, i in vertices {
				idx := indices[i]
				v.position = data.positions[idx.position]
				// colors array is only filled if the colors data is in the file
				v.color = data.colors[idx.position] if idx.position < len(data.colors) else 1
			}
			append(&g.vertices, ..vertices[:]) or_return
		}
	}

	// append_soa(&data.faces, Face{
	// 	verticis = count,
	// 	material = data.material,
	// })

	// data.group.face_count  += 1
	// data.object.face_count += 1
	return
}

parse_object :: proc (data: ^Data, ptr: ^[^]byte)
{
	g := object_last(data)
	if (g.name != "") {
		append(&data.objects, object_make(data))
		g = &data.objects[len(data.objects)-1]
	}

	skip_whitespace(ptr)
	g.name = parse_name(ptr)
}

// parse_group :: proc (data: ^Data, ptr: ^[^]byte)
// {
//     flush_group(data)

//     skip_whitespace(ptr)
//     data.group.name = parse_name(ptr)
// }

parse_usemtl :: proc (data: ^Data, ptr: ^[^]byte) {

	g := object_last(data)
	assert(g.material == "")

	skip_whitespace(ptr)
	g.material = parse_name(ptr)
}

parse_line :: proc (data: ^Data, str: string) -> (err: runtime.Allocator_Error)
{
	ptr := raw_data(str)

	skip_whitespace(&ptr)

	switch ptr[0] {
	case 'v':
		move(&ptr)

		switch ptr[0] {
		case ' ', '\t':
			move(&ptr)
			parse_vertex(data, &ptr)
		case 't':
			move(&ptr)
			parse_texcoord(data, &ptr)
		case 'n':
			move(&ptr)
			parse_normal(data, &ptr)
		}

	case 'f':
		move(&ptr)

		switch ptr[0] {
		case ' ', '\t':
			move(&ptr)
			parse_face(data, &ptr)
		}

	case 'o':
		move(&ptr)

		switch ptr[0] {
		case ' ', '\t':
			move(&ptr)
			parse_object(data, &ptr)
		}

	// case 'g':
	// 	move(&ptr)

	// 	switch ptr[0] {
	// 	case ' ', '\t':
	// 		move(&ptr)
	// 		parse_group(data, &ptr)
	// 	}

	case 'm':
		move(&ptr)

		if ptr[0] == 't' &&
		   ptr[1] == 'l' &&
		   ptr[2] == 'l' &&
		   ptr[3] == 'i' &&
		   ptr[4] == 'b' &&
		   is_whitespace(ptr[5]) {
			// parse_mtllib(data, p + 5, callbacks, user_data)
		}

	case 'u':
		move(&ptr)

		if ptr[0] == 's' &&
		   ptr[1] == 'e' &&
		   ptr[2] == 'm' &&
		   ptr[3] == 't' &&
		   ptr[4] == 'l' &&
		   is_whitespace(ptr[5]) {
			move(&ptr, 5)
			parse_usemtl(data, &ptr)
		}
	}

	return
}

parse_file :: proc (
	src: string,
	allocator := context.allocator,
) -> (
	objects: []Object,
	err: runtime.Allocator_Error,
) #optional_allocator_error {
	
	data: Data

	// indices are base-1, add zero index to be able to index it normally
	data.positions  = make([dynamic]vec3,   1, 1024, context.temp_allocator)
	data.colors     = make([dynamic]vec3,   1, 1024, context.temp_allocator)
	data.texcoords  = make([dynamic]vec2,   1, 1024, context.temp_allocator)
	data.normals    = make([dynamic]vec3,   1, 1024, context.temp_allocator)
	
	data.objects    = make([dynamic]Object, 1,  4, allocator)
	data.objects[0] = object_make(&data)

	it := src
	for line in strings.split_lines_iterator(&it) {
		parse_line(&data, line) or_return
	}

	return data.objects[:], nil
}
