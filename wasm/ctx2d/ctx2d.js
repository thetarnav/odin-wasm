import * as mem from "../memory.js"


/** @typedef {import("../types.js").WasmState} Wasm_State */


export function Ctx2d_State() {
	this.ctx = /** @type {CanvasRenderingContext2D} */ (/** @type {*} */(null))
}

/** @enum {typeof CanvasFillRuleEnum[keyof typeof CanvasFillRuleEnum]} */
const CanvasFillRuleEnum = /** @type {const} */({
	nonzero: 0,
	evenodd: 1,
})

/** @type {Record<CanvasFillRuleEnum, CanvasFillRule>} */
const CANVAS_FILL_RULE = {
	0: "nonzero",
	1: "evenodd",
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
		/** @returns {number} */
		getGlobalAlpha() {
			return s.ctx.globalAlpha
		},
		/**
		 * @param   {number} alpha
		 * @returns {void}   */
		setGlobalAlpha(alpha) {
			s.ctx.globalAlpha = alpha
		},
		/** @returns {number} */
		getGlobalCompositeOperation() {
			switch (s.ctx.globalCompositeOperation) {
			case "source-over":       return  0
			case "source-in":         return  1
			case "source-out":        return  2
			case "source-atop":       return  3
			case "destination-over":  return  4
			case "destination-in":    return  5
			case "destination-out":   return  6
			case "destination-atop":  return  7
			case "lighter":           return  8
			case "copy":              return  9
			case "xor":               return 10
			case "multiply":          return 11
			case "screen":            return 12
			case "overlay":           return 13
			case "darken":            return 14
			case "lighten":           return 15
			case "color-dodge":       return 16
			case "color-burn":        return 17
			case "hard-light":        return 18
			case "soft-light":        return 19
			case "difference":        return 20
			case "exclusion":         return 21
			case "hue":               return 22
			case "saturation":        return 23
			case "color":             return 24
			case "luminosity":        return 25
			}
		},
		/**
		 * @param   {number} op
		 * @returns {void}   */
		setGlobalCompositeOperation(op) {
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
		 * @returns {void}
		 */
		beginPath() {
			s.ctx.beginPath();
		},
		/**
		 * Clips the current path.
		 * @param {CanvasFillRuleEnum} fill_rule
		 * @returns {void}
		 */
		clip(fill_rule) {
			s.ctx.clip(CANVAS_FILL_RULE[fill_rule]);
		},
		/**
		 * Fills the current path.
		 * @param {CanvasFillRuleEnum} fill_rule
		 * @returns {void}
		 */
		fill(fill_rule) {
			s.ctx.fill(CANVAS_FILL_RULE[fill_rule])
		},
		/**
		 * Checks if the given point is inside the current path.
		 * @param {number} x
		 * @param {number} y
		 * @param {CanvasFillRuleEnum} fill_rule
		 * @returns {boolean}
		 */
		isPointInPath(x, y, fill_rule) {
			return s.ctx.isPointInPath(x, y, CANVAS_FILL_RULE[fill_rule])
		},
		/**
		 * Checks if the given point is inside the current stroke.
		 * @param {number} x
		 * @param {number} y
		 * @returns {boolean}
		 */
		isPointInStroke(x, y) {
			return s.ctx.isPointInStroke(x, y)
		},
		/**
		 * Strokes the current path.
		 * @returns {void}
		 */
		stroke() {
			s.ctx.stroke()
		},
	}
}