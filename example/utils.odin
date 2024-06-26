package example

import     "base:intrinsics"
import     "core:math/rand"
import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

float  :: f32
double :: f64
vec2   :: glm.vec2
vec3   :: glm.vec3
vec4   :: glm.vec4
ivec2  :: glm.ivec2
ivec3  :: glm.ivec3
ivec4  :: glm.ivec4
uvec2  :: glm.uvec2
uvec3  :: glm.uvec3
uvec4  :: glm.uvec4
bvec2  :: distinct [2]b32
bvec3  :: distinct [3]b32
bvec4  :: distinct [4]b32
mat2   :: glm.mat2
mat3   :: glm.mat3
mat4   :: glm.mat4
u8vec4 :: [4]u8
rgba   :: u8vec4

TAU	   :: glm.TAU
PI     :: glm.PI
VAO    :: gl.VertexArrayObject

mod       :: glm.mod
radians   :: glm.radians_f32
cos       :: glm.cos
sin       :: glm.sin
tan       :: glm.tan
dot       :: glm.dot
cross     :: glm.cross
normalize :: glm.normalize
lerp      :: glm.lerp
distance  :: glm.distance
sqrt      :: glm.sqrt

cbrt :: #force_inline proc "contextless" (x: f32) -> f32 {
	return x * x * x
}

UP    :: vec3{ 0, 1, 0}
DOWN  :: vec3{ 0,-1, 0}
LEFT  :: vec3{-1, 0, 0}
RIGHT :: vec3{ 1, 0, 0}
FRONT :: vec3{ 0, 0, 1}
BACK  :: vec3{ 0, 0,-1}

ratio :: distinct f32
rvec2 :: distinct [2]f32

to_px :: proc(r: rvec2) -> vec2 {
	return vec2(r) * window_size * dpr
}
to_rvec2 :: proc(p: vec2) -> rvec2 {
	return rvec2(p / window_size * dpr)
}

u8vec4_to_vec4 :: #force_inline proc "contextless" (rgba: u8vec4) -> vec4 {
	return {f32(rgba.r)/255, f32(rgba.g)/255, f32(rgba.b)/255, f32(rgba.a)/255}
}
rgba_to_vec4 :: u8vec4_to_vec4

to_rgba_3_1 :: #force_inline proc "contextless" (color: $A/[3]u8, a: u8) -> rgba {
	return {color.r, color.g, color.b, a}
}
to_rgba :: proc {to_rgba_3_1}

copy_array :: #force_inline proc "contextless" (dst: []$S, src: [$N]S) {
	src := src
	copy(dst, src[:])
}

copy_pattern :: #force_inline proc "contextless" (dst: []$S, src: []S) #no_bounds_check {
	for i in 0..<len(dst)/len(src) {
		copy(dst[i*len(src):][:len(src)], src)
	}
}

// cast_vec2 :: #force_inline proc "contextless" ($D: typeid, v: [2]$S) -> [2]D
// 	where intrinsics.type_is_numeric(S),
// 	      intrinsics.type_is_numeric(D) {
// 	return {D(v.x), D(v.y)}
// }

cast_vec2 :: #force_inline proc "contextless" (v: $T/[2]$S) -> vec2
	where intrinsics.type_is_numeric(S) {
	return {f32(v.x), f32(v.y)}
}
cast_ivec2 :: #force_inline proc "contextless" (v: $T/[2]$S) -> ivec2
	where intrinsics.type_is_numeric(S) {
	return {i32(v.x), i32(v.y)}
}

vec2_to_vec3 :: #force_inline proc "contextless" (v: $T/[2]f32, z: f32 = 0) -> vec3 {
	return {v.x, v.y, z}
}

