package example

import "core:intrinsics"
import glm "core:math/linalg/glsl"
import gl "../wasm/webgl"

PI   :: glm.PI
VAO  :: gl.VertexArrayObject
Vec  :: glm.vec3
Vec3 :: glm.vec3
Mat3 :: glm.mat3
Mat4 :: glm.mat4
RGBA :: distinct [4]u8

radians :: glm.radians_f32
cos     :: glm.cos
sin     :: glm.sin
tan     :: glm.tan
dot     :: glm.dot
cross   :: glm.cross

copy_array :: #force_inline proc "contextless" (dst: []$S, src: [$N]S) {
	clone := src
	copy(dst, clone[:])
}

cast_vec2 :: #force_inline proc "contextless" ($D: typeid, v: [2]$S) -> [2]D
	where intrinsics.type_is_numeric(S) && intrinsics.type_is_numeric(D) {
	return {D(v.x), D(v.y)}
}

vec2_to_vec3 :: #force_inline proc "contextless" (v: $T/[2]f32, z: f32 = 0) -> glm.vec3 {
	return {v.x, v.y, z}
}

@(require_results)
mat3_translate :: proc "contextless" (v: [2]f32) -> glm.mat3 {
	return {
		1, 0, v.x,
		0, 1, v.y,
		0, 0, 1,
   	}
}
@(require_results)
mat3_scale :: proc "contextless" (v: [2]f32) -> glm.mat3 {
	return {
		v.x, 0,   0,
		0,   v.y, 0,
		0,   0,   1,
   	}
}
@(require_results)
mat3_rotate :: proc "contextless" (angle: f32) -> glm.mat3 {
	c := glm.cos(angle)
	s := glm.sin(angle)
	return {
		 c, s, 0,
		-s, c, 0,
		 0, 0, 1,
	}
}
@(require_results)
mat3_projection :: proc "contextless" (size: [2]f32) -> glm.mat3 {
	return {
		2/size.x, 0,       -1,
		0,       -2/size.y, 1,
		0,        0,        1,
	}
}

mat4_translate :: glm.mat4Translate
mat4_inverse :: glm.inverse_mat4

@(require_results)
mat4_rotate_x :: proc "contextless" (radians: f32) -> glm.mat4 {
	c := glm.cos(radians)
	s := glm.sin(radians)

	return {
		1, 0, 0, 0,
		0, c, s, 0,
		0,-s, c, 0,
		0, 0, 0, 1,
	}
}
@(require_results)
mat4_rotate_y :: proc "contextless" (radians: f32) -> glm.mat4 {
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
mat4_rotate_z :: proc "contextless" (radians: f32) -> glm.mat4 {
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
mat4_perspective :: proc "contextless" (fov, aspect, near, far: f32) -> glm.mat4 {
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
	// f  := glm.normalize(target - eye)
	// s  := glm.normalize(cross(f, up))
	// u  := cross(s, f)
	// fe := dot(f, eye)
	
	// return {
	// 	+s.x, +s.y, +s.z, -dot(s, eye),
	// 	+u.x, +u.y, +u.z, -dot(u, eye),
	// 	-f.x, -f.y, -f.z, +fe,
	// 	0,    0,    0,    1,
	// }

	z := glm.normalize(eye - target)
	x := glm.normalize(cross(up, z))
	y := glm.normalize(cross(z, x))

	return {
		x.x, y.x, z.x, eye.x,
		x.y, y.y, z.y, eye.y,
		x.z, y.z, z.z, eye.z,
		0,   0,   0,   1,	
	}
}


WHITE : RGBA : {255, 255, 255, 255}
GREEN : RGBA : {60, 210, 0, 255}
YELLOW: RGBA : {210, 210, 0, 255}
BLUE  : RGBA : {0, 80, 190, 255}
RED   : RGBA : {230, 20, 0, 255}
ORANGE: RGBA : {250, 160, 50, 255}
PURPLE: RGBA : {160, 100, 200, 255}

CUBE_TRIANGLES :: 6 * 2
CUBE_VERTICES  :: CUBE_TRIANGLES * 3

CUBE_POSITIONS: [CUBE_VERTICES]Vec : {
	{0, 0, 0}, // 0
	{1, 0, 0},
	{0, 0, 1},

	{0, 0, 1}, // 1
	{1, 0, 0},
	{1, 0, 1},

	{0, 0, 1}, // 2
	{1, 0, 1},
	{0, 1, 1},

	{0, 1, 1}, // 3
	{1, 0, 1},
	{1, 1, 1},

	{0, 0, 0}, // 4
	{0, 0, 1},
	{0, 1, 1},

	{0, 0, 0}, // 5
	{0, 1, 1},
	{0, 1, 0},

	{1, 0, 0}, // 6
	{1, 1, 1},
	{1, 0, 1},

	{1, 0, 0}, // 7
	{1, 1, 0},
	{1, 1, 1},

	{0, 0, 0}, // 8
	{1, 1, 0},
	{1, 0, 0},

	{0, 0, 0}, // 9
	{0, 1, 0},
	{1, 1, 0},

	{0, 1, 0}, // 10
	{0, 1, 1},
	{1, 1, 1},
	
	{0, 1, 0}, // 11
	{1, 1, 1},
	{1, 1, 0},
}

get_cube_positions :: proc(pos: Vec = 0, h: f32 = 1) -> [CUBE_VERTICES]Vec {
	positions := CUBE_POSITIONS
	for &vec in positions {
		vec = pos + (vec - {0.5, 0.5, 0.5}) * h
	}
	return positions
}

WHITE_CUBE_COLORS: [CUBE_VERTICES]RGBA : {
	WHITE, WHITE, WHITE, // 0
	WHITE, WHITE, WHITE, // 1
	WHITE, WHITE, WHITE, // 2
	WHITE, WHITE, WHITE, // 3
	WHITE, WHITE, WHITE, // 4
	WHITE, WHITE, WHITE, // 5
	WHITE, WHITE, WHITE, // 6
	WHITE, WHITE, WHITE, // 7
	WHITE, WHITE, WHITE, // 8
	WHITE, WHITE, WHITE, // 9
	WHITE, WHITE, WHITE, // 10
	WHITE, WHITE, WHITE, // 11
}


PYRAMID_TRIANGLES :: 6
PYRAMID_VERTICES  :: PYRAMID_TRIANGLES * 3

get_pyramid_positions :: proc(pos: Vec = 0, h: f32 = 1) -> [PYRAMID_VERTICES]Vec {
	x := pos.x - h/2
	y := pos.y - h/2
	z := pos.z - h/2

	return {
		{x, y, z},   {x+h, y, z}, {x,   y, z+h},
		{x, y, z+h}, {x+h, y, z}, {x+h, y, z+h},

		{x,   y, z},   {x+h/2, y+h, z+h/2}, {x+h, y, z},
		{x+h, y, z},   {x+h/2, y+h, z+h/2}, {x+h, y, z+h},
		{x+h, y, z+h}, {x+h/2, y+h, z+h/2}, {x,   y, z+h},
		{x,   y, z+h}, {x+h/2, y+h, z+h/2}, {x,   y, z},
	}
}