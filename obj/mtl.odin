/*
https://paulbourke.net/dataformats/mtl/
*/

package obj

import "base:runtime"
import "core:strings"

Material :: struct {
	name:            string, // newmtl   : Material name
	shininess:       f32,    // Ns       : Specular exponent (ranges 0-1000)
	ambient:         vec3,   // Ka       : Ambient color
	diffuse:         vec3,   // Kd       : Diffuse color
	specular:        vec3,   // Ks       : Specular color
	emissive:        vec3,   // Ke       : Emissive color
	optical_density: f32,    // Ni       : Optical density / Index of refraction
	opacity:         f32,    // d        : Dissolve (1.0 is fully opaque)
	illum:           int,    // illum    : illumination model (0-10)
	map_diffuse:     string, // map_Kd   : Diffuse texture map
	map_specular:    string, // map_Ns   : Specular intensity texture map
	map_normal:      string, // map_Bump : Normal/bump texture map
}

parse_mtl_file :: proc(
	src: string,
	allocator := context.allocator,
) -> (
	materials: []Material,
	err: runtime.Allocator_Error,
) #optional_allocator_error {
	mats := make([dynamic]Material, 0, 4, allocator)
	m: ^Material
	#no_bounds_check {m = &mats[0]}

	it := src
	for line in strings.split_lines_iterator(&it) {
		
		ptr := raw_data(line)
		skip_whitespace(&ptr)
		
		switch ptr[0] {
		case 'n': // newmtl
			if check_keyword(&ptr, "newmtl") {
				skip_whitespace(&ptr)

				mat := Material{
					name = parse_name(&ptr),
					optical_density = 1,
					opacity         = 1,
				}
				append(&mats, mat) or_return
				m = &mats[len(mats)-1]

				skip_whitespace(&ptr)
			}
		
		case 'N': // Ns or Ni
		
			v: ^f32
			switch ptr[1] {
			case 's': v = &m.shininess
			case 'i': v = &m.optical_density
			case: continue
			}
		
			move(&ptr, 2)
			v^ = parse_float(&ptr)
		
		case 'K': // Ka, Kd, Ks, Ke
		
			v: ^vec3
			switch ptr[1] {
			case 'a': v = &m.ambient
			case 'd': v = &m.diffuse
			case 's': v = &m.specular
			case 'e': v = &m.emissive
			case: continue
			}
		
			move(&ptr, 2)
			v^ = parse_vec3(&ptr)
		
		case 'd': // d (dissolve)
			move(&ptr)
			m.opacity = parse_float(&ptr)
		
		case 'i': // illum
			if check_keyword(&ptr, "illum") {
				m.illum = parse_int(&ptr)
			}

		case 'm': // map_Kd, map_Ns, map_Bump
			if string(ptr[:4]) == "map_" {
				move(&ptr, 4)

				v: ^string
				switch {
				case check_keyword(&ptr, "Kd"):   v = &m.map_diffuse
				case check_keyword(&ptr, "Ns"):   v = &m.map_specular
				case check_keyword(&ptr, "Bump"): v = &m.map_normal
				case: continue
				}
				
				skip_whitespace(&ptr)
				v^ = parse_name(&ptr)
			}
		}
	}

	return mats[:], nil
}
