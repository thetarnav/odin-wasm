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

SHAPE_CREATOR_RECT :: ctx.Rect{40, 40, 260, 260}

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

	/*
	Shape creator
	*/

	hovering_shape_creator := is_vec_in_rect(mouse_pos * dpr, rect_with_margin(SHAPE_CREATOR_RECT, 4))

	if s.draggig == -1 && hovering_shape_creator && mouse_down {
		for p, i in sa.slice(&s.shape) {
			if distance(mouse_pos * dpr, rect_rvec_to_px(p, SHAPE_CREATOR_RECT)) < 6 {
				s.draggig = i
				break
			}
		}
	}

	if s.draggig != -1 && mouse_down {
		s.shape.data[s.draggig] = rvec_clamp(vec_to_rect_rvec(mouse_pos * dpr, SHAPE_CREATOR_RECT))
	}

	if s.draggig != -1 && !mouse_down {
		s.draggig = -1
	}

	ctx.path_rect_rounded(SHAPE_CREATOR_RECT, 8)
	ctx.fillStyle(to_rgba(GRAY.xyz, 24))
	ctx.fill()
	ctx.strokeStyle(to_rgba(GRAY.xyz, 60))
	ctx.stroke()

	for p, i in sa.slice(&s.shape) {
		if hovering_shape_creator {
			ctx.path_circle(rect_rvec_to_px(p, SHAPE_CREATOR_RECT), 6)
			ctx.fillStyle(GRAY_1)
			ctx.fill()
		}

		if i < sa.len(s.shape) - 1 {
			ctx.beginPath()
			ctx.moveTo(rect_rvec_to_px(p, SHAPE_CREATOR_RECT))
			ctx.lineTo(rect_rvec_to_px(sa.get(s.shape, i+1), SHAPE_CREATOR_RECT))
			ctx.strokeStyle(GRAY_1)
			ctx.stroke()
		}
	}
}

is_vec_in_rect :: proc (p: vec2, r: ctx.Rect) -> bool
{
	return p.x >= r.x && p.x <= r.x + r.w && p.y >= r.y && p.y <= r.y + r.h
}

rect_rvec_to_px :: proc (p: rvec2, r: ctx.Rect) -> vec2
{
	return vec2(p) * ctx.rect_size(r) + ctx.rect_pos(r)
}

vec_to_rect_rvec :: proc (p: vec2, r: ctx.Rect) -> rvec2
{
	return rvec2((p - ctx.rect_pos(r)) / ctx.rect_size(r))
}

rect_with_margin :: proc (r: ctx.Rect, margin: f32) -> ctx.Rect
{
	return ctx.Rect{r.x - margin, r.y - margin, r.w + margin * 2, r.h + margin * 2}
}

rvec_clamp :: proc (v: rvec2) -> rvec2
{
	return rvec2{clamp(v.x, 0, 1), clamp(v.y, 0, 1)}
}
