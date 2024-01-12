/*

Copied from the Odin/vendor/wasm
https://github.com/odin-lang/Odin/tree/master/vendor/wasm

*/

//+build js
package wasm

foreign import "odin_env"

@(default_calling_convention = "contextless")
foreign odin_env {
	trap :: proc() -> ! ---
	abort :: proc() -> ! ---
	alert :: proc(msg: string) ---
	evaluate :: proc(str: string) ---
}
