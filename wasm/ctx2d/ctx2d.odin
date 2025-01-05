package ctx2d

import glm "core:math/linalg/glsl"

foreign import "ctx2d"


vec2 :: glm.vec2
mat3 :: glm.mat3
rgba :: [4]u8

@private
digits := "0123456789abcdef"

Buf_px   :: [32]byte
Buf_rgba :: [9]byte

px_to_string :: proc (buf: []byte, val: int) -> string #no_bounds_check {
	assert(len(buf) >= 32, "buffer too small")

	if val == 0 {
		copy(buf, "0px")
		return string(buf[:3])
	}

	i := len(buf)
	u := u64(val)
	buf[0] = '+'

	if val < 0 {
		buf[0] = '-'
		u      = u64(-val)
	}
	
	B :: 10
	for u >= B {
		i -= 1
		buf[i] = digits[u % B]
		u /= B
	}
	i -= 1
	buf[i] = digits[u % B]

	copy(buf[1:], buf[i:])

	val_len := len(buf) - i + 1
	buf[val_len+0] = 'p'
	buf[val_len+1] = 'x'

	return string(buf[:val_len+2])
}

rgba_to_string :: proc (buf: []byte, color: rgba) -> string #no_bounds_check {
	assert(len(buf) >= 9, "buffer too small")

	i := len(buf)
	buf[0] = '#'

	for j := 3; j >= 0; j -= 1 {
		i -= 2
		buf[i+0] = digits[color[j] >> 4]  // high nibble
		buf[i+1] = digits[color[j] & 0xF] // low nibble
	}

	return string(buf[:9])
}


// ------------------------------ /
//             CONTEXT            /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	// Sets the current 2d context by canvas id.
	setCurrentContextById :: proc (id: string) -> bool ---
}

// ------------------------------ /
//           COMPOSITING          /
// ------------------------------ /

GlobalCompositeOperation :: enum {
	source_over      =  0,
	source_in        =  1,
	source_out       =  2,
	source_atop      =  3,
	destination_over =  4,
	destination_in   =  5,
	destination_out  =  6,
	destination_atop =  7,
	lighter          =  8,
	copy             =  9,
	xor              = 10,
	multiply         = 11,
	screen           = 12,
	overlay          = 13,
	darken           = 14,
	lighten          = 15,
	color_dodge      = 16,
	color_burn       = 17,
	hard_light       = 18,
	soft_light       = 19,
	difference       = 20,
	exclusion        = 21,
	hue              = 22,
	saturation       = 23,
	color            = 24,
	luminosity       = 25,
}

@(default_calling_convention="contextless")
foreign ctx2d {
	globalCompositeOperation :: proc (operation: GlobalCompositeOperation) ---
	globalAlpha              :: proc (alpha: f32) ---
}

// ------------------------------ /
//            DRAW PATH           /
// ------------------------------ /

FillRule :: enum {
	nonzero = 0,
	evenodd = 1,
}

@(default_calling_convention="contextless")
foreign ctx2d {
	// Begins a new path.
	beginPath       :: proc () ---
	// Clips the current path.
	clip            :: proc (fill_rule: FillRule = .nonzero) ---
	// Fills the current path.
	fill            :: proc (fill_rule: FillRule = .nonzero) ---
	// Checks if the given point is inside the current path.
	isPointInPath   :: proc (x, y: f32, fill_rule: FillRule = .nonzero) -> bool ---
	// Checks if the given point is inside the current stroke.
	isPointInStroke :: proc (x, y: f32) -> bool ---
	// Strokes the current path.
	stroke          :: proc () ---
}

// ------------------------------ /
//      FILL STROKE STYLES        /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	@(link_name="fillStyle")
	fillStyleString   :: proc (color: string) ---
	@(link_name="strokeStyle")
	strokeStyleString :: proc (color: string) ---
}

// Sets the fill style color.
fillStyle :: proc (color: rgba) {
	buf: Buf_rgba
	fillStyleString(rgba_to_string(buf[:], color))
}

// Sets the stroke style color.
strokeStyle :: proc (color: rgba) {
	buf: Buf_rgba
	strokeStyleString(rgba_to_string(buf[:], color))
}

// ------------------------------ /
//            FILTERS             /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	// Sets the filter to apply to the canvas.
	filter :: proc (filter: string) ---
}

// ------------------------------ /
//              PATH              /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	@(link_name="arc")
	arcXY            :: proc (x, y, radius, angle_start, angle_end: f32, counter_clockwise: bool = false) ---
	@(link_name="arcTo")
	arcToXY          :: proc (x1, y1, x2, y2, radius: f32) ---
	@(link_name="bezierCurveTo")
	bezierCurveToXY  :: proc (cp1x, cp1y, cp2x, cp2y, x, y: f32) ---
	closePath        :: proc () ---
	ellipse          :: proc (x, y, radius_x, radius_y, rotation, angle_start, angle_end: f32, counter_clockwise: bool = false) ---
	@(link_name="lineTo")
	lineToXY         :: proc (x, y: f32) ---
	@(link_name="moveTo")
	moveToXY         :: proc (x, y: f32) ---
	quadraticCurveTo :: proc (cpx, cpy, x, y: f32) ---
	rect             :: proc (x, y, w, h: f32) ---
	roundRect        :: proc (x, y, w, h: f32, radii: f32 = 0) ---
}

