package example

import "base:intrinsics"
import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

PI     :: glm.PI
VAO    :: gl.VertexArrayObject
vec2   :: glm.vec2
vec3   :: glm.vec3
vec4   :: glm.vec4
mat2   :: glm.mat2
mat3   :: glm.mat3
mat4   :: glm.mat4
u8vec4 :: distinct [4]u8
RGBA   :: u8vec4

radians   :: glm.radians_f32
cos       :: glm.cos
sin       :: glm.sin
tan       :: glm.tan
dot       :: glm.dot
cross     :: glm.cross
normalize :: glm.normalize

UP    :: vec3{ 0, 1, 0}
DOWN  :: vec3{ 0,-1, 0}
LEFT  :: vec3{-1, 0, 0}
RIGHT :: vec3{ 1, 0, 0}
FRONT :: vec3{ 0, 0, 1}
BACK  :: vec3{ 0, 0,-1}


Attribute_Float :: distinct i32
Attribute_Vec2  :: distinct i32
Attribute_Vec3  :: distinct i32
Attribute_Vec4  :: distinct i32
Attribute_Mat2  :: distinct i32
Attribute_Mat3  :: distinct i32
Attribute_Mat4  :: distinct i32

Uniform_f32     :: distinct i32
Uniform_vec2    :: distinct i32
Uniform_vec3    :: distinct i32
Uniform_vec4    :: distinct i32
Uniform_mat2    :: distinct i32
Uniform_mat3    :: distinct i32
Uniform_mat4    :: distinct i32

get_uniform_f32  :: #force_inline proc(program: gl.Program, name: string) -> Uniform_f32  {return Uniform_f32 (#force_inline gl.GetUniformLocation(program, name))}
get_uniform_vec2 :: #force_inline proc(program: gl.Program, name: string) -> Uniform_vec2 {return Uniform_vec2(#force_inline gl.GetUniformLocation(program, name))}
get_uniform_vec3 :: #force_inline proc(program: gl.Program, name: string) -> Uniform_vec3 {return Uniform_vec3(#force_inline gl.GetUniformLocation(program, name))}
get_uniform_vec4 :: #force_inline proc(program: gl.Program, name: string) -> Uniform_vec4 {return Uniform_vec4(#force_inline gl.GetUniformLocation(program, name))}
get_uniform_mat2 :: #force_inline proc(program: gl.Program, name: string) -> Uniform_mat2 {return Uniform_mat2(#force_inline gl.GetUniformLocation(program, name))}
get_uniform_mat3 :: #force_inline proc(program: gl.Program, name: string) -> Uniform_mat3 {return Uniform_mat3(#force_inline gl.GetUniformLocation(program, name))}
get_uniform_mat4 :: #force_inline proc(program: gl.Program, name: string) -> Uniform_mat4 {return Uniform_mat4(#force_inline gl.GetUniformLocation(program, name))}

uniform_vec1 :: #force_inline proc(loc: Uniform_f32,  v: f32 ) {#force_inline gl.Uniform1fv(i32(loc), v)}
uniform_vec2 :: #force_inline proc(loc: Uniform_vec2, v: vec2) {#force_inline gl.Uniform2fv(i32(loc), v)}
uniform_vec3 :: #force_inline proc(loc: Uniform_vec3, v: vec3) {#force_inline gl.Uniform3fv(i32(loc), v)}
uniform_vec4 :: #force_inline proc(loc: Uniform_vec4, v: vec4) {#force_inline gl.Uniform4fv(i32(loc), v)}
uniform_f32  :: uniform_vec1
uniform_vec  :: proc{uniform_f32, uniform_vec2, uniform_vec3, uniform_vec4}

uniform_ivec1 :: #force_inline proc(loc: Uniform_f32,  v: i32      ) {#force_inline gl.Uniform1iv(i32(loc), v)}
uniform_ivec2 :: #force_inline proc(loc: Uniform_vec2, v: glm.ivec2) {#force_inline gl.Uniform2iv(i32(loc), v)}
uniform_ivec3 :: #force_inline proc(loc: Uniform_vec3, v: glm.ivec3) {#force_inline gl.Uniform3iv(i32(loc), v)}
uniform_ivec4 :: #force_inline proc(loc: Uniform_vec4, v: glm.ivec4) {#force_inline gl.Uniform4iv(i32(loc), v)}
uniform_i32   :: uniform_ivec1
uniform_ivec  :: proc{uniform_ivec1, uniform_ivec2, uniform_ivec3, uniform_ivec4}

uniform_mat2 :: #force_inline proc(loc: Uniform_mat2, v: mat2) {#force_inline gl.UniformMatrix2fv(i32(loc), v)}
uniform_mat3 :: #force_inline proc(loc: Uniform_mat3, v: mat3) {#force_inline gl.UniformMatrix3fv(i32(loc), v)}
uniform_mat4 :: #force_inline proc(loc: Uniform_mat4, v: mat4) {#force_inline gl.UniformMatrix4fv(i32(loc), v)}
uniform_mat  :: proc{uniform_mat2, uniform_mat3, uniform_mat4}

rgba_to_vec4 :: proc "contextless" (rgba: u8vec4) -> vec4 {
	return {f32(rgba.r)/255, f32(rgba.g)/255, f32(rgba.b)/255, f32(rgba.a)/255}
}

copy_array :: #force_inline proc "contextless" (dst: []$S, src: [$N]S) {
	src := src
	copy(dst, src[:])
}

copy_pattern :: #force_inline proc "contextless" (dst: []$S, src: []S) #no_bounds_check {
	for i in 0..<len(dst)/len(src) {
		copy(dst[i*len(src):][:len(src)], src)
	}
}

cast_vec2 :: #force_inline proc "contextless" ($D: typeid, v: [2]$S) -> [2]D
	where intrinsics.type_is_numeric(S) && intrinsics.type_is_numeric(D) {
	return {D(v.x), D(v.y)}
}

vec2_to_vec3 :: #force_inline proc "contextless" (v: $T/[2]f32, z: f32 = 0) -> vec3 {
	return {v.x, v.y, z}
}

@(require_results)
mat3_translate :: proc "contextless" (v: [2]f32) -> mat3 {
	return {
		1, 0, v.x,
		0, 1, v.y,
		0, 0, 1,
   	}
}
@(require_results)
mat3_scale :: proc "contextless" (v: [2]f32) -> mat3 {
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
mat3_projection :: proc "contextless" (size: [2]f32) -> mat3 {
	return {
		2/size.x, 0,       -1,
		0,       -2/size.y, 1,
		0,        0,        1,
	}
}

mat4_translate :: glm.mat4Translate
mat4_inverse   :: glm.inverse_mat4

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
    w := m[0][3] * v.x + m[1][3] * v.y + m[2][3] * v.z + m[3][3] // assume v[3] is 1

    return {
        (m[0][0] * v.x + m[1][0] * v.y + m[2][0] * v.z + m[3][0]) / w,
        (m[0][1] * v.x + m[1][1] * v.y + m[2][1] * v.z + m[3][1]) / w,
        (m[0][2] * v.x + m[1][2] * v.y + m[2][2] * v.z + m[3][2]) / w,
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
