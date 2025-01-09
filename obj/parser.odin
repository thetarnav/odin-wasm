/*
https://paulbourke.net/dataformats/obj

https://github.com/thisistherk/fast_obj
*/

package obj

vec3   :: [3]f32
vec2   :: [2]f32
u8vec4 :: [4]u8

// Texture :: struct {
// 	name: string, // Texture name from .mtl file
// 	path: string, // Resolved path to texture
// }

Index :: struct {
	/* 
	 indices are base-1
	*/
	position: int,
	texcoord: int,
	normal  : int,
}

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
	indices:   [dynamic][]Index,
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

init_data :: proc (data: ^Data, allocator := context.allocator) {

	// indices are base-1, add zero index to be able to index it normally
	data.positions  = make([dynamic]vec3,   1, 32, allocator)
	data.texcoords  = make([dynamic]vec2,   1, 32, allocator)
	data.normals    = make([dynamic]vec3,   1, 32, allocator)

	data.colors     = make([dynamic]vec3,   0, 32, allocator)
	data.objects    = make([dynamic]Object, 1,  4, allocator)
	data.objects[0] = object_make(data)
}
data_init :: init_data

data_make :: proc (allocator := context.allocator) -> (data: Data) {
	init_data(&data)
	return
}

object_make :: proc (data: ^Data) -> (g: Object) {
	g.indices   = make([dynamic][]Index, 0, 32, data.objects.allocator)
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

parse_vertex :: proc(data: ^Data, ptr: ^[^]byte) {

	append(&data.positions, parse_vec3(ptr))

	skip_whitespace(ptr)
	if is_newline(ptr[0]) do return

	/* Fill the colors array until it matches the size of the positions array */
	for _ in len(data.colors) ..< len(data.positions)-1 {
		append(&data.colors, vec3{1, 1, 1})
	}

	append(&data.colors, parse_vec3(ptr))
}

parse_texcoord :: proc (data: ^Data, ptr: ^[^]byte) {

	append(&data.texcoords, parse_vec2(ptr))
}

parse_normal :: proc (data: ^Data, ptr: ^[^]byte) {

	append(&data.normals, parse_vec3(ptr))
}

parse_face :: proc (data: ^Data, ptr: ^[^]byte) {

	g := object_last(data)

	indices := make([dynamic]Index, 0, 3, g.indices.allocator)

	for {
		skip_whitespace(ptr)
		if is_newline(ptr[0]) do break

		idx: Index

		idx.position = parse_int(ptr)
		
		if ptr[0] == '/' {
			move(ptr)

			if ptr[0] != '/' {
				idx.texcoord = parse_int(ptr)
			}

			if (ptr[0] == '/') {
				move(ptr)
				idx.normal = parse_int(ptr)
			}
		}
		
		if idx.position == 0 {
			return /* Skip lines with no valid vertex idx */
		}
		if idx.position < 0 do idx.position += len(data.positions)
		if idx.texcoord < 0 do idx.texcoord += len(data.texcoords)
		if idx.normal   < 0 do idx.normal   += len(data.normals)

		append(&indices, idx)
	}

	assert(len(indices) >= 3)
	append(&g.indices, indices[:])

	// append_soa(&data.faces, Face{
	// 	verticis = count,
	// 	material = data.material,
	// })

	// data.group.face_count  += 1
	// data.object.face_count += 1
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

parse_line :: proc (data: ^Data, str: string)
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
}

Vertex :: struct {
	pos: vec3,
	col: vec3,
}
Vertices :: #soa[]Vertex

vertex_get_from_index :: proc (data: Data, idx: Index) -> (v: Vertex) {
	v.pos = data.positions[idx.position]
	// colors array is only filled if the colors data is in the file
	v.col = data.colors[idx.position] if idx.position < len(data.colors) else 1
	return
}

object_to_triangles :: proc (data: Data, g: Object, allocator := context.allocator) -> Vertices {

	vertices := make(#soa[dynamic]Vertex, 0, 3*len(g.indices), allocator)

	for indices in g.indices {
		for i in 2 ..< len(indices) {
			a, b, c := indices[0], indices[i-1], indices[i]
			append(&vertices, ..[]Vertex{
				vertex_get_from_index(data, a),
				vertex_get_from_index(data, b),
				vertex_get_from_index(data, c),
			})
		}
	}

	return vertices[:]
}

object_to_lines :: proc (data: Data, g: Object, allocator := context.allocator) -> Vertices {

	vertices := make(#soa[dynamic]Vertex, 0, 6*len(g.indices), allocator)

	for indices in g.indices {
		for i in 2 ..< len(indices) {
			a, b, c := indices[0], indices[i-1], indices[i]
			append(&vertices, ..[]Vertex{
				vertex_get_from_index(data, a),
				vertex_get_from_index(data, b),
				vertex_get_from_index(data, b),
				vertex_get_from_index(data, c),
				vertex_get_from_index(data, c),
				vertex_get_from_index(data, a),
			})
		}
	}

	return vertices[:]
}
