//+private file
package example

import "core:fmt"
import sa "core:container/small_array"

import gl  "../wasm/webgl"
import ctx "../wasm/ctx2d"


@private
State_Lathe :: struct {
	shape: sa.Small_Array(32, vec2),
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

	sa.append(&s.shape, vec2{0, 0}, vec2{0.25, 0.75}, vec2{1, 1})
}

@private
frame_lathe :: proc (s: ^State_Lathe, delta: f32)
{
	ctx.resetTransform()
	ctx.clearRect(0, canvas_size * dpr)

	/*
	Shape creator
	*/

	ctx.path_rect_rounded(SHAPE_CREATOR_RECT, 8)
	ctx.fillStyle(to_rgba(GRAY.xyz, 24))
	ctx.fill()
	ctx.strokeStyle(to_rgba(GRAY.xyz, 60))
	ctx.stroke()

	for p in sa.slice(&s.shape) {
		ctx.path_circle(p * ctx.rect_size(SHAPE_CREATOR_RECT) + ctx.rect_pos(SHAPE_CREATOR_RECT), 6)
		ctx.fillStyle(GRAY)
		ctx.fill()
	}
}
