#+private file
package example

import glm "core:math/linalg/glsl"
import gl  "../wasm/webgl"
import     "../obj"

@private
State_Windmill :: struct {
	rotation:  mat4,
	shapes:    []Shape,
}

Shape :: struct {
	using uniforms: Uniform_Values_Chair,
	locations:      Input_Locations_Chair,
	vao:            VAO,
	vertices:       Vertices,
	material:       obj.Material,
}

chair_obj_src := #load("./public/windmill.obj", string)
chair_mtl_src := #load("./public/windmill.mtl", string)

@private
setup_windmill :: proc(s: ^State_Windmill, program: gl.Program) {
	
	gl.Enable(gl.CULL_FACE)  // don't draw back faces
	gl.Enable(gl.DEPTH_TEST) // draw only closest faces

	obj_data, obj_parse_err := obj.parse_file(chair_obj_src, context.temp_allocator)
	if obj_parse_err != nil {
		fmt.eprintf("Obj parse error: %v", obj_parse_err)
	}

	materials, mtl_parse_err := obj.parse_mtl_file(chair_mtl_src)
	if obj_parse_err != nil {
		fmt.eprintf("Mtl parse error: %v", mtl_parse_err)
	}

	extent_min, extent_max := get_extents(obj_data.positions[:])

	s.shapes = make([]Shape, len(obj_data.objects))

	for &shape, i in s.shapes {
		o := obj_data.objects[i]

		shape.vao = gl.CreateVertexArray()

		shape.vertices = convert_obj_vertices(o.vertices[:])

		correct_extents(shape.vertices.position[:len(shape.vertices)], extent_min, extent_max, -200, 200)

		for m in materials {
			if m.name == o.material {
				shape.material = m
				break
			}
		}

		gl.BindVertexArray(shape.vao)
	
		input_locations_chair(&shape.locations, program)
	
		attribute(shape.locations.a_position, gl.CreateBuffer(), shape.vertices.position[:len(shape.vertices)])
		attribute(shape.locations.a_color,    gl.CreateBuffer(), shape.vertices.color[:len(shape.vertices)])
		attribute(shape.locations.a_normal,   gl.CreateBuffer(), shape.vertices.normal[:len(shape.vertices)])
	}

	/* Init rotation */
	s.rotation = 1
}

@private
frame_windmill :: proc(s: ^State_Windmill, delta: f32) {

	gl.Viewport(0, 0, canvas_res.x, canvas_res.y)
	gl.ClearColor(0, 0, 0, 0)
	// Clear the canvas AND the depth buffer.
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	rotation := -0.01 * delta * mouse_rel.yx
	s.rotation = mat4_rotate_x(rotation.x) * mat4_rotate_y(rotation.y) * s.rotation

	eye_pos := vec3{0, 0, 500 - 500 * (scale-0.5)}

	eye_mat := mat4(1)
	eye_mat *= mat4_translate(eye_pos)
	eye_mat  = glm.inverse_mat4(eye_mat)

	view_mat := glm.mat4PerspectiveInfinite(
		fovy   = radians(80),
		aspect = aspect_ratio,
		near   = 1,
	)
	view_mat *= eye_mat

	local_mat: mat4 = 1
	local_mat *= s.rotation
	
	for &shape in s.shapes {

		shape.u_local        = local_mat
		shape.u_view         = view_mat
		shape.u_eye_position = eye_pos
		shape.u_light_dir    = normalize(vec3{-1, 3, 5})

		shape.u_diffuse      = shape.material.diffuse
		shape.u_ambient      = shape.material.ambient
		shape.u_emissive     = shape.material.emissive
		shape.u_specular     = shape.material.specular
		shape.u_shininess    = shape.material.shininess
		shape.u_opacity      = shape.material.opacity

		gl.BindVertexArray(shape.vao)

		uniforms_chair(shape.locations, shape)
		
		gl.DrawArrays(gl.TRIANGLES, 0, len(shape.vertices))
	}
}
