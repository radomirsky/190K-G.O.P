shader_type spatial;

uniform vec4 color_dark : source_color = vec4(0.14, 0.14, 0.16, 1.0);
uniform vec4 color_light : source_color = vec4(0.86, 0.86, 0.9, 1.0);
uniform float cell_size : hint_range(0.5, 32.0) = 4.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.92;

varying vec3 world_vertex;

void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 xz = world_vertex.xz / cell_size;
	float c = mod(floor(xz.x) + floor(xz.y), 2.0);
	ALBEDO = mix(color_light.rgb, color_dark.rgb, c);
	ROUGHNESS = roughness;
	METALLIC = 0.0;
}