arcVec :: proc (v: glm.vec2, radius, angle_start, angle_end: f32, counter_clockwise: bool = false) {
	arcXY(v.x, v.y, radius, angle_start, angle_end, counter_clockwise)
}
arc :: proc {arcXY, arcVec}

arcToVec :: proc (v1, v2: glm.vec2, radius: f32) {
	arcToXY(v1.x, v1.y, v2.x, v2.y, radius)
}
arcTo :: proc {arcToXY, arcToVec}

bezierCurveToVec :: proc (cp1, cp2, v: glm.vec2) {
	bezierCurveToXY(cp1.x, cp1.y, cp2.x, cp2.y, v.x, v.y)
}
bezierCurveTo :: proc {bezierCurveToXY, bezierCurveToVec}

lineToVec :: proc (v: glm.vec2) {
	lineToXY(v.x, v.y)
}
lineTo :: proc {lineToXY, lineToVec}

moveToVec :: proc (v: glm.vec2) {
	moveToXY(v.x, v.y)
}
moveTo :: proc {moveToXY, moveToVec}

// ------------------------------ /
//      PATH DRAWING STYLES       /
// ------------------------------ /

LineCap :: enum {
	butt   = 0,
	round  = 1,
	square = 2,
}

LineJoin :: enum {
	miter = 0,
	round = 1,
	bevel = 2,
}

@(default_calling_convention="contextless")
foreign ctx2d {
	lineCap        :: proc (cap: LineCap) ---
	lineDashOffset :: proc (offset: f32) ---
	lineJoin       :: proc (join: LineJoin) ---
	lineWidth      :: proc (width: f32) ---
	miterLimit     :: proc (limit: f32) ---
	setLineDash    :: proc (segments: []f32) ---
}

// ------------------------------ /
//              RECT              /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	@(link_name="clearRect")
	clearRectXY  :: proc (x, y, w, h: f32) ---
	@(link_name="fillRect")
	fillRectXY   :: proc (x, y, w, h: f32) ---
	@(link_name="strokeRect")
	strokeRectXY :: proc (x, y, w, h: f32) ---
}

Rect :: struct {
	using pos: vec2,
	size: vec2,
}

clearRectVec :: proc (v: glm.vec2, size: glm.vec2) {
	clearRectXY(v.x, v.y, size.x, size.y)
}
clearRectRect :: proc (rect: Rect) {
	clearRectVec(rect, rect.size)
}
clearRect :: proc {clearRectXY, clearRectVec, clearRectRect}

fillRectVec :: proc (v: glm.vec2, size: glm.vec2) {
	fillRectXY(v.x, v.y, size.x, size.y)
}
fillRectRect :: proc (rect: Rect) {
	fillRectVec(rect, rect.size)
}
fillRect :: proc {fillRectXY, fillRectVec, fillRectRect}

strokeRectVec :: proc (v: glm.vec2, size: glm.vec2) {
	strokeRectXY(v.x, v.y, size.x, size.y)
}
strokeRectRect :: proc (rect: Rect) {
	strokeRectVec(rect, rect.size)
}
strokeRect :: proc {strokeRectXY, strokeRectVec, strokeRectRect}

// ------------------------------ /
//         SHADOW STYLES          /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	shadowBlur    :: proc (blur: f32) ---
	@(link_name="shadowColor")
	_shadowColor  :: proc (color: string) ---
	shadowOffsetX :: proc (offset: f32) ---
	shadowOffsetY :: proc (offset: f32) ---
}

shadowColor :: proc (color: rgba) {
	buf: Buf_rgba
	_shadowColor(rgba_to_string(buf[:], color))
}

// ------------------------------ /
//              STATE             /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	reset   :: proc () ---
	restore :: proc () ---
	save    :: proc () ---
}

// ------------------------------ /
//              TEXT              /
// ------------------------------ /

// The dimensions of a piece of text in the canvas, as created by the CanvasRenderingContext2D.measureText() method.
TextMetrics :: struct {
	actualBoundingBoxAscent:  f32,
	actualBoundingBoxDescent: f32,
	actualBoundingBoxLeft:    f32,
	actualBoundingBoxRight:   f32,
	alphabeticBaseline:       f32,
	emHeightAscent:           f32,
	emHeightDescent:          f32,
	fontBoundingBoxAscent:    f32,
	fontBoundingBoxDescent:   f32,
	hangingBaseline:          f32,
	ideographicBaseline:      f32,
	width:                    f32,
}

