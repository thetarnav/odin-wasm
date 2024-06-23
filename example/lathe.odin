//+private file
package example

import "core:fmt"

import gl  "../wasm/webgl"
import ctx "../wasm/ctx2d"

@private
State_Lathe :: struct {
	
}

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

}
