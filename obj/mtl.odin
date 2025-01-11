/*
https://paulbourke.net/dataformats/mtl/
*/

package obj

import "base:runtime"
import "core:strings"

Material :: struct {
	name:  string, // Material name
	Ns:    f32,    // Specular exponent (ranges 0-1000)
	Ka:    vec3,   // Ambient color
	Kd:    vec3,   // Diffuse color
	Ks:    vec3,   // Specular color
	Ke:    vec3,   // Emissive color
	Ni:    f32,    // Optical density / Index of refraction
	d:     f32,    // Dissolve (1.0 is fully opaque)
	illum: int,    // illumination model (0-10)
}

parse_mtl_file :: proc(
	src: string,
	allocator := context.allocator,
) -> (
	materials: []Material,
	err: runtime.Allocator_Error,
) {
	mats := make([dynamic]Material, 0, 4, allocator)
	m := &mats[0]

	it := src
	for line in strings.split_lines_iterator(&it) {
		
		ptr := raw_data(line)
		skip_whitespace(&ptr)
		
		switch ptr[0] {
		case 'n': // newmtl
			if ptr[1] == 'e' &&
			   ptr[2] == 'w' &&
			   ptr[3] == 'm' &&
			   ptr[4] == 't' &&
			   ptr[5] == 'l' &&
			   is_whitespace(ptr[6]) {
				move(&ptr, 6)

				mat := Material{
					name = parse_name(&ptr),
					Ni   = 1,
					d    = 1,
				}
				append(&mats, mat) or_return
				m = &mats[len(mats)-1]

				skip_whitespace(&ptr)
			}
		
		case 'N': // Ns or Ni
		
			v: ^f32
			switch ptr[1] {
			case 's': v = &m.Ns
			case 'i': v = &m.Ni
			case: continue
			}
		
			move(&ptr, 2)
			v^ = parse_float(&ptr)
		
		case 'K': // Ka, Kd, Ks, Ke
		
			v: ^vec3
			switch ptr[1] {
			case 'a': v = &m.Ka
			case 'd': v = &m.Kd
			case 's': v = &m.Ks
			case 'e': v = &m.Ke
			case: continue
			}
		
			move(&ptr, 2)
			v^ = parse_vec3(&ptr)
		
		case 'd': // d (dissolve)
			move(&ptr)
			m.d = parse_float(&ptr)
		
		case 'i': // illum
			if ptr[1] == 'l' &&
			   ptr[2] == 'l' &&
			   ptr[3] == 'u' &&
			   ptr[4] == 'm' &&
			   is_whitespace(ptr[5]) {
				move(&ptr, 5)
				m.illum = parse_int(&ptr)
			}
		}
	}

	return mats[:], nil
}
