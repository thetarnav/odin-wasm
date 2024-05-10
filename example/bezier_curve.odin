//+private file
package example

import glm "core:math/linalg/glsl"
import "core:fmt"
import "core:math"

import gl  "../wasm/webgl"
import ctx "../wasm/ctx2d"

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

	s.points[0] = {-0.2,  0.2}
	s.points[1] = {-0.2, -0.2}
	s.points[2] = { 0.2, -0.2}
	s.points[3] = { 0.2,  0.2}
}

@private
frame_bezier_curve :: proc(s: ^State_Bezier_Curve, delta: f32) {

	// update t
	s.t = math.mod(s.t + delta * 0.0008, 1.0)

	// dragging
	if mouse_down {
		for &p in s.points {
			if glm.distance_vec2(to_px(p), mouse_pos) < 10 {
				p = to_rvec2(mouse_pos)
			}
		}
	}


	px_points: [4]vec2
	for p, i in s.points {
		px_points[i] = to_px(p)
	}
	p1 := px_points[0]
	p2 := px_points[1]
	p3 := px_points[2]
	p4 := px_points[3]

	q1 := lerp(p1, p2, s.t)
	q2 := lerp(p2, p3, s.t)
	q3 := lerp(p3, p4, s.t)
	
	r1 := lerp(q1, q2, s.t)
	r2 := lerp(q2, q3, s.t)

	tp := lerp(r1, r2, s.t)

	
	ctx.resetTransform()
	ctx.clearRect(0, 0, canvas_size.x * dpr, canvas_size.y * dpr)

	// debug info
	
	ctx.font("32px monospace")
	ctx.lineWidth(2)
	ctx.fillStyle(WHITE)
	ctx.fillText(fmt.tprintf("mouse_pos:  %v", mouse_pos), 50, 50)
	ctx.fillText(fmt.tprintf("mouse_rel:  %v", mouse_rel), 50, 100)
	ctx.fillText(fmt.tprintf("mouse_down: %v", mouse_down), 50, 150)
	ctx.fillText(fmt.tprintf("p1:         %v", p1), 50, 200)
	ctx.fillText(fmt.tprintf("p2:         %v", p2), 50, 250)
	ctx.fillText(fmt.tprintf("p3:         %v", p3), 50, 300)
	ctx.fillText(fmt.tprintf("p4:         %v", p4), 50, 350)
	// ctx.fillText(fmt.tprintf("dist:       %v", glm.distance_vec2(p1, mouse_pos)), 50, 200)
	
	// draw
	
	// ctx.translate(canvas_size/2 * dpr)

	SHADOWS :: 8
	for shadow in f32(0)..<SHADOWS {
		ctx.globalAlpha(1.0 - shadow/SHADOWS)

		defer {
			m: mat3 = 1
			m *= mat3_translate(p4 - p1)
			m *= mat3_translate((p1 - p3)/2)
			m *= mat3_rotate(-PI/3)
			m *= mat3_scale(0.8)
			m *= mat3_translate((p3 - p1)/2)
			ctx.transform(m)
		}
	
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
		ctx.arc(tp, 8, 0, TAU)
		ctx.fill()
		ctx.stroke()
	}
}
