import * as mem from "../memory.js"


/** @typedef {import("../types.js").WasmState} Wasm_State */


export function Ctx2d_State() {
	this.ctx = /** @type {CanvasRenderingContext2D} */ (/** @type {*} */(null))
}

/** @type {Record<number, CanvasFillRule>} */
const CANVAS_FILL_RULE = {
	0: "nonzero",
	1: "evenodd",
}

/** @type {Record<number, CanvasLineCap>} */
const CANVAS_LINE_CAP = {
	0: "butt",
	1: "round",
	2: "square",
}

/** @type {Record<number, CanvasLineJoin>} */
const CANVAS_LINE_JOIN = {
	0: "miter",
	1: "round",
	2: "bevel",
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
		 * @param {number} fill_rule
		 * @returns {void}             */
		clip(fill_rule) {
			s.ctx.clip(CANVAS_FILL_RULE[fill_rule]);
		},
		/**
		 * Fills the current path.
		 * @param   {number} fill_rule
		 * @returns {void}               */
		fill(fill_rule) {
			s.ctx.fill(CANVAS_FILL_RULE[fill_rule])
		},
		/**
		 * Checks if the given point is inside the current path.
		 * @param   {number}             x
		 * @param   {number}             y
		 * @param   {number} fill_rule
		 * @returns {boolean}            */
		isPointInPath(x, y, fill_rule) {
			return s.ctx.isPointInPath(x, y, CANVAS_FILL_RULE[fill_rule])
		},
		/**
		 * Checks if the given point is inside the current stroke.
		 * @param   {number}  x
		 * @param   {number}  y
		 * @returns {boolean} */
		isPointInStroke(x, y) {
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

		/**
		 * @param   {string} color
		 * @returns {void}   */
		fillStyle(color) {
			s.ctx.fillStyle = color
		},
		/**
		 * @param   {string} color
		 * @returns {void}   */
		strokeStyle(color) {
			s.ctx.strokeStyle = color
		},

		// ------------------------------ /
		//            FILTERS             /
		// ------------------------------ /

		/**
		 * @param   {string} filter
		 * @returns {void}   */
		filter(filter) {
			s.ctx.filter = filter
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
			s.ctx.lineCap = CANVAS_LINE_CAP[cap]
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
			s.ctx.lineJoin = CANVAS_LINE_JOIN[join]
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
	}
}
