package ctx2d

import "core:testing"


@test
test_px_to_string :: proc (t: ^testing.T) {
	buf: Buf_px
	testing.expect_value(t, px_to_string(buf[:],           0),           "0px")
	testing.expect_value(t, px_to_string(buf[:],           1),          "+1px")
	testing.expect_value(t, px_to_string(buf[:],          10),         "+10px")
	testing.expect_value(t, px_to_string(buf[:],         100),        "+100px")
	testing.expect_value(t, px_to_string(buf[:],        1000),       "+1000px")
	testing.expect_value(t, px_to_string(buf[:],  2147483647), "+2147483647px")
	testing.expect_value(t, px_to_string(buf[:],          -1),          "-1px")
	testing.expect_value(t, px_to_string(buf[:],         -10),         "-10px")
	testing.expect_value(t, px_to_string(buf[:],        -100),        "-100px")
	testing.expect_value(t, px_to_string(buf[:],       -1000),       "-1000px")
	testing.expect_value(t, px_to_string(buf[:], -2147483647), "-2147483647px")
}

@test
test_rgba_to_string :: proc (t: ^testing.T) {
	buf: Buf_rgba
	testing.expect_value(t, rgba_to_string(buf[:], {  0,   0,   0,   0}), "#00000000")
	testing.expect_value(t, rgba_to_string(buf[:], {255,   0,   0,  47}), "#ff00002f")
	testing.expect_value(t, rgba_to_string(buf[:], {  0, 255,  47,   0}), "#00ff2f00")
	testing.expect_value(t, rgba_to_string(buf[:], {  0,  47, 255,   0}), "#002fff00")
	testing.expect_value(t, rgba_to_string(buf[:], { 47,   0,   0, 255}), "#2f0000ff")
	testing.expect_value(t, rgba_to_string(buf[:], {255, 255, 255, 255}), "#ffffffff")
}
