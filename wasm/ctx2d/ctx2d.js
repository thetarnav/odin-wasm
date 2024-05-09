import * as mem from "../memory.js"


/** @typedef {import("../types.js").WasmState} Wasm_State */


export function Ctx2d_State() {
	this.ctx = /** @type {CanvasRenderingContext2D} */ (/** @type {*} */(null))
}

/** @type {Record<number, CanvasFillRule>} */
const FILL_RULE = {
	0: "nonzero",
	1: "evenodd",
}

/** @type {Record<number, CanvasLineCap>} */
const LINE_CAP = {
	0: "butt",
	1: "round",
	2: "square",
}

/** @type {Record<number, CanvasLineJoin>} */
const LINE_JOIN = {
	0: "miter",
	1: "round",
	2: "bevel",
}

/** @type {Record<number, CanvasDirection>} */
const DIRECTION = {
	0: "inherit",
	1: "ltr",
	2: "rtl",
}

/** @type {Record<number, CanvasFontKerning>} */
const FONT_KERNING = {
	0: "auto",
	1: "none",
	2: "normal",
}

/** @type {Record<number, CanvasFontStretch>} */
const FONT_STRETCH = {
	0: "normal",
	1: "ultra-condensed",
	2: "extra-condensed",
	3: "condensed",
	4: "semi-condensed",
	5: "semi-expanded",
	6: "expanded",
	7: "extra-expanded",
	8: "ultra-expanded",
}

/** @type {Record<number, CanvasFontVariantCaps>} */
const FONT_VARIANT_CAPS = {
	0: "normal",
	1: "petite-caps",
	2: "all-petite-caps",
	3: "small-caps",
	4: "all-small-caps",
	5: "titling-caps",
	6: "unicase",
}

/** @type {Record<number, CanvasTextAlign>} */
const TEXT_ALIGN = {
	0: "start",
	1: "end",
	2: "left",
	3: "right",
	4: "center",
}

/** @type {Record<number, CanvasTextBaseline>} */
const TEXT_BASELINE = {
	0: "alphabetic",
	1: "top",
	2: "hanging",
	3: "middle",
	4: "ideographic",
	5: "bottom",
}

/** @type {Record<number, CanvasTextRendering>} */
const TEXT_RENDERING = {
	0: "auto",
	1: "optimizeSpeed",
	2: "optimizeLegibility",
	3: "geometricPrecision",
}

/**
 * @param   {Wasm_State}  wasm
 * @param   {Ctx2d_State} s
 * @returns Canvas 2d context bindings for Odin.
 */
