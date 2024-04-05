package example

import "core:intrinsics"
import glm "core:math/linalg/glsl"
import gl "../wasm/webgl"

VAO  :: gl.VertexArrayObject
Vec  :: glm.vec3
Mat3 :: glm.mat3
Mat4 :: glm.mat4
RGBA :: distinct [4]u8

radians :: glm.radians_f32

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
	c := glm.cos(radians)
	s := glm.sin(radians)

	return {
		c, 0,-s, 0,
		0, 1, 0, 0,
		s, 0, c, 0,
		0, 0, 0, 1,
	}
}
@(require_results)
mat4_rotate_z :: proc "contextless" (radians: f32) -> glm.mat4 {
	c := glm.cos(radians)
	s := glm.sin(radians)

	return {
		c,  s, 0, 0,
		-s, c, 0, 0,
		0,  0, 1, 0,
		0,  0, 0, 1,
	}
}
@(require_results)
mat4_perspective :: proc "contextless" (fov, aspect, near, far: f32) -> glm.mat4 {
    f    : f32 = glm.tan(fov*0.5)
    range: f32 = 1.0 / (near - far)

    return {
		f/aspect, 0, 0,                    0,
		0,        f, 0,                    0,
		0,        0, (near + far) * range, near * far * range * 2,
		0,        0, -1,                   0,
	}
}



CUBE_TRIANGLES :: 6 * 2
CUBE_VERTICES  :: CUBE_TRIANGLES * 3

cube_colors: [CUBE_VERTICES]RGBA = {
	{60, 210, 0, 255}, // 0
	{60, 210, 0, 255}, // Green
	{60, 210, 0, 255}, // 
	{60, 210, 0, 255}, // 1
	{60, 210, 0, 255}, // Green
	{60, 210, 0, 255}, // 

	{210, 210, 0, 255}, // 2
	{210, 210, 0, 255}, // Yellow
	{210, 210, 0, 255}, //
	{210, 210, 0, 255}, // 3
	{210, 210, 0, 255}, // Yellow
	{210, 210, 0, 255}, //

	{0, 80, 190, 255}, // 4
	{0, 80, 190, 255}, // Blue
	{0, 80, 190, 255}, //
	{0, 80, 190, 255}, // 5
	{0, 80, 190, 255}, // Blue
	{0, 80, 190, 255}, //

	{230, 20, 0, 255}, // 6 
	{230, 20, 0, 255}, // Red
	{230, 20, 0, 255}, //
	{230, 20, 0, 255}, // 7
	{230, 20, 0, 255}, // Red
	{230, 20, 0, 255}, //

	{250, 160, 50, 255}, // 8
	{250, 160, 50, 255}, // Orange
	{250, 160, 50, 255}, //
	{250, 160, 50, 255}, // 9
	{250, 160, 50, 255}, // Orange
	{250, 160, 50, 255}, //

	{160, 100, 200, 255}, // 10
	{160, 100, 200, 255}, // Purple
	{160, 100, 200, 255}, //
	{160, 100, 200, 255}, // 11
	{160, 100, 200, 255}, // Purple
	{160, 100, 200, 255}, //
}

cube_positions: [CUBE_VERTICES]Vec = {
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

write_cube_positions :: proc(dst: []Vec, x, y, z, h: f32) {
	assert(len(dst) == CUBE_VERTICES)
	copy(dst, cube_positions[:])
	for &vec in dst {
		vec = {x, y, z} + (vec - {0.5, 0.5, 0.5}) * h
	}
}