rand_color :: proc() -> u8vec4 {
	color := transmute(u8vec4)rand.uint32()
	color.a = 255
	return color
}
rand_color_gray :: proc() -> u8vec4 {
	l := u8(rand.uint64())/4 + 256/2 + 256/4
	return {l, l, l, 255}
}
rand_colors :: proc(colors: []u8vec4) {
	assert(len(colors)%3 == 0)
	for i in 0 ..< len(colors)/3 {
		color := rand_color()
		colors[i*3+0] = color
		colors[i*3+1] = color
		colors[i*3+2] = color
	}
}
rand_colors_gray :: proc(colors: []u8vec4) {
	assert(len(colors)%3 == 0)
	for i in 0..<len(colors)/3 {
		color := rand_color_gray()
		colors[i*3+0] = color
		colors[i*3+1] = color
		colors[i*3+2] = color
	}
}

@(require_results)
vec2_angle :: proc "contextless" (a, b: vec2) -> f32 {
	return glm.atan2(a.y - b.y, a.x - b.x)
}
@(require_results)
mat3_translate :: proc "contextless" (v: vec2) -> mat3 {
	return {
		1, 0, v.x,
		0, 1, v.y,
		0, 0, 1,
   	}
}
@(require_results)
mat3_scale :: proc "contextless" (v: vec2) -> mat3 {
	return {
		v.x, 0,   0,
		0,   v.y, 0,
		0,   0,   1,
   	}
}
@(require_results)
mat3_rotate :: proc "contextless" (angle: f32) -> mat3 {
	c := cos(angle)
	s := sin(angle)
	return {
		 c, s, 0,
		-s, c, 0,
		 0, 0, 1,
	}
}
@(require_results)
mat3_projection :: proc "contextless" (size: vec2) -> mat3 {
	return {
		2/size.x, 0,       -1,
		0,       -2/size.y, 1,
		0,        0,        1,
	}
}

mat4_inverse   :: glm.inverse_mat4

@(require_results)
mat4_translate :: proc "contextless" (v: vec3) -> mat4 {
	return {
		1, 0, 0, v.x,
		0, 1, 0, v.y,
		0, 0, 1, v.z,
		0, 0, 0, 1,
	}
}
@(require_results)
mat4_scale :: proc "contextless" (v: vec3) -> (m: mat4) {
	return {
		v.x, 0,   0,   0,
		0,   v.y, 0,   0,
		0,   0,   v.z, 0,
		0,   0,   0,   1,
	}
}
@(require_results)
mat4_rotate_x :: proc "contextless" (radians: f32) -> mat4 {
	c := cos(radians)
	s := sin(radians)

	return {
		1, 0, 0, 0,
		0, c, s, 0,
		0,-s, c, 0,
		0, 0, 0, 1,
	}
}
@(require_results)
mat4_rotate_y :: proc "contextless" (radians: f32) -> mat4 {
	c := cos(radians)
	s := sin(radians)

	return {
		c, 0,-s, 0,
		0, 1, 0, 0,
		s, 0, c, 0,
		0, 0, 0, 1,
	}
}
@(require_results)
mat4_rotate_z :: proc "contextless" (radians: f32) -> mat4 {
	c := cos(radians)
	s := sin(radians)

	return {
		c,  s, 0, 0,
		-s, c, 0, 0,
		0,  0, 1, 0,
		0,  0, 0, 1,
	}
}
@(require_results)
mat4_rotate_vec :: #force_inline proc "contextless" (v: vec3) -> mat4 {
	return mat4_rotate_x(v.x) * mat4_rotate_y(v.y) * mat4_rotate_z(v.z)
}
@(require_results)
mat4_perspective :: proc "contextless" (fov, aspect, near, far: f32) -> mat4 {
    f    : f32 = tan(fov*0.5)
    range: f32 = 1 / (near - far)

    return {
		f/aspect, 0, 0,                    0,
		0,        f, 0,                    0,
		0,        0, (near + far) * range, near * far * range * 2,
		0,        0, -1,                   0,
	}
}
@(require_results)
mat4_look_at :: proc "contextless" (eye, target, up: vec3) -> mat4 {
	// f  := normalize(target - eye)
	// s  := normalize(cross(f, up))
	// u  := cross(s, f)
	// fe := dot(f, eye)

	// return {
	// 	+s.x, +s.y, +s.z, -dot(s, eye),
	// 	+u.x, +u.y, +u.z, -dot(u, eye),
	// 	-f.x, -f.y, -f.z, +fe,
	// 	0,    0,    0,    1,
	// }

	z := normalize(eye - target)
	x := normalize(cross(up, z))
	y := normalize(cross(z, x))

	return {
		x.x, y.x, z.x, eye.x,
		x.y, y.y, z.y, eye.y,
		x.z, y.z, z.z, eye.z,
		0,   0,   0,   1,
	}
}

