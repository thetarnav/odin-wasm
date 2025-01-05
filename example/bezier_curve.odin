#+private file
package example

import "core:fmt"

import gl  "../wasm/webgl"
import ctx "../wasm/ctx2d"

@private
State_Bezier_Curve :: struct {
	points:  [4]rvec2,
	t:       f32,
	draggig: int,
}

@private
setup_bezier_curve :: proc(s: ^State_Bezier_Curve, _: gl.Program) {
	ok := ctx.setCurrentContextById("canvas-0")
	if !ok {
		fmt.eprintfln("failed to set current context")
		return
	}

	s.points[0] = {-0.15,  0  }
	s.points[1] = {-0.10, -0.2}
	s.points[2] = { 0.10,  0.2}
	s.points[3] = { 0.15,  0  }

	s.draggig = -1
}

@private
frame_bezier_curve :: proc(s: ^State_Bezier_Curve, delta: f32) {

	// update t
	s.t = mod(s.t + delta * 0.0008, 1.0)

	// dragging
	switch {
	case s.draggig == -1 && mouse_down:
		for &p, i in s.points {
			if distance(to_px(p), to_px(mouse_rel)) < 10 {
				p = mouse_rel
				s.draggig = i
				break
			}
		}
	case s.draggig != -1 && mouse_down:
		s.points[s.draggig] = mouse_rel
	case s.draggig != -1 && !mouse_down:
		s.draggig = -1
	}

	// calc
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

	a12 := vec2_angle(p1, p2)
	a34 := vec2_angle(p3, p4)


	ctx.resetTransform()
	ctx.clearRect(0, canvas_size * dpr)

	// debug info
	{
		Fill_Text :: struct {
			pos:         [2]f32,
			line_height: f32,
			line_number: f32,
		}
		fill_text_line :: proc(t: ^Fill_Text, str: string) {
			ctx.fillText(str, t.pos.x, t.pos.y + t.line_height*t.line_number)
			t.line_number += 1
		}

		ctx.font("26px monospace")
		ctx.fillStyle(to_rgba(WHITE.rgb, 100))

		t := Fill_Text{
			pos         = {30, 50},
			line_height = 30,
		}
		fill_text_line(&t, fmt.tprintf("mouse_down: %t",           mouse_down))
		fill_text_line(&t, fmt.tprintf("dragging:   %i",           s.draggig))
		fill_text_line(&t, fmt.tprintf("mouse_rel:  %+.2f, %+.2f", mouse_rel.x       , mouse_rel.y       ))
		fill_text_line(&t, fmt.tprintf("mouse_pos:  %+.2f, %+.2f", to_px(mouse_rel).x, to_px(mouse_rel).y))
		fill_text_line(&t, fmt.tprintf("p1:         %+.2f, %+.2f", p1.x              , p1.y              ))
		fill_text_line(&t, fmt.tprintf("p2:         %+.2f, %+.2f", p2.x              , p2.y              ))
		fill_text_line(&t, fmt.tprintf("p3:         %+.2f, %+.2f", p3.x              , p3.y              ))
		fill_text_line(&t, fmt.tprintf("p4:         %+.2f, %+.2f", p4.x              , p4.y              ))
		fill_text_line(&t, fmt.tprintf("a12:        %f",           a12))
		fill_text_line(&t, fmt.tprintf("a34:        %f",           a34))
	}

	// draw

	ctx.lineWidth(2)

	ctx.translate(canvas_size/2 * dpr)

	SHADOWS :: 12
	for shadow in f32(0)..<SHADOWS {
		alpha := u8(255 * (SHADOWS-shadow) / SHADOWS)

		defer {
			m: mat3 = 1
			m *= mat3_translate(p4 - p1)
			m *= mat3_translate(p1)
			m *= mat3_rotate(-a34 -a12)
			m *= mat3_scale({0.8, -0.8})
			m *= mat3_translate(-p1)
			ctx.transform(m)
		}

		ctx.strokeStyle(to_rgba(GRAY.rgb, alpha))
		for p, i in px_points[1:] {
			ctx.beginPath()
			ctx.moveTo(p)
			ctx.lineTo(px_points[i])
			ctx.stroke()
		}

		ctx.strokeStyle(to_rgba(BLUE.rgb, alpha))
		ctx.beginPath()
		ctx.moveTo(q1)
		ctx.lineTo(q2)
		ctx.lineTo(q3)
		ctx.stroke()

		ctx.strokeStyle(to_rgba(GREEN.rgb, alpha))
		ctx.beginPath()
		ctx.moveTo(r1)
		ctx.lineTo(r2)
		ctx.stroke()

		ctx.strokeStyle(to_rgba(RED.rgb, alpha))
		ctx.beginPath()
		ctx.moveTo(p1)
		ctx.bezierCurveTo(p2, p3, p4)
		ctx.stroke()

		if shadow == 0 {
			ctx.fillStyle(to_rgba(GRAY.rgb, alpha))
			ctx.strokeStyle(to_rgba(WHITE.rgb, alpha))
			for p, pi in px_points {
				ctx.path_circle(p, 6)
				if s.draggig == pi {
					ctx.fillStyle(to_rgba(WHITE.rgb, alpha))
					ctx.fill()
					ctx.stroke()
					ctx.fillStyle(to_rgba(GRAY.rgb, alpha))
				} else {
					ctx.fill()
					ctx.stroke()
				}
			}
		}

		ctx.fillStyle(to_rgba(RED.rgb, alpha))
		ctx.strokeStyle(TRANSPARENT)
		ctx.path_circle(tp, 10)
		ctx.fill()
		ctx.stroke()
	}
}
