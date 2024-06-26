//+private file
package example

import     "core:fmt"
import sa  "core:container/small_array"
import glm "core:math/linalg/glsl"
import     "core:slice"

import gl  "../wasm/webgl"
import ctx "../wasm/ctx2d"

MAX_SEGMENTS :: 32
DIVISIONS    :: 12
MAX_VERTICES :: ((MAX_SEGMENTS-3) * DIVISIONS + DIVISIONS) * 2 * 3

get_verts_len :: proc (segments: int) -> int {
	return ((segments-3) * DIVISIONS + DIVISIONS) * 2 * 3
}

@private
State_Lathe :: struct {
	using locations: Input_Locations_Lighting,
	vao            : VAO,
	positions      : [MAX_VERTICES]vec3,
	normals        : [MAX_VERTICES]vec3,
	colors         : [MAX_VERTICES]rgba,
	buffer_position: gl.Buffer,
	buffer_normal  : gl.Buffer,
	buffer_color   : gl.Buffer,
	light_angle    : f32,
	rotation       : mat4,
	shape          : sa.Small_Array(MAX_SEGMENTS, rvec2),
	dragging       : int, // shape index
}

SHAPE_CREATOR_RECT :: ctx.Rect{40, 260}

@private
setup_lathe :: proc (s: ^State_Lathe, program: gl.Program)
{
	s.vao = gl.CreateVertexArray()
	gl.BindVertexArray(s.vao)

	input_locations_lighting(s, program)

	gl.Enable(gl.CULL_FACE)  // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	ok := ctx.setCurrentContextById("canvas-0")
	if !ok {
		fmt.eprintfln("failed to set current context")
		return
	}

	sa.append(&s.shape, rvec2{0, 0}, rvec2{0.25, 0.75}, rvec2{1, 1})

	s.dragging = -1

	s.buffer_position = gl.CreateBuffer()
	s.buffer_normal   = gl.CreateBuffer()
	s.buffer_color    = gl.CreateBuffer()
}