// Rotates a vector around an axis
@(require_results)
vec3_rotate :: proc "contextless" (v, axis: vec3, angle: f32) -> vec3 {
	axis, angle := axis, angle

	axis = normalize(axis)

	angle *= 0.5
	a := sin(angle)
	b := axis.x*a
	c := axis.y*a
	d := axis.z*a
	a = cos(angle)
	w := vec3{b, c, d}

	wv := cross(w, v)
	wwv := cross(w, wv)

	a *= 2
	wv *= a

	wwv *= 2

	return v + wv + wwv
}

vec3_transform :: proc "contextless" (v: vec3, m: mat4) -> vec3 {
    w := m[0][3] * v.x + m[1][3] * v.y + m[2][3] * v.z + m[3][3]

    return {
        (m[0][0] * v.x + m[1][0] * v.y + m[2][0] * v.z + m[3][0]) / w,
        (m[0][1] * v.x + m[1][1] * v.y + m[2][1] * v.z + m[3][1]) / w,
        (m[0][2] * v.x + m[1][2] * v.y + m[2][2] * v.z + m[3][2]) / w,
	}
}

vec2_transform :: proc "contextless" (v: vec2, m: mat3) -> vec2 {
	return {
		v.x * m[0].x + v.y * m[1].x + m[2].x,
		v.x * m[0].y + v.y * m[1].y + m[2].y,
	}
}

normals_from_positions :: proc(dst, src: []vec3) {
	assert(len(dst) >= len(src))
	assert(len(src) % 3 == 0)

	for i in 0..<len(src)/3 {
		a := src[i*3+0]
		b := src[i*3+1]
		c := src[i*3+2]

		normal := normalize(cross(b - a, c - a))

		dst[i*3+0] = normal
		dst[i*3+1] = normal
		dst[i*3+2] = normal
	}
}

vec3_on_radius :: proc (r, a, y: f32) -> vec3 {
	return {r * cos(a), y, r * sin(a)}
}


Attribute_int   :: distinct i32
Attribute_ivec2 :: distinct i32
Attribute_ivec3 :: distinct i32
Attribute_ivec4 :: distinct i32
Attribute_uint  :: distinct i32
Attribute_uvec2 :: distinct i32
Attribute_uvec3 :: distinct i32
Attribute_uvec4 :: distinct i32
Attribute_bool  :: distinct i32
Attribute_bvec2 :: distinct i32
Attribute_bvec3 :: distinct i32
Attribute_bvec4 :: distinct i32
Attribute_float :: distinct i32
Attribute_vec2  :: distinct i32
Attribute_vec3  :: distinct i32
Attribute_vec4  :: distinct i32
Attribute_mat2  :: distinct i32
Attribute_mat3  :: distinct i32
Attribute_mat4  :: distinct i32

