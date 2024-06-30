package obj


// Texture :: struct {
// 	name: string, // Texture name from .mtl file
// 	path: string, // Resolved path to texture
// }

Index :: struct {
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

Data :: struct {
	positions : [dynamic]f32,
	texcoords : [dynamic]f32,
	normals   : [dynamic]f32,
	colors    : [dynamic]f32,
	indices   : [dynamic]Index,
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
	data.positions = make([dynamic]f32  , 0, 32, allocator)
	data.normals   = make([dynamic]f32  , 0, 32, allocator)
	data.texcoords = make([dynamic]f32  , 0, 32, allocator)
	data.colors    = make([dynamic]f32  , 0, 32, allocator)
	data.indices   = make([dynamic]Index, 0, 32, allocator)
}

@private increase :: #force_inline proc (ptr: ^[^]byte, amount := 1)
{
	ptr ^= ([^]byte)(uintptr(ptr^) + uintptr(amount))
}
@private decrease :: #force_inline proc (ptr: ^[^]byte, amount := 1)
{
	ptr ^= ([^]byte)(uintptr(ptr^) - uintptr(amount))
}

is_whitespace :: proc (c: byte) -> bool
{
	return c == ' ' || c == '\t' || c == '\r'
}

is_newline :: proc (c: byte) -> bool
{
	return c == '\n'
}

is_digit :: proc (c: byte) -> bool
{
	return c >= '0' && c <= '9'
}

is_exponent :: proc (c: byte) -> bool
{
	return c == 'e' || c == 'E'
}

skip_name :: proc (ptr: ^[^]byte)
{
	start := ptr^

	for !is_newline(ptr[0]) {
		increase(ptr)
	}

	for ptr^ > start && is_whitespace(ptr[-1]) {
		decrease(ptr)
	}
}


skip_whitespace :: proc (ptr: ^[^]byte)
{
	for is_whitespace(ptr[0]) {
		increase(ptr)
	}
}


skip_line :: proc (ptr: ^[^]byte)
{
	for !is_newline(ptr[0]) {
		increase(ptr)
	}
	increase(ptr)
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
		increase(ptr)
	}
	else {
		sign = +1
	}

	num = 0
	for is_digit(ptr[0]) {
		num = 10 * num + int(ptr[0] - '0')
		increase(ptr)
	}

	return sign * num
}

/* Max supported power when parsing float */
MAX_POWER   :: 20

POWER_10_POS :: [MAX_POWER]f64{
	1.0e0,  1.0e1,  1.0e2,  1.0e3,  1.0e4,  1.0e5,  1.0e6,  1.0e7,  1.0e8,  1.0e9,
	1.0e10, 1.0e11, 1.0e12, 1.0e13, 1.0e14, 1.0e15, 1.0e16, 1.0e17, 1.0e18, 1.0e19,
}

POWER_10_NEG :: [MAX_POWER]f64{
	1.0e0,   1.0e-1,  1.0e-2,  1.0e-3,  1.0e-4,  1.0e-5,  1.0e-6,  1.0e-7,  1.0e-8,  1.0e-9,
	1.0e-10, 1.0e-11, 1.0e-12, 1.0e-13, 1.0e-14, 1.0e-15, 1.0e-16, 1.0e-17, 1.0e-18, 1.0e-19,
}

parse_float :: proc (ptr: ^[^]byte) -> f32
{
	skip_whitespace(ptr)
	
	sign: f64
	switch ptr[0] {
	case '+':
		sign = 1.0
		increase(ptr)
	case '-':
		sign = -1.0
		increase(ptr)
	case:
		sign = 1.0
	}


	num := 0.0
	for is_digit(ptr[0]) {
		num = 10 * num + f64(ptr[0] - '0')
		increase(ptr)
	}

	if ptr[0] == '.' {
		increase(ptr)
	}

	fra := 0.0
	div := 1.0

	for is_digit(ptr[0]) {
		fra  = 10 * fra + f64(ptr[0] - '0')
		div *= 10
		increase(ptr)
	}

	num += fra / div

	if is_exponent(ptr[0]) {
		increase(ptr)

		powers: [MAX_POWER]f64
		switch ptr[0] {
		case '+':
			powers = POWER_10_POS
			increase(ptr)
		case '-':
			powers = POWER_10_NEG
			increase(ptr)
		case:
			powers = POWER_10_POS
		}

		eval := 0
		for is_digit(ptr[0]) {
			eval = 10 * eval + int(ptr[0] - '0')
			increase(ptr)
		}
		
		num *= eval >= MAX_POWER ? 0.0 : powers[eval]
	}

	return f32(sign * num)
}

