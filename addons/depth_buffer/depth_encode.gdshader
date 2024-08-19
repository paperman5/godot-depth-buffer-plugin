shader_type spatial;
render_mode unshaded, cull_disabled, ambient_light_disabled, fog_disabled, shadows_disabled, specular_disabled, depth_draw_never;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	ALBEDO = vec3(1.0, 0.0, 1.0);
}
