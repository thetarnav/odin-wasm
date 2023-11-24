package hive

import "core:mem"
import "core:slice"

Callback_Raw :: proc(data_ptr: rawptr)
Callback_Data :: struct {
	data_ptr: rawptr,
	callback: Callback_Raw,
}

@(private = "file")
cb_array: #soa[1024]Callback_Data

@(private = "file")
cb_offset: int

subscribe :: proc(data_ptr: ^$T, callback: proc(data_ptr: ^T)) -> (err: mem.Allocator_Error) {
	if cb_offset == len(cb_array) {
		return mem.Allocator_Error.Out_Of_Memory
	}

	cb_array[cb_offset] = {
		data_ptr = data_ptr,
		callback = Callback_Raw(callback),
	}
	cb_offset += 1

	return
}

unsubscribe :: proc(callback: proc(data_ptr: ^$T)) -> (ok: bool) {
	callbacks := cb_array.callback[:cb_offset]
	idx := slice.linear_search(callbacks, Callback_Raw(callback)) or_return

	cb_offset -= 1
	cb_array[idx] = cb_array[cb_offset]

	return true
}

publish :: proc() {
	for callback_data in cb_array[:cb_offset] {
		callback_data.callback(callback_data.data_ptr)
	}
}
