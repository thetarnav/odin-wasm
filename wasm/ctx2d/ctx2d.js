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

		/**
		 * @param   {number}  x
		 * @param   {number}  y
		 * @param   {number}  radius
		 * @param   {number}  angle_start
		 * @param   {number}  angle_end
		 * @param   {boolean} counterclockwise
		 * @returns {void}     */
		arc(x, y, radius, angle_start, angle_end, counterclockwise) {
			s.ctx.arc(x, y, radius, angle_start, angle_end, counterclockwise)
		},
		/**
		 * @param   {number} x1
		 * @param   {number} y1
		 * @param   {number} x2
		 * @param   {number} y2
		 * @param   {number} radius
		 * @returns {void}   */
		arcTo(x1, y1, x2, y2, radius) {
			s.ctx.arcTo(x1, y1, x2, y2, radius)
		},
		/**
		 * @param   {number} cp1x
		 * @param   {number} cp1y
		 * @param   {number} cp2x
		 * @param   {number} cp2y
		 * @param   {number} x
		 * @param   {number} y
		 * @returns {void}   */
		bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y) {
			s.ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y)
		},
		/** @returns {void} */
		closePath() {
			s.ctx.closePath()
		},
		/**
		 * @param   {number}  x
		 * @param   {number}  y
		 * @param   {number}  radius_x
		 * @param   {number}  radius_y
		 * @param   {number}  rotation
		 * @param   {number}  angle_start
		 * @param   {number}  angle_end
		 * @param   {boolean} counterclockwise
		 * @returns {void}
		 */
		ellipse(x, y, radius_x, radius_y, rotation, angle_start, angle_end, counterclockwise) {
			s.ctx.ellipse(x, y, radius_x, radius_y, rotation, angle_start, angle_end, counterclockwise)
		},
		/**
		 * @param   {number} x
		 * @param   {number} y
		 * @returns {void}   */
		lineTo(x, y) {
			s.ctx.lineTo(x, y)
		},
		/**
		 * @param   {number} x
		 * @param   {number} y
		 * @returns {void}   */
		moveTo(x, y) {
			s.ctx.moveTo(x, y)
		},
		/**
		 * @param   {number} cpx
		 * @param   {number} cpy
		 * @param   {number} x
		 * @param   {number} y
		 * @returns {void}   */
		quadraticCurveTo(cpx, cpy, x, y) {
			s.ctx.quadraticCurveTo(cpx, cpy, x, y)
		},
		/**
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} w
		 * @param   {number} h
		 * @returns {void}   */
		rect(x, y, w, h) {
			s.ctx.rect(x, y, w, h)
		},
		/**
		 * @param   {number} x
		 * @param   {number} y
		 * @param   {number} w
		 * @param   {number} h
		 * @param   {number} radii
		 * @returns {void}   */
		roundRect(x, y, w, h, radii) {
			s.ctx.roundRect(x, y, w, h, radii)
		},

		// ------------------------------ /
		//      PATH DRAWING STYLES       /
		// ------------------------------ /

		/**
		 * @param   {number} cap
		 * @returns {void}          */
		lineCap(cap) {
			s.ctx.lineCap = CANVAS_LINE_CAP[cap]
		},
		/**
		 * @param   {number} offset
		 * @returns {void}   */
		lineDashOffset(offset) {
			s.ctx.lineDashOffset = offset
		},
		/**
		 * @param   {number} join
		 * @returns {void}           */
		lineJoin(join) {
			s.ctx.lineJoin = CANVAS_LINE_JOIN[join]
		},
		/**
		 * @param   {number} width
		 * @returns {void}   */
		lineWidth(width) {
			s.ctx.lineWidth = width
		},
		/**
		 * @param   {number} limit
		 * @returns {void}   */
		miterLimit(limit) {
			s.ctx.miterLimit = limit
		},
		/**
		 * @param   {number} ptr
		 * @param   {number} len
		 * @returns {void}     */
		setLineDash(ptr, len) {
			const data = new Float32Array(wasm.memory.buffer, ptr, len)
			s.ctx.setLineDash(/** @type {*} */ (data))
		},
	}
}