//+private file
package example

import "core:fmt"
import sa "core:container/small_array"

import gl  "../wasm/webgl"
import ctx "../wasm/ctx2d"


@private
State_Lathe :: struct {
	shape:   sa.Small_Array(32, rvec2),
	draggig: int, // shape index
}

SHAPE_CREATOR_RECT :: ctx.Rect{40, 260}

@private
setup_lathe :: proc (s: ^State_Lathe, _: gl.Program)
{
	ok := ctx.setCurrentContextById("canvas-0")
	if !ok {
		fmt.eprintfln("failed to set current context")
		return
	}

	sa.append(&s.shape, rvec2{0, 0}, rvec2{0.25, 0.75}, rvec2{1, 1})

	s.draggig = -1
}

@private
frame_lathe :: proc (s: ^State_Lathe, delta: f32)
{
	ctx.resetTransform()
	ctx.clearRect(0, canvas_size * dpr)

	mouse_dpr := mouse_pos * dpr

	is_double_click_frame := mouse_down_frame && mouse_down_time - mouse_down_time_prev < 0.3

	/*
	Shape creator
	*/

	hovering_shape_creator := is_vec_in_rect(mouse_dpr, rect_with_margin(SHAPE_CREATOR_RECT, 4))

	hovered_shape_point         := -1
	hovered_shape_edge_midpoint := -1
	
	find_hover_point: if hovering_shape_creator {
		// find hovered shape point
		for p, i in sa.slice(&s.shape) {
			if distance(mouse_dpr, rect_rvec_to_px(p, SHAPE_CREATOR_RECT)) < 8 {
				hovered_shape_point = i
				break find_hover_point
			}
		}

		// find hovered shape edge midpoint
		for i in 0 ..< s.shape.len-1 {
			a := sa.get(s.shape, i+0)
			b := sa.get(s.shape, i+1)
			m := (a + b) / 2

			if distance(mouse_dpr, rect_rvec_to_px(m, SHAPE_CREATOR_RECT)) < 8 {
				hovered_shape_edge_midpoint = i
				break find_hover_point
			}
		}
	}

	if s.draggig == -1 && hovering_shape_creator && mouse_down {

		if hovered_shape_point != -1 {
			// remove point on double click
			if is_double_click_frame && sa.len(s.shape) > 2 {
				sa.ordered_remove(&s.shape, hovered_shape_point)
			}\
			// start dragging point
			else {
				s.draggig = hovered_shape_point
			}
		}\
		// add point
		else if hovered_shape_edge_midpoint != -1 {
			sa.inject_at(&s.shape, vec_to_rect_rvec(mouse_dpr, SHAPE_CREATOR_RECT), hovered_shape_edge_midpoint+1)
			s.draggig = hovered_shape_edge_midpoint+1
			hovered_shape_edge_midpoint = -1
		}
	}

	// update dragging
	if s.draggig != -1 && mouse_down {
		s.shape.data[s.draggig] = rvec_clamp(vec_to_rect_rvec(mouse_dpr, SHAPE_CREATOR_RECT))
	}

	// end dragging
	if s.draggig != -1 && !mouse_down {
		s.draggig = -1
	}

	ctx.path_rect_rounded(SHAPE_CREATOR_RECT, 8)
	ctx.fillStyle(to_rgba(GRAY.xyz, 24))
	ctx.fill()
	ctx.strokeStyle(to_rgba(GRAY.xyz, 60))
	ctx.stroke()

	// draw shape edges
	for i in 0 ..< sa.len(s.shape)-1 {

		p0 := sa.get(s.shape, i+0)
		p1 := sa.get(s.shape, i+1)
		ctx.beginPath()
		ctx.moveTo(rect_rvec_to_px(p0, SHAPE_CREATOR_RECT))
		ctx.lineTo(rect_rvec_to_px(p1, SHAPE_CREATOR_RECT))
		ctx.strokeStyle(GRAY_2)
		ctx.stroke()
	}

	// draw shape points
	if hovering_shape_creator || s.draggig != -1 {

		for p, i in sa.slice(&s.shape) {
			ctx.path_circle(rect_rvec_to_px(p, SHAPE_CREATOR_RECT), 6)
			ctx.fillStyle(i == hovered_shape_point || i == s.draggig ? GRAY_1 : GRAY_2)
			ctx.fill()
		}
	}

	// draw shape edge hovered midpoint
	if hovered_shape_edge_midpoint != -1 {

		p0 := sa.get(s.shape, hovered_shape_edge_midpoint+0)
		p1 := sa.get(s.shape, hovered_shape_edge_midpoint+1)
		m  := (p0 + p1) / 2
		ctx.path_circle(rect_rvec_to_px(m, SHAPE_CREATOR_RECT), 6)
		ctx.fillStyle(GRAY_3)
		ctx.fill()
	}
}

is_vec_in_rect :: proc (p: vec2, r: ctx.Rect) -> bool
{
	return p.x >= r.x && p.x <= r.x + r.size.x && p.y >= r.y && p.y <= r.y + r.size.y
}

rect_rvec_to_px :: proc (p: rvec2, r: ctx.Rect) -> vec2
{
	return vec2(p) * r.size + r
}

vec_to_rect_rvec :: proc (p: vec2, r: ctx.Rect) -> rvec2
{
	return rvec2((p - r) / r.size)
}

rect_with_margin :: proc (r: ctx.Rect, margin: f32) -> ctx.Rect
{
	return ctx.Rect{r.pos - margin, r.size + margin * 2}
}

rvec_clamp :: proc (v: rvec2) -> rvec2
{
	return rvec2{clamp(v.x, 0, 1), clamp(v.y, 0, 1)}
}