@(default_calling_convention="contextless")
foreign ctx2d {
	@(link_name="fillTextNoMax")
	fillTextNoMaxXY      :: proc (text: string, x, y: f32) ---
	@(link_name="fillTextMaxWidth")
	fillTextMaxWidthXY   :: proc (text: string, x, y: f32, max_width: f32) ---
	@(link_name="strokeTextNoMax")
	strokeTextNoMaxXY    :: proc (text: string, x, y: f32) ---
	@(link_name="strokeTextMaxWidth")
	strokeTextMaxWidthXY :: proc (text: string, x, y: f32, max_width: f32) ---
	measureText          :: proc (text: string, metrics: ^TextMetrics) ---
}

fillTextNoMax :: proc (text: string, v: glm.vec2) {
	fillTextNoMaxXY(text, v.x, v.y)
}
fillTextMaxWidth :: proc (text: string, v: glm.vec2, max_width: f32) {
	fillTextMaxWidthXY(text, v.x, v.y, max_width)
}
fillText :: proc {fillTextNoMax, fillTextMaxWidth, fillTextNoMaxXY, fillTextMaxWidthXY}

strokeTextNoMax :: proc (text: string, v: glm.vec2) {
	strokeTextNoMaxXY(text, v.x, v.y)
}
strokeTextMaxWidth :: proc (text: string, v: glm.vec2, max_width: f32) {
	strokeTextMaxWidthXY(text, v.x, v.y, max_width)
}
strokeText :: proc {strokeTextNoMax, strokeTextMaxWidth, strokeTextNoMaxXY, strokeTextMaxWidthXY}

getTextMetrics :: proc (text: string) -> (metrics: TextMetrics) {
	measureText(text, &metrics)
	return
}

// ------------------------------ /
//      TEXT DRAWING STYLES       /
// ------------------------------ /

Direction :: enum {
	inherit = 0,
	ltr     = 1,
	rtl     = 2,
}

FontKerning :: enum {
	auto   = 0,
	none   = 1,
	normal = 2,
}

FontStretch :: enum {
	normal          = 0,
	ultra_condensed = 1,
	extra_condensed = 2,
	condensed       = 3,
	semi_condensed  = 4,
	semi_expanded   = 5,
	expanded        = 6,
	extra_expanded  = 7,
	ultra_expanded  = 8,
}

FontVariantCaps :: enum {
	normal          = 0,
	petite_caps     = 1,
	all_petite_caps = 2,
	small_caps      = 3,
	all_small_caps  = 4,
	titling_caps    = 5,
	unicase         = 6,
}

TextAlign :: enum {
	start  = 0,
	end    = 1,
	left   = 2,
	right  = 3,
	center = 4,
}

TextBaseline :: enum {
	alphabetic  = 0,
	top         = 1,
	hanging     = 2,
	middle      = 3,
	ideographic = 4,
	bottom      = 5,
}

TextRendering :: enum {
	auto               = 0,
	optimizeSpeed      = 1,
	optimizeLegibility = 2,
	geometricPrecision = 3,
}

@(default_calling_convention="contextless")
foreign ctx2d {
	direction           :: proc (Direction)       ---
	font                :: proc (string)          ---
	fontKerning         :: proc (FontKerning)     ---
	fontStretch         :: proc (FontStretch)     ---
	fontVariantCaps     :: proc (FontVariantCaps) ---
	@(link_name="letterSpacing")
	letterSpacingString :: proc (string)          ---
	textAlign           :: proc (TextAlign)       ---
	textBaseline        :: proc (TextBaseline)    ---
	textRendering       :: proc (TextRendering)   ---
	@(link_name="wordSpacing")
	wordSpacingString   :: proc (string)          ---
}

letterSpacingPx :: proc (px: int) {
	buf: Buf_px
	letterSpacingString(px_to_string(buf[:], px))
}

wordSpacingPx :: proc (px: int) {
	buf: Buf_px
	wordSpacingString(px_to_string(buf[:], px))
}

letterSpacing :: proc {letterSpacingString, letterSpacingPx}
wordSpacing   :: proc {wordSpacingString, wordSpacingPx}

// ------------------------------ /
//           TRANSFORM            /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	@(link_name="setTransform")
	_setTransform  :: proc (a, b, c, d, e, f: f32) ---
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
	c := glm.cos(angle)
	s := glm.sin(angle)
	return {
		 c, s, 0,
		-s, c, 0,
		 0, 0, 1,
	}
}

mat: mat3

getTransform :: proc () -> mat3 {
	return mat
}

setTransform :: proc (m: mat3) {
	mat = m
	_setTransform(m[0][0], m[0][1], m[1][0], m[1][1], m[2][0], m[2][1])
}

resetTransform :: proc () {
	setTransform(1)
}

scale :: proc (v: vec2) {
	setTransform(mat * mat3_scale(v))
}

translate :: proc (v: vec2) {
	setTransform(mat * mat3_translate(v))
}

rotate :: proc (angle: f32) {
	setTransform(mat * mat3_rotate(angle))
}

transform :: proc (m: mat3) {
	setTransform(mat * m)
}
