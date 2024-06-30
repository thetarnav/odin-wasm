package obj

import "core:fmt"
import "core:testing"
import "core:strings"


@test
test_obj_parser :: proc (t: ^testing.T)
{
	obj_file := `# hello
v 1.0 0.0 0.0
v 0.0 1.0 0.0
v 0.0 0.0 1.0
vn 0.0 0.0 1.0
vn 0.0 1.0 0.0
vn 1.0 0.0 0.0
vt 0.0 0.0
vt 1.0 0.0
vt 0.0 1.0
f 1/1/1 2/2/2 3/3/3
f 1/1/1 3/3/3 2/2/2
f 2/2/2 3/3/3 1/1/1
f 2/2/2 1/1/1 3/3/3
f 3/3/3 1/1/1 2/2/2
f 3/3/3 2/2/2 1/1/1
`

	data: Data

	it := obj_file
	for line in strings.split_lines_iterator(&it) {
		parse_line(&data, line)
	}

	fmt.println(data)
}