@require_results attribute_location_int   :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_int   {
	loc := Attribute_int  (#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_ivec2 :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_ivec2 {
	loc := Attribute_ivec2(#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_ivec3 :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_ivec3 {
	loc := Attribute_ivec3(#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_ivec4 :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_ivec4 {
	loc := Attribute_ivec4(#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_uint  :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_uint  {
	loc := Attribute_uint (#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_uvec2 :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_uvec2 {
	loc := Attribute_uvec2(#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_uvec3 :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_uvec3 {
	loc := Attribute_uvec3(#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_uvec4 :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_uvec4 {
	loc := Attribute_uvec4(#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_bool  :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_bool  {
	loc := Attribute_bool (#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_bvec2 :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_bvec2 {
	loc := Attribute_bvec2(#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_bvec3 :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_bvec3 {
	loc := Attribute_bvec3(#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_bvec4 :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_bvec4 {
	loc := Attribute_bvec4(#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_float :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_float {
	loc := Attribute_float(#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_vec2  :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_vec2  {
	loc := Attribute_vec2 (#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_vec3  :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_vec3  {
	loc := Attribute_vec3 (#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_vec4  :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_vec4  {
	loc := Attribute_vec4 (#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_mat2  :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_mat2  {
	loc := Attribute_mat2 (#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}
@require_results attribute_location_mat3  :: #force_inline proc "contextless" (program: gl.Program, name: string, enable: bool = true) -> Attribute_mat3  {
	loc := Attribute_mat3 (#force_inline gl.GetAttribLocation(program, name))
	if enable do gl.EnableVertexAttribArray(i32(loc))
	return loc
}

attribute_int    :: proc "contextless" (loc: Attribute_int, buffer: gl.Buffer, data: []i32) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 3, gl.INT, false, 0, 0)
}
attribute_ivec2  :: proc "contextless" (loc: Attribute_ivec2, buffer: gl.Buffer, data: []ivec2) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 2, gl.INT, false, 0, 0)
}
attribute_ivec3  :: proc "contextless" (loc: Attribute_ivec3, buffer: gl.Buffer, data: []ivec3) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 3, gl.INT, false, 0, 0)
}
attribute_ivec4  :: proc "contextless" (loc: Attribute_ivec4, buffer: gl.Buffer, data: []ivec4) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 4, gl.INT, false, 0, 0)
}
attribute_uint   :: proc "contextless" (loc: Attribute_uint, buffer: gl.Buffer, data: []u32) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 3, gl.UNSIGNED_INT, false, 0, 0)
}
attribute_uvec2  :: proc "contextless" (loc: Attribute_uvec2, buffer: gl.Buffer, data: []uvec2) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 2, gl.UNSIGNED_INT, false, 0, 0)
}
attribute_uvec3  :: proc "contextless" (loc: Attribute_uvec3, buffer: gl.Buffer, data: []uvec3) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 3, gl.UNSIGNED_INT, false, 0, 0)
}
attribute_uvec4  :: proc "contextless" (loc: Attribute_uvec4, buffer: gl.Buffer, data: []uvec4) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 4, gl.UNSIGNED_INT, false, 0, 0)
}
attribute_bool   :: proc "contextless" (loc: Attribute_bool, buffer: gl.Buffer, data: []b32) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, transmute([]u32)data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 3, gl.UNSIGNED_INT, false, 0, 0)
}
attribute_bvec2  :: proc "contextless" (loc: Attribute_bvec2, buffer: gl.Buffer, data: []bvec2) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, transmute([]uvec2)data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 2, gl.UNSIGNED_INT, false, 0, 0)
}
attribute_bvec3  :: proc "contextless" (loc: Attribute_bvec3, buffer: gl.Buffer, data: []bvec3) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, transmute([]uvec3)data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 3, gl.UNSIGNED_INT, false, 0, 0)
}
attribute_bvec4  :: proc "contextless" (loc: Attribute_bvec4, buffer: gl.Buffer, data: []bvec4) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, transmute([]uvec4)data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 4, gl.UNSIGNED_INT, false, 0, 0)
}
attribute_float  :: proc "contextless" (loc: Attribute_float, buffer: gl.Buffer, data: []f32) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 3, gl.FLOAT, false, 0, 0)
}
attribute_vec2   :: proc "contextless" (loc: Attribute_vec2, buffer: gl.Buffer, data: []vec2) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 2, gl.FLOAT, false, 0, 0)
}
attribute_vec3   :: proc "contextless" (loc: Attribute_vec3, buffer: gl.Buffer, data: []vec3) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 3, gl.FLOAT, false, 0, 0)
}
attribute_vec4   :: proc "contextless" (loc: Attribute_vec4, buffer: gl.Buffer, data: []vec4) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 4, gl.FLOAT, false, 0, 0)
}
attribute_u8vec4 :: proc "contextless" (loc: Attribute_vec4, buffer: gl.Buffer, data: []u8vec4) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 4, gl.UNSIGNED_BYTE, true, 0, 0)
}
attribute_mat2   :: proc "contextless" (loc: Attribute_mat2, buffer: gl.Buffer, data: []mat2) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 4, gl.FLOAT, false, 0, 0)
}
attribute_mat3   :: proc "contextless" (loc: Attribute_mat3, buffer: gl.Buffer, data: []mat3) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 9, gl.FLOAT, false, 0, 0)
}
attribute_mat4   :: proc "contextless" (loc: Attribute_mat4, buffer: gl.Buffer, data: []mat4) {
	gl.BindBuffer(gl.ARRAY_BUFFER, buffer)
	#force_inline gl.BufferDataSlice(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
	gl.VertexAttribPointer(i32(loc), 16, gl.FLOAT, false, 0, 0)
}

