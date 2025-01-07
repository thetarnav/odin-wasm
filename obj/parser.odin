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
	 indices start ar 1
	 zero means it points to nowhere
	 `data.positions[idx.position-1]`
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

Geometry :: struct {
	positions: [dynamic]vec3,
	texcoords: [dynamic]vec2,
	normals:   [dynamic]vec3,
	colors:    [dynamic]vec3,
	indices:   [dynamic][]Index,
	material:  string,
}

Data :: struct {
	geometry: [dynamic]Geometry,
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
	data.geometry = make([dynamic]Geometry, 1, allocator)
	data.geometry[0] = geometry_make(data)
}
data_init :: init_data

data_make :: proc (allocator := context.allocator) -> (data: Data) {
	init_data(&data)
	return
}

geometry_make :: proc (data: ^Data) -> (g: Geometry) {
	g.positions = make([dynamic]vec3,    0, 32, data.geometry.allocator)
	g.texcoords = make([dynamic]vec2,    0, 32, data.geometry.allocator)
	g.normals   = make([dynamic]vec3,    0, 32, data.geometry.allocator)
	g.colors    = make([dynamic]vec3,    0, 32, data.geometry.allocator)
	g.indices   = make([dynamic][]Index, 0, 32, data.geometry.allocator)
	return
}

geometry_last :: proc (data: ^Data) -> (g: ^Geometry) {
	return &data.geometry[len(data.geometry)-1]
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

	g := geometry_last(data)
	if (g.material != "") {
		append(&data.geometry, geometry_make(data))
		g = &data.geometry[len(data.geometry)-1]
	}

	append(&g.positions, parse_vec3(ptr))

	skip_whitespace(ptr)
	if is_newline(ptr[0]) do return

	/* Fill the colors array until it matches the size of the positions array */
	for _ in len(g.colors) ..< len(g.positions)-1 {
		append(&g.colors, vec3{1, 1, 1})
	}

	append(&g.colors, parse_vec3(ptr))
}

parse_texcoord :: proc (data: ^Data, ptr: ^[^]byte) {

	g := geometry_last(data)
	if (g.material != "") {
		append(&data.geometry, geometry_make(data))
		g = &data.geometry[len(data.geometry)-1]
	}

	append(&g.texcoords, parse_vec2(ptr))
}

parse_normal :: proc (data: ^Data, ptr: ^[^]byte) {

	g := geometry_last(data)
	if (g.material != "") {
		append(&data.geometry, geometry_make(data))
		g = &data.geometry[len(data.geometry)-1]
	}

	append(&g.normals, parse_vec3(ptr))
}

parse_face :: proc (data: ^Data, ptr: ^[^]byte) {

	g := geometry_last(data)

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
		if idx.position < 0 do idx.position += len(g.positions)
		if idx.texcoord < 0 do idx.texcoord += len(g.texcoords)
		if idx.normal   < 0 do idx.normal   += len(g.normals)

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

// parse_object :: proc (data: ^Data, ptr: ^[^]byte)
// {
//	 flush_object(data)

//     skip_whitespace(ptr)
//     data.object.name = parse_name(ptr)
// }

// parse_group :: proc (data: ^Data, ptr: ^[^]byte)
// {
//     flush_group(data)
	
//     skip_whitespace(ptr)
//     data.group.name = parse_name(ptr)
// }

parse_usemtl :: proc (data: ^Data, ptr: ^[^]byte) {

	skip_whitespace(ptr)	
	name := parse_name(ptr)

	g := geometry_last(data)
	if (g.material != "") {
		append(&data.geometry, geometry_make(data))
		g = &data.geometry[len(data.geometry)-1]
	}

	g.material = name
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
			// increase(&ptr)
			// parse_object(data, &ptr)
		}

	case 'g':
		move(&ptr)

		switch ptr[0] {
		case ' ', '\t':
			// increase(&ptr)
			// parse_group(data, &ptr)
		}

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
			// increase(&ptr, 5)
			parse_usemtl(data, &ptr)
		}
	}

	// if len(data.colors) > 0 {
	//     /* Fill the remaining slots in the colors array */
	// 	for _ in 0 ..< len(data.positions) - len(data.colors) {
	// 		append(&data.colors, 1)
	// 	}
	// }
}

Vertex :: struct {
	pos: vec3,
	col: u8vec4,
}
Vertices :: #soa[]Vertex

geometry_to_triangles :: proc (g: Geometry, allocator := context.allocator) -> Vertices {

	vertices := make(#soa[dynamic]Vertex, 0, 3*len(g.indices), allocator)

	for indices in g.indices {
		for i in 2 ..< len(indices) {
			a, b, c := indices[0], indices[i-1], indices[i]
			append(&vertices, ..[]Vertex{
				{pos = g.positions[a.position-1]},
				{pos = g.positions[b.position-1]},
				{pos = g.positions[c.position-1]},
			})
		}
	}

	return vertices[:]
}

geometry_to_lines :: proc (g: Geometry, allocator := context.allocator) -> Vertices {

	vertices := make(#soa[dynamic]Vertex, 0, 6*len(g.indices), allocator)

	for indices in g.indices {
		for i in 2 ..< len(indices) {
			a, b, c := indices[0], indices[i-1], indices[i]
			append(&vertices, ..[]Vertex{
				{pos = g.positions[a.position-1]},
				{pos = g.positions[b.position-1]},
				{pos = g.positions[b.position-1]},
				{pos = g.positions[c.position-1]},
				{pos = g.positions[c.position-1]},
				{pos = g.positions[a.position-1]},
			})
		}
	}

	return vertices[:]
}
