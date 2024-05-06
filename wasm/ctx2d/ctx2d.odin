package ctx2d

foreign import "ctx2d"

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

CanvasFillRule :: enum {
	nonzero = 0,
	evenodd = 1,
}

@(default_calling_convention="contextless")
foreign ctx2d {
	// Sets the current 2d context by canvas id.
	setCurrentContextById :: proc (id: string) -> bool ---

	// ------------------------------ /
	//           COMPOSITING          /
	// ------------------------------ /
	
	getGlobalCompositeOperation :: proc () -> GlobalCompositeOperation ---
	setGlobalCompositeOperation :: proc (operation: GlobalCompositeOperation) ---
	getGlobalAlpha :: proc () -> f32 ---
	setGlobalAlpha :: proc (alpha: f32) ---

	// ------------------------------ /
	//            DRAW PATH           /
	// ------------------------------ /

	// Begins a new path.
	beginPath       :: proc () ---
	// Clips the current path.
	clip            :: proc (fill_rule: CanvasFillRule = .nonzero) ---
	// Fills the current path.
	fill            :: proc (fill_rule: CanvasFillRule = .nonzero) ---
	// Checks if the given point is inside the current path.
	isPointInPath   :: proc (x: f32, y: f32, fill_rule: CanvasFillRule = .nonzero) -> bool ---
	// Checks if the given point is inside the current stroke.
	isPointInStroke :: proc (x: f32, y: f32) -> bool ---
	// Strokes the current path.
	stroke          :: proc () ---
}