parse_vertex :: proc(data: ^Data, ptr: ^[^]byte)
{
	for _ in 0..<3 {
		append(&data.positions, parse_float(ptr))
	}

	skip_whitespace(ptr)
	if is_newline(ptr[0]) do return

	/* Fill the colors array until it matches the size of the positions array */
	for _ in 0 ..< len(data.positions) - 3 - len(data.colors) {
		append(&data.colors, 1.0)
	}

	for _ in 0..<3 {
		append(&data.colors, parse_float(ptr))
	}
}

parse_texcoord :: proc (data: ^Data, ptr: ^[^]byte)
{
	for _ in 0..<2 {
		append(&data.texcoords, parse_float(ptr))
	}
}

parse_normal :: proc (data: ^Data, ptr: ^[^]byte)
{
	for _ in 0..<3 {
		append(&data.normals, parse_float(ptr))
	}
}

parse_face :: proc (data: ^Data, ptr: ^[^]byte)
{
	// count: int
	for {
		skip_whitespace(ptr)
		if is_newline(ptr[0]) do break

		index: Index

		index.position = parse_int(ptr)
		if index.position == 0 do return /* Skip lines with no valid vertex index */

		if ptr[0] == '/' {
			increase(ptr)

            if ptr[0] != '/' {
                index.texcoord = parse_int(ptr)
			}

            if (ptr[0] == '/') {
                increase(ptr)
                index.normal = parse_int(ptr)
            }
		}

		if index.position < 0 do index.position += len(data.positions) / 3
		if index.texcoord < 0 do index.texcoord += len(data.texcoords) / 2
		if index.normal   < 0 do index.normal   += len(data.normals)   / 3

		append(&data.indices, index)
		// count += 1
	}

	// append_soa(&data.faces, Face{
	// 	verticis = count,
	// 	material = data.material,
	// })

	// data.group.face_count  += 1
	// data.object.face_count += 1
}

// parse_object :: proc (data: ^Data, ptr: ^[^]byte)
// {
//     flush_object(data)

//     skip_whitespace(ptr)
//     data.object.name = parse_name(ptr)
// }

// parse_group :: proc (data: ^Data, ptr: ^[^]byte)
// {
//     flush_group(data)
	
//     skip_whitespace(ptr)
//     data.group.name = parse_name(ptr)
// }

// parse_usemtl :: proc (data: ^Data, ptr: ^[^]byte)
// {
//     skip_whitespace(ptr)
// 	name := parse_name(ptr)
	
// 	/* Find an existing material with the same name */
// 	for mtl, i in data.materials {
// 		if mtl.name == name {
// 			data.material = i
// 			return
// 		}
// 	}

// 	/* If doesn't exist, create a default one with this name
// 	   Note: this case happens when OBJ doesn't have its MTL */
// 	data.material = len(data.materials)
// 	append(&data.materials, Material{ // TODO this should be initialized I think
// 		name     = name,
// 		fallback = 1,
// 	})
// }

parse_line :: proc (data: ^Data, str: string)
{
	ptr := raw_data(str)

	skip_whitespace(&ptr)

	switch ptr[0] {
	case 'v':
		increase(&ptr)

		switch ptr[0] {
		case ' ', '\t':
			increase(&ptr)
			parse_vertex(data, &ptr)
		case 't':
			increase(&ptr)
			parse_texcoord(data, &ptr)
		case 'n':
			increase(&ptr)
			parse_normal(data, &ptr)
		}

	case 'f':
		increase(&ptr)

		switch ptr[0] {
		case ' ', '\t':
			increase(&ptr)
			parse_face(data, &ptr)
		}

	case 'o':
		increase(&ptr)

		switch ptr[0] {
		case ' ', '\t':
			// increase(&ptr)
			// parse_object(data, &ptr)
		}

	case 'g':
		increase(&ptr)

		switch ptr[0] {
		case ' ', '\t':
			// increase(&ptr)
			// parse_group(data, &ptr)
		}

	case 'm':
		increase(&ptr)

		if ptr[0] == 't' &&
		   ptr[1] == 'l' &&
		   ptr[2] == 'l' &&
		   ptr[3] == 'i' &&
		   ptr[4] == 'b' &&
		   is_whitespace(ptr[5]) {
			// parse_mtllib(data, p + 5, callbacks, user_data)
		}

	case 'u':
		increase(&ptr)
		
		if ptr[0] == 's' &&
		   ptr[1] == 'e' &&
		   ptr[2] == 'm' &&
		   ptr[3] == 't' &&
		   ptr[4] == 'l' &&
		   is_whitespace(ptr[5]) {
			// increase(&ptr, 5)
			// parse_usemtl(data, &ptr)
		}
	}

    // if len(data.colors) > 0 {
    //     /* Fill the remaining slots in the colors array */
	// 	for _ in 0 ..< len(data.positions) - len(data.colors) {
	// 		append(&data.colors, 1)
	// 	}
    // }
}