attribute :: proc {
	attribute_int,
	attribute_ivec2,
	attribute_ivec3,
	attribute_ivec4,
	attribute_uint,
	attribute_uvec2,
	attribute_uvec3,
	attribute_uvec4,
	attribute_bool,
	attribute_bvec2,
	attribute_bvec3,
	attribute_bvec4,
	attribute_float,
	attribute_vec2,
	attribute_vec3,
	attribute_vec4,
	attribute_u8vec4,
	attribute_mat2,
	attribute_mat3,
	attribute_mat4,
}

Uniform_int   :: distinct i32
Uniform_ivec2 :: distinct i32
Uniform_ivec3 :: distinct i32
Uniform_ivec4 :: distinct i32
Uniform_uint  :: distinct i32
Uniform_uvec2 :: distinct i32
Uniform_uvec3 :: distinct i32
Uniform_uvec4 :: distinct i32
Uniform_bool  :: distinct i32
Uniform_bvec2 :: distinct i32
Uniform_bvec3 :: distinct i32
Uniform_bvec4 :: distinct i32
Uniform_float :: distinct i32
Uniform_vec2  :: distinct i32
Uniform_vec3  :: distinct i32
Uniform_vec4  :: distinct i32
Uniform_mat2  :: distinct i32
Uniform_mat3  :: distinct i32
Uniform_mat4  :: distinct i32

