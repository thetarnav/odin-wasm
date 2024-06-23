//+private file
package example

import "core:fmt"

import gl  "../wasm/webgl"
import ctx "../wasm/ctx2d"

@private
State_Lathe :: struct {
	
}

SHAPE_CREATOR_RECT :: Rect{40, 40, 260, 260}

@private
setup_lathe :: proc(s: ^State_Lathe, _: gl.Program) {
	ok := ctx.setCurrentContextById("canvas-0")
	if !ok {
		fmt.eprintfln("failed to set current context")
		return
	}

	
}

@private
frame_lathe :: proc(s: ^State_Lathe, delta: f32) {

	ctx.resetTransform()
	ctx.clearRect(0, canvas_size * dpr)

	draw_rect_rounded(SHAPE_CREATOR_RECT, 8)
	ctx.fillStyle(to_rgba(GRAY.xyz, 24))
	ctx.fill()
	ctx.strokeStyle(to_rgba(GRAY.xyz, 60))
	ctx.stroke()
}

draw_rect_rounded :: proc (rect: Rect, r: f32) {
	using rect
	ctx.beginPath()
	ctx.moveTo(x + r, y)
	ctx.arcTo(x+w, y  , x+w, y+h, r)
	ctx.arcTo(x+w, y+h, x  , y+h, r)
	ctx.arcTo(x  , y+h, x  , y  , r)
	ctx.arcTo(x  , y  , x+w, y  , r)
}
