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
mat4_inverse :: glm.inverse_mat4

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

// Rotates a vector around an axis
@(require_results)
vec3_rotate_by_axis_angle :: proc "contextless" (v, axis: Vec, angle: f32) -> Vec {
	axis, angle := axis, angle

	axis = normalize(axis)

	angle *= 0.5
	a := sin(angle)
	b := axis.x*a
	c := axis.y*a
	d := axis.z*a
	a = cos(angle)
	w := Vec{b, c, d}

	wv := cross(w, v)
	wwv := cross(w, wv)

	a *= 2
	wv *= a

	wwv *= 2

	return v + wv + wwv
}


WHITE : RGBA : {255, 255, 255, 255}
GREEN : RGBA : {60, 210, 0, 255}
YELLOW: RGBA : {210, 200, 0, 255}
BLUE  : RGBA : {0, 80, 190, 255}
CYAN  : RGBA : {0, 210, 210, 255}
RED   : RGBA : {230, 20, 0, 255}
ORANGE: RGBA : {250, 150, 50, 255}
PURPLE: RGBA : {160, 100, 200, 255}
PURPLE_DARK: RGBA : {80, 30, 30, 255}
BLACK : RGBA : {0, 0, 0, 255}

rgba_to_vec4 :: proc "contextless" (rgba: RGBA) -> glm.vec4 {
	return {f32(rgba.r)/255, f32(rgba.g)/255, f32(rgba.b)/255, f32(rgba.a)/255}
}

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

CUBE_NORMALS: [CUBE_VERTICES]Vec : {
	{0, -1, 0}, // 0
	{0, -1, 0},
	{0, -1, 0},
	{0, -1, 0}, // 1
	{0, -1, 0},
	{0, -1, 0},
	
	{0, 0, 1}, // 2
	{0, 0, 1},
	{0, 0, 1},
	{0, 0, 1}, // 3
	{0, 0, 1},
	{0, 0, 1},
	
	{-1, 0, 0}, // 4
	{-1, 0, 0},
	{-1, 0, 0},
	{-1, 0, 0}, // 5
	{-1, 0, 0},
	{-1, 0, 0},
	
	{1, 0, 0}, // 6
	{1, 0, 0},
	{1, 0, 0},
	{1, 0, 0}, // 7
	{1, 0, 0},
	{1, 0, 0},
	
	{0, 0, -1}, // 8
	{0, 0, -1},
	{0, 0, -1},
	{0, 0, -1}, // 9
	{0, 0, -1},
	{0, 0, -1},
	
	{0, 1, 0}, // 10
	{0, 1, 0},
	{0, 1, 0},
	{0, 1, 0}, // 11
	{0, 1, 0},
	{0, 1, 0},
}