@require_results uniform_location_int   :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_int   {return Uniform_int  (#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_ivec2 :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_ivec2 {return Uniform_ivec2(#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_ivec3 :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_ivec3 {return Uniform_ivec3(#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_ivec4 :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_ivec4 {return Uniform_ivec4(#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_uint  :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_uint  {return Uniform_uint (#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_uvec2 :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_uvec2 {return Uniform_uvec2(#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_uvec3 :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_uvec3 {return Uniform_uvec3(#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_uvec4 :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_uvec4 {return Uniform_uvec4(#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_bool  :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_bool  {return Uniform_bool (#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_bvec2 :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_bvec2 {return Uniform_bvec2(#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_bvec3 :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_bvec3 {return Uniform_bvec3(#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_bvec4 :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_bvec4 {return Uniform_bvec4(#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_float :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_float {return Uniform_float(#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_vec2  :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_vec2  {return Uniform_vec2 (#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_vec3  :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_vec3  {return Uniform_vec3 (#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_vec4  :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_vec4  {return Uniform_vec4 (#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_mat2  :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_mat2  {return Uniform_mat2 (#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_mat3  :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_mat3  {return Uniform_mat3 (#force_inline gl.GetUniformLocation(program, name))}
@require_results uniform_location_mat4  :: #force_inline proc "contextless" (program: gl.Program, name: string) -> Uniform_mat4  {return Uniform_mat4 (#force_inline gl.GetUniformLocation(program, name))}

uniform_int   :: #force_inline proc "contextless" (loc: Uniform_int  , v: i32  ) {#force_inline gl.Uniform1iv      (i32(loc), v)}
uniform_ivec2 :: #force_inline proc "contextless" (loc: Uniform_ivec2, v: ivec2) {#force_inline gl.Uniform2iv      (i32(loc), v)}
uniform_ivec3 :: #force_inline proc "contextless" (loc: Uniform_ivec3, v: ivec3) {#force_inline gl.Uniform3iv      (i32(loc), v)}
uniform_ivec4 :: #force_inline proc "contextless" (loc: Uniform_ivec4, v: ivec4) {#force_inline gl.Uniform4iv      (i32(loc), v)}
uniform_uint  :: #force_inline proc "contextless" (loc: Uniform_uint , v: u32  ) {#force_inline gl.Uniform1uiv     (i32(loc), v)}
uniform_uvec2 :: #force_inline proc "contextless" (loc: Uniform_uvec2, v: uvec2) {#force_inline gl.Uniform2uiv     (i32(loc), v)}
uniform_uvec3 :: #force_inline proc "contextless" (loc: Uniform_uvec3, v: uvec3) {#force_inline gl.Uniform3uiv     (i32(loc), v)}
uniform_uvec4 :: #force_inline proc "contextless" (loc: Uniform_uvec4, v: uvec4) {#force_inline gl.Uniform4uiv     (i32(loc), v)}
uniform_bool  :: #force_inline proc "contextless" (loc: Uniform_bool , v: b32  ) {#force_inline gl.Uniform1uiv     (i32(loc), u32(v))}
uniform_bvec2 :: #force_inline proc "contextless" (loc: Uniform_bvec2, v: bvec2) {#force_inline gl.Uniform2uiv     (i32(loc), transmute(uvec2)v)}
uniform_bvec3 :: #force_inline proc "contextless" (loc: Uniform_bvec3, v: bvec3) {#force_inline gl.Uniform3uiv     (i32(loc), transmute(uvec3)v)}
uniform_bvec4 :: #force_inline proc "contextless" (loc: Uniform_bvec4, v: bvec4) {#force_inline gl.Uniform4uiv     (i32(loc), transmute(uvec4)v)}
uniform_float :: #force_inline proc "contextless" (loc: Uniform_float, v: float) {#force_inline gl.Uniform1fv      (i32(loc), v)}
uniform_vec2  :: #force_inline proc "contextless" (loc: Uniform_vec2 , v: vec2 ) {#force_inline gl.Uniform2fv      (i32(loc), v)}
uniform_vec3  :: #force_inline proc "contextless" (loc: Uniform_vec3 , v: vec3 ) {#force_inline gl.Uniform3fv      (i32(loc), v)}
uniform_vec4  :: #force_inline proc "contextless" (loc: Uniform_vec4 , v: vec4 ) {#force_inline gl.Uniform4fv      (i32(loc), v)}
uniform_mat2  :: #force_inline proc "contextless" (loc: Uniform_mat2 , v: mat2 ) {#force_inline gl.UniformMatrix2fv(i32(loc), v)}
uniform_mat3  :: #force_inline proc "contextless" (loc: Uniform_mat3 , v: mat3 ) {#force_inline gl.UniformMatrix3fv(i32(loc), v)}
uniform_mat4  :: #force_inline proc "contextless" (loc: Uniform_mat4 , v: mat4 ) {#force_inline gl.UniformMatrix4fv(i32(loc), v)}

uniform :: proc {
	uniform_int,
	uniform_ivec2,
	uniform_ivec3,
	uniform_ivec4,
	uniform_uint,
	uniform_uvec2,
	uniform_uvec3,
	uniform_uvec4,
	uniform_bool,
	uniform_bvec2,
	uniform_bvec3,
	uniform_bvec4,
	uniform_float,
	uniform_vec2,
	uniform_vec3,
	uniform_vec4,
	uniform_mat2,
	uniform_mat3,
	uniform_mat4,
}
