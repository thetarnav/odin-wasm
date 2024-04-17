package example

import "base:intrinsics"
import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"

PI   :: glm.PI
VAO  :: gl.VertexArrayObject
Vec  :: glm.vec3
Vec3 :: glm.vec3
Mat3 :: glm.mat3
Mat4 :: glm.mat4
RGBA :: distinct [4]u8

radians   :: glm.radians_f32
cos       :: glm.cos
sin       :: glm.sin
tan       :: glm.tan
dot       :: glm.dot
cross     :: glm.cross
normalize :: glm.normalize


rgba_to_vec4 :: proc "contextless" (rgba: RGBA) -> glm.vec4 {
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

vec2_to_vec3 :: #force_inline proc "contextless" (v: $T/[2]f32, z: f32 = 0) -> Vec {
	return {v.x, v.y, z}
}

@(require_results)
mat3_translate :: proc "contextless" (v: [2]f32) -> Mat3 {
	return {
		1, 0, v.x,
		0, 1, v.y,
		0, 0, 1,
   	}
}
@(require_results)
mat3_scale :: proc "contextless" (v: [2]f32) -> Mat3 {
	return {
		v.x, 0,   0,
		0,   v.y, 0,
		0,   0,   1,
   	}
}
@(require_results)
mat3_rotate :: proc "contextless" (angle: f32) -> Mat3 {
	c := cos(angle)
	s := sin(angle)
	return {
		 c, s, 0,
		-s, c, 0,
		 0, 0, 1,
	}
}
@(require_results)
mat3_projection :: proc "contextless" (size: [2]f32) -> Mat3 {
	return {
		2/size.x, 0,       -1,
		0,       -2/size.y, 1,
		0,        0,        1,
	}
}

mat4_translate :: glm.mat4Translate
mat4_inverse   :: glm.inverse_mat4

@(require_results)
mat4_rotate_x :: proc "contextless" (radians: f32) -> Mat4 {
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
mat4_rotate_y :: proc "contextless" (radians: f32) -> Mat4 {
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
mat4_rotate_z :: proc "contextless" (radians: f32) -> Mat4 {
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
mat4_perspective :: proc "contextless" (fov, aspect, near, far: f32) -> Mat4 {
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
mat4_look_at :: proc "contextless" (eye, target, up: Vec3) -> Mat4 {
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

vec3_transform :: proc "contextless" (v: Vec, m: Mat4) -> Vec {
    w := m[0][3] * v.x + m[1][3] * v.y + m[2][3] * v.z + m[3][3] // assume v[3] is 1

    return {
        (m[0][0] * v.x + m[1][0] * v.y + m[2][0] * v.z + m[3][0]) / w,
        (m[0][1] * v.x + m[1][1] * v.y + m[2][1] * v.z + m[3][1]) / w,
        (m[0][2] * v.x + m[1][2] * v.y + m[2][2] * v.z + m[3][2]) / w,
	}
}

normals_from_positions :: proc(dst, src: []Vec) {
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