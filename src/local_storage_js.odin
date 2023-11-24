package hive

foreign import "local_storage"

@(default_calling_convention = "contextless")
foreign local_storage {
    // odinfmt: disable
	ls_key        :: proc(index: int, key: []byte) -> int ---
	ls_key_bytes  :: proc(index: int, key: []byte) -> int ---
	ls_get_bytes  :: proc(key: string, value: []byte) -> int ---
	ls_set_bytes  :: proc(key: string, value: []byte) ---
	ls_get_string :: proc(key: string, value: []byte) -> int ---
	ls_set_string :: proc(key: string, value: []byte) ---
	ls_remove     :: proc(key: string) ---
	ls_length     :: proc() -> int ---
	ls_clear      :: proc() ---
    // odinfmt: enable
}

Ls_Item_Type :: enum {
	Post,
	Id,
}

LS_POST_KEY_PREFIX :: "post_"
LS_POST_KEY_PREFIX_LEN :: len(LS_POST_KEY_PREFIX)
LS_KEY_MAX_LEN :: LS_POST_KEY_PREFIX_LEN + 8

@(require_results)
get_ls_key :: proc(timestamp: i64) -> string {
	buf: [LS_KEY_MAX_LEN]byte
	copy(buf[:], LS_POST_KEY_PREFIX)
	timestamp_bytes := transmute([8]byte)(i64le(timestamp))
	copy(buf[LS_POST_KEY_PREFIX_LEN:], timestamp_bytes[:])
	return string(buf[:])
}

@(require_results)
get_timestamp_from_ls_key :: proc(key: string) -> (timestamp: i64) {
	assert(len(key) == LS_KEY_MAX_LEN)

	timestamp_bytes: [8]byte
	copy(timestamp_bytes[:], key[LS_POST_KEY_PREFIX_LEN:])
	return i64(transmute(i64le)(timestamp_bytes))
}