export function make_odin_ctx2d(wasm, s) {
	return {
		/**
		 * Sets the current 2d context by canvas id.
		 * @param   {number}  id_ptr
		 * @param   {number}  id_len
		 * @returns {boolean} */
		setCurrentContextById: (id_ptr, id_len) => {
			const id      = mem.load_string_raw(wasm.memory.buffer, id_ptr, id_len)
			const element = document.getElementById(id)

			if (!(element instanceof HTMLCanvasElement)) return false
			
			const ctx = element.getContext("2d")
			if (!ctx) return false

			s.ctx = ctx
			return true
		},
		// ------------------------------ /
		//           COMPOSITING          /
		// ------------------------------ /
		/**
		 * @param   {number} alpha
		 * @returns {void}   */
		globalAlpha(alpha) {
			s.ctx.globalAlpha = alpha
		},
		/**
		 * @param   {number} op
		 * @returns {void}   */
		globalCompositeOperation(op) {
			switch (op) {
			case  0: s.ctx.globalCompositeOperation = "source-over"      ;break
			case  1: s.ctx.globalCompositeOperation = "source-in"        ;break
			case  2: s.ctx.globalCompositeOperation = "source-out"       ;break
			case  3: s.ctx.globalCompositeOperation = "source-atop"      ;break
			case  4: s.ctx.globalCompositeOperation = "destination-over" ;break
			case  5: s.ctx.globalCompositeOperation = "destination-in"   ;break
			case  6: s.ctx.globalCompositeOperation = "destination-out"  ;break
			case  7: s.ctx.globalCompositeOperation = "destination-atop" ;break
			case  8: s.ctx.globalCompositeOperation = "lighter"          ;break
			case  9: s.ctx.globalCompositeOperation = "copy"             ;break
			case 10: s.ctx.globalCompositeOperation = "xor"              ;break
			case 11: s.ctx.globalCompositeOperation = "multiply"         ;break
			case 12: s.ctx.globalCompositeOperation = "screen"           ;break
			case 13: s.ctx.globalCompositeOperation = "overlay"          ;break
			case 14: s.ctx.globalCompositeOperation = "darken"           ;break
			case 15: s.ctx.globalCompositeOperation = "lighten"          ;break
			case 16: s.ctx.globalCompositeOperation = "color-dodge"      ;break
			case 17: s.ctx.globalCompositeOperation = "color-burn"       ;break
			case 18: s.ctx.globalCompositeOperation = "hard-light"       ;break
			case 19: s.ctx.globalCompositeOperation = "soft-light"       ;break
			case 20: s.ctx.globalCompositeOperation = "difference"       ;break
			case 21: s.ctx.globalCompositeOperation = "exclusion"        ;break
			case 22: s.ctx.globalCompositeOperation = "hue"              ;break
			case 23: s.ctx.globalCompositeOperation = "saturation"       ;break
			case 24: s.ctx.globalCompositeOperation = "color"            ;break
			case 25: s.ctx.globalCompositeOperation = "luminosity"       ;break
			}
		},
		// ------------------------------ /
		//            DRAW PATH           /
		// ------------------------------ /
		/**
		 * Begins a new path.
		 * @returns {void} */
		beginPath() {
			s.ctx.beginPath();
		},
		/**
		 * Clips the current path.
		 * @returns {void} */
		clip(
			/** @type {number} */ fill_rule,
		) {
			s.ctx.clip(FILL_RULE[fill_rule]);
		},
		/**
		 * Fills the current path.
		 * @returns {void} */
		fill(
			/** @type {number} */ fill_rule,
		) {
			s.ctx.fill(FILL_RULE[fill_rule])
		},
		/**
		 * Checks if the given point is inside the current path.
		 * @returns {boolean} */
		isPointInPath(
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ fill_rule,
		) {
			return s.ctx.isPointInPath(x, y, FILL_RULE[fill_rule])
		},
		/**
		 * Checks if the given point is inside the current stroke.
		 * @returns {boolean} */
		isPointInStroke(
			/** @type {number} */ x,
			/** @type {number} */ y,
		) {
			return s.ctx.isPointInStroke(x, y)
		},
		/**
		 * Strokes the current path.
		 * @returns {void} */
		stroke() {
			s.ctx.stroke()
		},

		// ------------------------------ /
		//      FILL STROKE STYLES        /
		// ------------------------------ /

		/** @returns {void} */
		fillStyle(
			/** @type {number} */ ptr,
			/** @type {number} */ len,
		) {
			const str = mem.load_string_raw(wasm.memory.buffer, ptr, len)
			s.ctx.fillStyle = str
		},
		/** @returns {void} */
		strokeStyle(
			/** @type {number} */ ptr,
			/** @type {number} */ len,
		) {
			const str = mem.load_string_raw(wasm.memory.buffer, ptr, len)
			s.ctx.strokeStyle = str
		},

		// ------------------------------ /
		//            FILTERS             /
		// ------------------------------ /

		/** @returns {void} */
		filter(
			/** @type {number} */ ptr,
			/** @type {number} */ len,
		) {
			const str = mem.load_string_raw(wasm.memory.buffer, ptr, len)
			s.ctx.filter = str
		},

		// ------------------------------ /
		//              PATH              /
		// ------------------------------ /

		/** @returns {void} */
		arc(
			/** @type {number}  */ x,
			/** @type {number}  */ y,
			/** @type {number}  */ radius,
			/** @type {number}  */ angle_start,
			/** @type {number}  */ angle_end,
			/** @type {boolean} */ counter_clockwise,
		) {
			s.ctx.arc(x, y, radius, angle_start, angle_end, counter_clockwise)
		},
		/** @returns {void} */
		arcTo(
			/** @type {number} */ x1,
			/** @type {number} */ y1,
			/** @type {number} */ x2,
			/** @type {number} */ y2,
			/** @type {number} */ radius,
		) {
			s.ctx.arcTo(x1, y1, x2, y2, radius)
		},
		/** @returns {void} */
		bezierCurveTo(
			/** @type {number} */ cp1x,
			/** @type {number} */ cp1y,
			/** @type {number} */ cp2x,
			/** @type {number} */ cp2y,
			/** @type {number} */ x,
			/** @type {number} */ y,
		) {
			s.ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y)
		},
		/** @returns {void} */
		closePath() {
			s.ctx.closePath()
		},
		/** @returns {void} */
		ellipse(	
			/** @type {number}  */ x,
			/** @type {number}  */ y,
			/** @type {number}  */ radius_x,
			/** @type {number}  */ radius_y,
			/** @type {number}  */ rotation,
			/** @type {number}  */ angle_start,
			/** @type {number}  */ angle_end,
			/** @type {boolean} */ counterclockwise,
		) {
			s.ctx.ellipse(x, y, radius_x, radius_y, rotation, angle_start, angle_end, counterclockwise)
		},
		/** @returns {void} */
		lineTo(
			/** @type {number} */ x,
			/** @type {number} */ y,
		) {
			s.ctx.lineTo(x, y)
		},
		/** @returns {void} */
		moveTo(
			/** @type {number} */ x,
			/** @type {number} */ y,
		) {
			s.ctx.moveTo(x, y)
		},
		/** @returns {void} */
		quadraticCurveTo(
			/** @type {number} */ cpx,
			/** @type {number} */ cpy,
			/** @type {number} */ x,
			/** @type {number} */ y,
		) {
			s.ctx.quadraticCurveTo(cpx, cpy, x, y)
		},
		/** @returns {void} */
		rect(
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ w,
			/** @type {number} */ h,
		) {
			s.ctx.rect(x, y, w, h)
		},
		/** @returns {void} */
		roundRect(
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ w,
			/** @type {number} */ h,
			/** @type {number} */ radii,
		) {
			s.ctx.roundRect(x, y, w, h, radii)
		},

		// ------------------------------ /
		//      PATH DRAWING STYLES       /
		// ------------------------------ /

		/** @returns {void} */
		lineCap(
			/** @type {number} */ cap,
		) {
			s.ctx.lineCap = LINE_CAP[cap]
		},
		/** @returns {void} */
		lineDashOffset(
			/** @type {number} */ offset,
		) {
			s.ctx.lineDashOffset = offset
		},
		/** @returns {void} */
		lineJoin(
			/** @type {number} */ join,
		) {
			s.ctx.lineJoin = LINE_JOIN[join]
		},
		/** @returns {void} */
		lineWidth(
			/** @type {number} */ width,
		) {
			s.ctx.lineWidth = width
		},
		/** @returns {void} */
		miterLimit(
			/** @type {number} */ limit,
		) {
			s.ctx.miterLimit = limit
		},
		/** @returns {void} */
		setLineDash(
			/** @type {number} */ ptr,
			/** @type {number} */ len,
		) {
			const data = new Float32Array(wasm.memory.buffer, ptr, len)
			s.ctx.setLineDash(/** @type {*} */ (data))
		},

		// ------------------------------ /
		//              RECT              /
		// ------------------------------ /

		/** @returns {void} */
		clearRect(
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ w,
			/** @type {number} */ h,
		) {
			s.ctx.clearRect(x, y, w, h)
		},
		/** @returns {void} */
		fillRect(
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ w,
			/** @type {number} */ h,
		) {
			s.ctx.fillRect(x, y, w, h)
		},
		/** @returns {void} */
		strokeRect(
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ w,
			/** @type {number} */ h,
		) {
			s.ctx.strokeRect(x, y, w, h)
		},

		// ------------------------------ /
		//         SHADOW STYLES          /
		// ------------------------------ /

		/** @returns {void} */
		shadowBlur(
			/** @type {number} */ blur,
		) {
			s.ctx.shadowBlur = blur
		},
		/** @returns {void} */
		shadowColor(
			/** @type {string} */ color,
		) {
			s.ctx.shadowColor = color
		},
		/** @returns {void} */
		shadowOffsetX(
			/** @type {number} */ offset_x,
		) {
			s.ctx.shadowOffsetX = offset_x
		},
		/** @returns {void} */
		shadowOffsetY(
			/** @type {number} */ offset_y,
		) {
			s.ctx.shadowOffsetY = offset_y
		},

		// ------------------------------ /
		//              STATE             /
		// ------------------------------ /

		/** @returns {void} */
		reset() {
			s.ctx.reset()
		},
		/** @returns {void} */
		restore() {
			s.ctx.restore()
		},
		/** @returns {void} */
		save() {
			s.ctx.save()
		},

		// ------------------------------ /
		//              TEXT              /
		// ------------------------------ /

		/** @returns {void} */
		fillTextNoMax(
			/** @type {string} */ text,
			/** @type {number} */ x,
			/** @type {number} */ y,
		) {
			s.ctx.fillText(text, x, y)
		},
		/** @returns {void} */
		fillTextMaxWidth(
			/** @type {string} */ text,
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ max_width,
		) {
			s.ctx.fillText(text, x, y, max_width)
		},
		/** @returns {void} */
		strokeTextNoMax(
			/** @type {string} */ text,
			/** @type {number} */ x,
			/** @type {number} */ y,
		) {
			s.ctx.strokeText(text, x, y)
		},
		/** @returns {void} */
		strokeTextMaxWidth(
			/** @type {string} */ text,
			/** @type {number} */ x,
			/** @type {number} */ y,
			/** @type {number} */ max_width,
		) {
			s.ctx.strokeText(text, x, y, max_width || undefined)
		},
		/** @returns {void} */
		measureText(
			/** @type {string} */ text,
			/** @type {number} */ ptr,
		) {
			const metrics = s.ctx.measureText(text)
			const offset  = new mem.ByteOffset(ptr)
			const data    = new DataView(wasm.memory.buffer)

			mem.store_offset_f32(data, offset, metrics.actualBoundingBoxAscent)
			mem.store_offset_f32(data, offset, metrics.actualBoundingBoxDescent)
			mem.store_offset_f32(data, offset, metrics.actualBoundingBoxLeft)
			mem.store_offset_f32(data, offset, metrics.actualBoundingBoxRight)
			mem.store_offset_f32(data, offset, metrics.alphabeticBaseline)
			mem.store_offset_f32(data, offset, metrics.emHeightAscent)
			mem.store_offset_f32(data, offset, metrics.emHeightDescent)
			mem.store_offset_f32(data, offset, metrics.fontBoundingBoxAscent)
			mem.store_offset_f32(data, offset, metrics.fontBoundingBoxDescent)
			mem.store_offset_f32(data, offset, metrics.hangingBaseline)
			mem.store_offset_f32(data, offset, metrics.ideographicBaseline)
			mem.store_offset_f32(data, offset, metrics.width)
		},

		// ------------------------------ /
		//      TEXT DRAWING STYLES       /
		// ------------------------------ /

		/** @returns {void} */
		direction(
			/** @type {number} */ value,
		) {
			s.ctx.direction = DIRECTION[value]
		},
		/** @returns {void} */
		font(
			/** @type {number} */ ptr,
			/** @type {number} */ len,
		) {
			s.ctx.font = mem.load_string_raw(wasm.memory.buffer, ptr, len)
		},
		/** @returns {void} */
		fontKerning(
			/** @type {number} */ value,
		) {
			s.ctx.fontKerning = FONT_KERNING[value]
		},
		/** @returns {void} */
		fontStretch(
			/** @type {number} */ value,
		) {
			s.ctx.fontStretch = FONT_STRETCH[value]
		},
		/** @returns {void} */
		fontVariantCaps(
			/** @type {number} */ value,
		) {
			s.ctx.fontVariantCaps = FONT_VARIANT_CAPS[value]
		},
		/** @returns {void} */
		letterSpacing(
			/** @type {number} */ ptr,
			/** @type {number} */ len,
		) {
			s.ctx.letterSpacing = mem.load_string_raw(wasm.memory.buffer, ptr, len)
		},
		/** @returns {void} */
		textAlign(
			/** @type {number} */ value,
		) {
			s.ctx.textAlign = TEXT_ALIGN[value]
		},
		/** @returns {void} */
		textBaseline(
			/** @type {number} */ value,
		) {
			s.ctx.textBaseline = TEXT_BASELINE[value]
		},
		/** @returns {void} */
		textRendering(
			/** @type {number} */ value,
		) {
			s.ctx.textRendering = TEXT_RENDERING[value]
		},
		/** @returns {void} */
		wordSpacing(
			/** @type {number} */ ptr,
			/** @type {number} */ len,
		) {
			s.ctx.wordSpacing = mem.load_string_raw(wasm.memory.buffer, ptr, len)
		},

		// ------------------------------ /
		//           TRANSFORM            /
		// ------------------------------ /

		/** @returns {void} */
		resetTransform() {
			s.ctx.resetTransform()
		},
		/** @returns {void} */
		getTransform(
			/** @type {number} */ ptr,
		) {
			const t      = s.ctx.getTransform()
			const data   = new DataView(wasm.memory.buffer)
			const offset = new mem.ByteOffset(ptr)

			mem.store_offset_f32(data, offset, t.a)
			mem.store_offset_f32(data, offset, t.b)
			mem.store_offset_f32(data, offset, t.c)
			mem.store_offset_f32(data, offset, t.d)
			mem.store_offset_f32(data, offset, t.e)
			mem.store_offset_f32(data, offset, t.f)
		},
		/** @returns {void} */
		setTransform(
			/** @type {number} */ a,
			/** @type {number} */ b,
			/** @type {number} */ c,
			/** @type {number} */ d,
			/** @type {number} */ e,
			/** @type {number} */ f,
		) {
			s.ctx.setTransform(a, b, c, d, e, f)
		},
		/** @returns {void} */
		transform(
			/** @type {number} */ a,
			/** @type {number} */ b,
			/** @type {number} */ c,
			/** @type {number} */ d,
			/** @type {number} */ e,
			/** @type {number} */ f,
		) {
			s.ctx.transform(a, b, c, d, e, f)
		},
		/** @returns {void} */
		rotate(
			/** @type {number} */ angle,
		) {
			s.ctx.rotate(angle)
		},
		/** @returns {void} */
		scale(
			/** @type {number} */ x,
			/** @type {number} */ y,
		) {
			s.ctx.scale(x, y)
		},
		/** @returns {void} */
		translate(
			/** @type {number} */ x,
			/** @type {number} */ y,
		) {
			s.ctx.translate(x, y)
		},
	}
}