@private
frame_lathe :: proc (s: ^State_Lathe, delta: f32)
{
	ctx.resetTransform()
	ctx.clearRect(0, canvas_size * dpr)

	mouse_dpr := mouse_pos * dpr

	is_double_click_frame := mouse_down_frame && mouse_down_time - mouse_down_time_prev < 0.3

	/*
	Shape creator
	*/

	hovering_shape_creator := is_vec_in_rect(mouse_dpr, rect_with_margin(SHAPE_CREATOR_RECT, 4))

	hovered_shape_point         := -1
	hovered_shape_edge_midpoint := -1
	
	find_hover_point: if hovering_shape_creator {
		// find hovered shape point
		for p, i in sa.slice(&s.shape) {
			if distance(mouse_dpr, rect_rvec_to_px(p, SHAPE_CREATOR_RECT)) < 10 {
				hovered_shape_point = i
				break find_hover_point
			}
		}

		// find hovered shape edge midpoint
		if sa.len(s.shape) < len(s.shape.data) {
			for i in 0 ..< sa.len(s.shape)-1 {
				a := sa.get(s.shape, i+0)
				b := sa.get(s.shape, i+1)
				m := (a + b) / 2
	
				if distance(mouse_dpr, rect_rvec_to_px(m, SHAPE_CREATOR_RECT)) < 10 {
					hovered_shape_edge_midpoint = i
					break find_hover_point
				}
			}
		}
	}

	if s.dragging == -1 && hovering_shape_creator && mouse_down {

		if hovered_shape_point != -1 {
			// remove point on double click
			if is_double_click_frame && sa.len(s.shape) > 2 {
				sa.ordered_remove(&s.shape, hovered_shape_point)
			}\
			// start dragging point
			else {
				s.dragging = hovered_shape_point
			}
		}\
		// add point
		else if hovered_shape_edge_midpoint != -1 {
			sa.inject_at(&s.shape, vec_to_rect_rvec(mouse_dpr, SHAPE_CREATOR_RECT), hovered_shape_edge_midpoint+1)
			s.dragging = hovered_shape_edge_midpoint+1
			hovered_shape_edge_midpoint = -1
		}
	}

	// update dragging
	if s.dragging != -1 && mouse_down {
		s.shape.data[s.dragging] = rvec_clamp(vec_to_rect_rvec(mouse_dpr, SHAPE_CREATOR_RECT))
		// keep cap points on the rect border
		if s.dragging == 0 {
			s.shape.data[s.dragging].x = 0
		} else if s.dragging == sa.len(s.shape)-1 {
			s.shape.data[s.dragging].y = 1
		}
	}

	// end dragging
	if s.dragging != -1 && !mouse_down {
		s.dragging = -1
	}

	// draw creator bg
	{
		ctx.path_rect_rounded(SHAPE_CREATOR_RECT, 8)
		ctx.fillStyle(to_rgba(GRAY.xyz, 24))
		ctx.fill()
		ctx.strokeStyle(to_rgba(GRAY.xyz, 60))
		ctx.stroke()
	}

	// draw shape
	{
		ctx.beginPath()
		
		first := sa.get(s.shape, 0)
		ctx.moveTo(rect_rvec_to_px(first, SHAPE_CREATOR_RECT))
		
		for p in sa.slice(&s.shape)[1:] {
			ctx.lineTo(rect_rvec_to_px(p, SHAPE_CREATOR_RECT))
		}

		// complete shape
		corner := rvec2{0, 1}
		ctx.lineTo(rect_rvec_to_px(corner, SHAPE_CREATOR_RECT))
		ctx.lineTo(rect_rvec_to_px(first , SHAPE_CREATOR_RECT))

		ctx.fillStyle(GRAY_4)
		ctx.fill()
		ctx.lineWidth(2)
		ctx.lineJoin(.round)
		ctx.strokeStyle(GRAY_2)
		ctx.stroke()
	}

	// draw shape points
	if hovering_shape_creator || s.dragging != -1 {

		for p, i in sa.slice(&s.shape) {
			ctx.path_circle(rect_rvec_to_px(p, SHAPE_CREATOR_RECT), 6)
			switch i {
			case s.dragging:          ctx.fillStyle(GRAY_0)
			case hovered_shape_point: ctx.fillStyle(GRAY_1)
			case:					  ctx.fillStyle(GRAY_2)
			}
			ctx.fill()
		}
	}

	// draw shape edge hovered midpoint
	if hovered_shape_edge_midpoint != -1 {

		p0 := sa.get(s.shape, hovered_shape_edge_midpoint+0)
		p1 := sa.get(s.shape, hovered_shape_edge_midpoint+1)
		m  := (p0 + p1) / 2
		ctx.path_circle(rect_rvec_to_px(m, SHAPE_CREATOR_RECT), 6)
		ctx.fillStyle(to_rgba(GRAY_2.xyz, 200))
		ctx.fill()
	}


	/*
	DRAW THE 3D SHAPE
	*/

	gl.BindVertexArray(s.vao)

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	// construct positions
	verts_len := get_verts_len(sa.len(s.shape))

	{
		shape_vec3: sa.Small_Array(MAX_SEGMENTS, vec3)
		shape_vec3.len = s.shape.len
		shape := sa.slice(&shape_vec3)
		for p, i in sa.slice(&s.shape) {
			shape[i] = {p.x * 200, (1-p.y-0.5) * 200, 0}
		}

		first    := shape[0]
		second   := shape[1]
		pre_last := shape[len(shape)-2]
		last     := shape[len(shape)-1]

		vi := 0
		
		for di in 0..<DIVISIONS {
			a0 := PI * (f32(di)+0) / DIVISIONS
			a1 := PI * (f32(di)+1) / DIVISIONS

			s.positions[vi+0] = {0, first.y, 0}
			s.positions[vi+1] = vec3_on_radius(second.x, a1, second.y)
			s.positions[vi+2] = vec3_on_radius(second.x, a0, second.y)
			vi += 3

			for si in 1..<len(shape)-2 {
				top := shape[si+0]
				bot := shape[si+1]

				s.positions[vi+0] = vec3_on_radius(bot.x, a1, bot.y)
				s.positions[vi+1] = vec3_on_radius(bot.x, a0, bot.y)
				s.positions[vi+2] = vec3_on_radius(top.x, a0, top.y)
				vi += 3

				s.positions[vi+0] = vec3_on_radius(top.x, a0, top.y)
				s.positions[vi+1] = vec3_on_radius(top.x, a1, top.y)
				s.positions[vi+2] = vec3_on_radius(bot.x, a1, bot.y)
				vi += 3
			}

			s.positions[vi+0] = vec3_on_radius(pre_last.x, a0, pre_last.y)
			s.positions[vi+1] = vec3_on_radius(pre_last.x, a1, pre_last.y)
			s.positions[vi+2] = {0, last.y, 0}
			vi += 3
		}
	}

	normals_from_positions(s.normals[:verts_len], s.positions[:verts_len])

	slice.fill(s.colors [:verts_len], PURPLE)

	attribute(s.a_position, s.buffer_position, s.positions[:verts_len])
	attribute(s.a_normal  , s.buffer_normal  , s.normals  [:verts_len])
	attribute(s.a_color   , s.buffer_color   , s.colors   [:verts_len])

	uniform(s.u_light_color, rgba_to_vec4(ORANGE))


	camera_mat: mat4 = 1
	camera_mat *= mat4_translate({0, 0, 800 - 700 * scale})
	camera_mat = glm.inverse_mat4(camera_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= camera_mat

	uniform(s.u_view, view_mat)

	uniform(s.u_local, 1)

	/* light */
	s.light_angle += 0.001 * delta

	light_pos := vec3{
		500 * -mouse_rel.y,
		300 * cos(s.light_angle),
		300 * sin(s.light_angle),
	}

	/* Draw light from cube */
	light_dir := glm.normalize(light_pos)
	uniform(s.u_light_dir, light_dir)

	gl.DrawArrays(gl.TRIANGLES, 0, verts_len)
}

is_vec_in_rect :: proc (p: vec2, r: ctx.Rect) -> bool
{
	return p.x >= r.x && p.x <= r.x + r.size.x && p.y >= r.y && p.y <= r.y + r.size.y
}

rect_rvec_to_px :: proc (p: rvec2, r: ctx.Rect) -> vec2
{
	return vec2(p) * r.size + r
}

vec_to_rect_rvec :: proc (p: vec2, r: ctx.Rect) -> rvec2
{
	return rvec2((p - r) / r.size)
}

rect_with_margin :: proc (r: ctx.Rect, margin: f32) -> ctx.Rect
{
	return ctx.Rect{r.pos - margin, r.size + margin * 2}
}

rvec_clamp :: proc (v: rvec2) -> rvec2
{
	return rvec2{clamp(v.x, 0, 1), clamp(v.y, 0, 1)}
}
