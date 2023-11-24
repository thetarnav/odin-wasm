//+build js
package ls

foreign import "odin_ls"

@(default_calling_convention = "contextless")
foreign odin_ls {
    // odinfmt: disable
	key        :: proc(index: int, key: []byte) -> int ---
	key_bytes  :: proc(index: int, key: []byte) -> int ---
	get_bytes  :: proc(key: string, value: []byte) -> int ---
	set_bytes  :: proc(key: string, value: []byte) ---
	get_string :: proc(key: string, value: []byte) -> int ---
	set_string :: proc(key: string, value: []byte) ---
	remove     :: proc(key: string) ---
	length     :: proc() -> int ---
	clear      :: proc() ---
    // odinfmt: enable
}
