package hive

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:time"


@(require_results)
timestamp_now :: proc() -> i64 {
	return time.now()._nsec / 1e6
}

@(export)
store_own_post :: proc(_content_length: uint) {
	context.allocator = mem.arena_allocator(&{data = temp_buf})

	buf: [1024]byte
	content_length := load_last_string(buf[:])
	content := string(buf[:content_length])

	post := Post {
		author    = own_id,
		content   = content,
		timestamp = timestamp_now(),
	}

	s: Serializer
	err := serializer_init_writer(&s);defer serializer_destroy_writer(s)

	if err == nil && serialize_post(&s, &post) {
		ls_key := get_ls_key(post.timestamp)
		fmt.println("storing post", own_id, s.data[:])
		ls_set_bytes(ls_key, s.data[:])
	}

	publish()
	notify_post_subscribers(&post)
}

read_post :: proc() {
	buf: [1024]byte
	len := ls_get_bytes("HEY", buf[:])

	s: Serializer
	serializer_init_reader(&s, buf[:len])

	post: Post

	serialize_post(&s, &post)

	fmt.println(post.content, post.timestamp)
}


@(require_results)
load_stored_post :: proc(key: string) -> (post: Post, ok: bool) {
	value_buf: [1024]byte
	value_len := ls_get_bytes(key, value_buf[:])
	(value_len > 0) or_return

	s: Serializer
	serializer_init_reader(&s, value_buf[:value_len])

	serialize_post(&s, &post)

	return post, true
}

@(require_results)
load_all_stored_posts :: proc(
	allocator := context.allocator,
) -> (
	posts: []Post,
	err: mem.Allocator_Error,
) {
	length := ls_length()

	posts = make([]Post, length, allocator) or_return

	posts_i := 0
	for ls_i in 0 ..< length {
		key_buf: [LS_KEY_MAX_LEN]byte
		key_len := ls_key_bytes(ls_i, key_buf[:])
		key := string(key_buf[:key_len])
		if !strings.has_prefix(key, LS_POST_KEY_PREFIX) do continue

		post, ok := load_stored_post(key)
		if !ok do continue

		posts[posts_i] = post
		posts_i += 1
	}

	posts = posts[:posts_i]

	return
}


@(export)
loadAllStoredPosts :: proc() -> ^[]Post {
	context.allocator = mem.arena_allocator(&{data = temp_buf})

	posts, err := load_all_stored_posts()
	assert(err == nil, "load_all_stored_posts failed")

	return &posts
}
