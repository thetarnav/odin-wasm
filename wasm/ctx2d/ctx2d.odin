package ctx2d

foreign import "ctx2d"

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

CanvasFillRule :: enum {
	nonzero = 0,
	evenodd = 1,
}

@(default_calling_convention="contextless")
foreign ctx2d {
	// Begins a new path.
	beginPath       :: proc () ---
	// Clips the current path.
	clip            :: proc (fill_rule: CanvasFillRule = .nonzero) ---
	// Fills the current path.
	fill            :: proc (fill_rule: CanvasFillRule = .nonzero) ---
	// Checks if the given point is inside the current path.
	isPointInPath   :: proc (x, y: f32, fill_rule: CanvasFillRule = .nonzero) -> bool ---
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
	// Sets the fill style color.
	fillStyle            :: proc (color: string) ---
	// Sets the stroke style color.
	strokeStyle          :: proc (color: string) ---
}

// ------------------------------ /
//              PATH              /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	arc              :: proc (x, y, radius, angle_start, angle_end: f32, counter_clockwise: bool = false) ---
	arcTo            :: proc (x1, y1, x2, y2, radius: f32) ---
	bezierCurveTo    :: proc (cp1x, cp1y, cp2x, cp2y, x, y: f32) ---
	closePath        :: proc () ---
	ellipse          :: proc (x, y, radius_x, radius_y, rotation, angle_start, angle_end: f32, counter_clockwise: bool = false) ---
	lineTo           :: proc (x, y: f32) ---
	moveTo           :: proc (x, y: f32) ---
	quadraticCurveTo :: proc (cpx, cpy, x, y: f32) ---
	rect             :: proc (x, y, w, h: f32) ---
	roundRect        :: proc (x, y, w, h: f32, radii: f32 = 0) ---
}

// ------------------------------ /
//      PATH DRAWING STYLES       /
// ------------------------------ /

CanvasLineCap :: enum {
	butt   = 0,
	round  = 1,
	square = 2,
}

CanvasLineJoin :: enum {
	miter = 0,
	round = 1,
	bevel = 2,
}

@(default_calling_convention="contextless")
foreign ctx2d {
	lineCap        :: proc (cap: CanvasLineCap) ---
	lineDashOffset :: proc (offset: f32) ---
	lineJoin       :: proc (join: CanvasLineJoin) ---
	lineWidth      :: proc (width: f32) ---
	miterLimit     :: proc (limit: f32) ---
	setLineDash    :: proc (segments: []f32) ---
}

// ------------------------------ /
//              RECT              /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	clearRect  :: proc (x, y, w, h: f32) ---
	fillRect   :: proc (x, y, w, h: f32) ---
	strokeRect :: proc (x, y, w, h: f32) ---
}

// ------------------------------ /
//         SHADOW STYLES          /
// ------------------------------ /

@(default_calling_convention="contextless")
foreign ctx2d {
	shadowBlur    :: proc (blur: f32) ---
	shadowColor   :: proc (color: string) ---
	shadowOffsetX :: proc (offset: f32) ---
	shadowOffsetY :: proc (offset: f32) ---
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
	fillTextNoMax      :: proc (text: string, x, y: f32) ---
	fillTextMaxWidth   :: proc (text: string, x, y: f32, max_width: f32) ---
	strokeTextNoMax    :: proc (text: string, x, y: f32) ---
	strokeTextMaxWidth :: proc (text: string, x, y: f32, max_width: f32) ---
	measureText        :: proc (text: string, metrics: ^TextMetrics) ---
}

fillText   :: proc {fillTextNoMax, fillTextMaxWidth}
strokeText :: proc {strokeTextNoMax, strokeTextMaxWidth}

getTextMetrics :: proc (text: string) -> (metrics: TextMetrics) {
	measureText(text, &metrics)
	return
}

