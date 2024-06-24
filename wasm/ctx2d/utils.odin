package ctx2d

import glm "core:math/linalg/glsl"


path_rect_rounded :: proc (rect: Rect, r: f32)
{
	using rect
	beginPath()
	moveTo(x+r, y)
	arcTo(x+w, y  , x+w, y+h, r)
	arcTo(x+w, y+h, x  , y+h, r)
	arcTo(x  , y+h, x  , y  , r)
	arcTo(x  , y  , x+w, y  , r)
}

path_rect_squircle :: proc (rect: Rect, r: f32)
{
	using rect
	beginPath()
	moveTo(x+r  , y)
	lineTo(x+w-r, y)
	quadraticCurveTo(x+w, y  , x+w  , y+r)
	lineTo(x+w  , y+h-r)
	quadraticCurveTo(x+w, y+h, x+w-r, y+h)
	lineTo(x+r  , y+h)
	quadraticCurveTo(x  , y+h, x    , y+h-r)
	lineTo(x    , y+r)
	quadraticCurveTo(x  , y  , x+r  , y)
	closePath()
}

path_squircle :: proc (pos: vec2, r: f32)
{
	x, y := pos.x, pos.y
	beginPath()
	moveTo(x+r, y)
	quadraticCurveTo(x+r, y-r, x  , y-r)
	quadraticCurveTo(x-r, y-r, x-r, y)
	quadraticCurveTo(x-r, y+r, x  , y+r)
	quadraticCurveTo(x+r, y+r, x+r, y)
	closePath()
}

path_circle :: proc (pos: vec2, r: f32)
{
	x, y := pos.x, pos.y
	beginPath()
	arc(x, y, r, 0, glm.TAU)
	closePath()
}