get_cube_positions :: proc(pos: Vec = 0, h: f32 = 1) -> [CUBE_VERTICES]Vec {
	positions := CUBE_POSITIONS
	for &vec in positions {
		vec = pos + (vec - {0.5, 0.5, 0.5}) * h
	}
	return positions
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

get_sphere_base_triangle :: proc(positions, normals: []Vec, radius: f32, segments: int) {
	// TODO: merge top and bottom segment triangles
	si := 0 // segment index
	for vi in 0..<segments { // vertical
		va0   := PI * (f32(vi)  ) / f32(segments)
		va1   := PI * (f32(vi)+1) / f32(segments)
		hmove := 0.5 * f32(vi%2)

		for hi in 0..<segments { // horizontal
			ha0 := 2*PI * (f32(hi)-0.5 + hmove) / f32(segments)
			ha1 := 2*PI * (f32(hi)     + hmove) / f32(segments)
			ha2 := 2*PI * (f32(hi)+0.5 + hmove) / f32(segments)
			ha3 := 2*PI * (f32(hi)+1   + hmove) / f32(segments)

			// Vertices
			v0 := Vec{cos(ha0)*sin(va1), cos(va1), sin(ha0)*sin(va1)}
			v1 := Vec{cos(ha1)*sin(va0), cos(va0), sin(ha1)*sin(va0)}
			v2 := Vec{cos(ha2)*sin(va1), cos(va1), sin(ha2)*sin(va1)}
			v3 := Vec{cos(ha3)*sin(va0), cos(va0), sin(ha3)*sin(va0)}

			// Normals
			n0 := normalize(v0)
			n1 := normalize(v1)
			n2 := normalize(v2)
			n3 := normalize(v3)

			// Triangle 1
			positions[si+0] = v0 * radius
			positions[si+1] = v1 * radius
			positions[si+2] = v2 * radius

			normals  [si+0] = n0
			normals  [si+1] = n1
			normals  [si+2] = n2

			// Triangle 2
			positions[si+3] = v1 * radius
			positions[si+4] = v3 * radius
			positions[si+5] = v2 * radius

			normals  [si+3] = n1
			normals  [si+4] = n3
			normals  [si+5] = n2

			si += 6
		}
	}
}

get_sphere_base_rectangle :: proc(positions, normals: []Vec, radius: f32, segments: int) {
	// TODO: merge top and bottom segment triangles
	si := 0 // segment index
	for vi in 0..<segments { // vertical
		for hi in 0..<segments { // horizontal
			va0 :=   PI * f32(vi+0) / f32(segments)
			va1 :=   PI * f32(vi+1) / f32(segments)
			ha0 := 2*PI * f32(hi+0) / f32(segments)
			ha1 := 2*PI * f32(hi+1) / f32(segments)
			
			// Vertices
			v0 := Vec{cos(ha0)*sin(va1), cos(va1), sin(ha0)*sin(va1)}
			v1 := Vec{cos(ha0)*sin(va0), cos(va0), sin(ha0)*sin(va0)}
			v2 := Vec{cos(ha1)*sin(va1), cos(va1), sin(ha1)*sin(va1)}
			v3 := Vec{cos(ha1)*sin(va0), cos(va0), sin(ha1)*sin(va0)}

			// Normals
			n0 := normalize(v0)
			n1 := normalize(v1)
			n2 := normalize(v2)
			n3 := normalize(v3)

			// Triangle 1
			positions[si+0] = v0 * radius
			positions[si+1] = v1 * radius
			positions[si+2] = v2 * radius

			normals  [si+0] = n0
			normals  [si+1] = n1
			normals  [si+2] = n2

			// Triangle 2
			positions[si+3] = v1 * radius
			positions[si+4] = v3 * radius
			positions[si+5] = v2 * radius

			normals  [si+3] = n1
			normals  [si+4] = n3
			normals  [si+5] = n2

			si += 6
		}
	}
}

JOINT_TRIANGLES :: 8
JOINT_VERTICES  :: 3 * JOINT_TRIANGLES

get_joint :: proc(from, to: Vec) -> [JOINT_VERTICES]Vec {
	
	mid: Vec = from*(1.0/3.0) + to*(2.0/3.0)
	
	from, to := from, to
	if from.y < to.y {
		from, to = to, from
	}

	length: f32 = glm.length(to - from)
	w     : f32 = min(20, length/3)
	
	normal: Vec = normalize(to - from)
	move_x: Vec = vec3_rotate_by_axis_angle(normal, Vec{1, 0, 0}, PI/2) * w
	move_y: Vec = vec3_rotate_by_axis_angle(normal, Vec{0, 0, 1}, PI/2) * w
	
	// TODO this is not correct
	return {
		from,
		mid + move_y,
		mid + move_x,
	
		from,
		mid - move_x,
		mid + move_y,
	
		from,
		mid + move_x,
		mid - move_y,
	
		from,
		mid - move_y,
		mid - move_x,

		mid + move_x,
		mid + move_y,
		to,

		mid + move_y,
		mid - move_x,
		to,

		mid - move_x,
		mid - move_y,
		to,

		mid - move_y,
		mid + move_x,
		to,
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