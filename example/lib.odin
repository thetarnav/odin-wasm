package example

import "core:intrinsics"
import glm "core:math/linalg/glsl"

cast_vec2 :: #force_inline proc "contextless" (
	$D: typeid,
	v: [2]$S,
) -> [2]D where intrinsics.type_is_numeric(S) &&
	intrinsics.type_is_numeric(D) {return {D(v.x), D(v.y)}}

vec2_to_vec3 :: #force_inline proc "contextless" (v: $T/[2]f32, z: f32 = 0) -> glm.vec3 {
	return {v.x, v.y, z}
}

// odinfmt: disable
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

// odinfmt: enable
