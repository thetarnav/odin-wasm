//+private file
package example

import     "core:fmt"
import     "core:math"
import glm "core:math/linalg/glsl"

import gl  "../wasm/webgl"
import ctx "../wasm/ctx2d"

ratio :: distinct f32
rvec2 :: distinct [2]f32

to_px :: proc(r: rvec2) -> vec2 {
	return vec2(r) * vec2(canvas_size) * dpr
}
to_rvec2 :: proc(p: vec2) -> rvec2 {
	return rvec2(p / vec2(canvas_size) / dpr)
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

	// update t
	s.t = math.mod(s.t + delta * 0.0008, 1.0)


	px_points: [4]vec2
	for p, i in s.points {
		px_points[i] = to_px(p)
	}
	p1 := px_points[0]
	p2 := px_points[1]
	p3 := px_points[2]
	p4 := px_points[3]

	q1 := glm.lerp(p1, p2, s.t)
	q2 := glm.lerp(p2, p3, s.t)
	q3 := glm.lerp(p3, p4, s.t)
	
	r1 := glm.lerp(q1, q2, s.t)
	r2 := glm.lerp(q2, q3, s.t)

	tp := glm.lerp(r1, r2, s.t)

	ctx.clearRect(0, 0, canvas_size.x, canvas_size.y)
	ctx.lineWidth(2)

	ctx.strokeStyle(GRAY)
	for p, i in px_points[1:] {
		ctx.beginPath()
		ctx.moveTo(p)
		ctx.lineTo(px_points[i])
		ctx.stroke()
	}

	ctx.strokeStyle(BLUE)
	ctx.beginPath()
	ctx.moveTo(q1)
	ctx.lineTo(q2)
	ctx.lineTo(q3)
	ctx.stroke()

	ctx.strokeStyle(GREEN)
	ctx.beginPath()
	ctx.moveTo(r1)
	ctx.lineTo(r2)
	ctx.stroke()

	ctx.strokeStyle(RED)
	ctx.beginPath()
	ctx.moveTo(p1)
	ctx.bezierCurveTo(p2, p3, p4)
	ctx.stroke()

	ctx.fillStyle(GRAY)
	ctx.strokeStyle(WHITE)
	for p in px_points {
		ctx.beginPath()
		ctx.arc(p, 6, 0, TAU)
		ctx.fill()
		ctx.stroke()
	}

	ctx.fillStyle(BLUE)
	ctx.strokeStyle(TRANSPARENT)
	for p in ([]vec2{q1, q2, q3}) {
		ctx.beginPath()
		ctx.arc(p, 6, 0, TAU)
		ctx.fill()
		ctx.stroke()
	}

	ctx.fillStyle(GREEN)
	ctx.strokeStyle(TRANSPARENT)
	for p in ([]vec2{r1, r2}) {
		ctx.beginPath()
		ctx.arc(p, 6, 0, TAU)
		ctx.fill()
		ctx.stroke()
	}

	ctx.fillStyle(RED)
	ctx.strokeStyle(TRANSPARENT)
	ctx.beginPath()	
	ctx.arc(tp, 6, 0, TAU)
	ctx.fill()
	ctx.stroke()
}
