//+private file
package example

import "core:fmt"

import gl  "../wasm/webgl"
import ctx "../wasm/ctx2d"

ratio :: distinct f32
rvec2 :: distinct [2]f32

to_px :: proc(r: rvec2) -> vec2 {
	return vec2(r) * vec2(canvas_size) * dpr
}

@private
State_Bezier_Curve :: struct {
	points: [4]rvec2,
	t:      f32,
}

@private
setup_bezier_curve :: proc(s: ^State_Bezier_Curve, _: gl.Program) {
	ok := ctx.setCurrentContextById("canvas-0")
	if !ok {
		fmt.eprintfln("failed to set current context")
		return
	}

	s.points[0] = {0.3, 0.7}
	s.points[1] = {0.3, 0.3}
	s.points[2] = {0.7, 0.3}
	s.points[3] = {0.7, 0.7}
}

@private
frame_bezier_curve :: proc(s: ^State_Bezier_Curve, delta: f32) {

	px_points: [4]vec2
	for p, i in s.points {
		px_points[i] = to_px(p)
	}

	ctx.clearRect(0, 0, canvas_size.x, canvas_size.y)

	ctx.strokeStyle(GRAY)
	for p, i in px_points[1:] {
		ctx.beginPath()
		ctx.moveTo(p)
		ctx.lineTo(px_points[i])
		ctx.stroke()
	}

	ctx.fillStyle  (GRAY)
	ctx.strokeStyle(WHITE)
	for p in px_points {
		ctx.beginPath()
		ctx.arc(p, 6, 0, 2 * PI)
		ctx.fill()
		ctx.stroke()
	}
}
