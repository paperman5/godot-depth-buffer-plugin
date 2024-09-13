shader_type spatial;
render_mode unshaded, cull_disabled, ambient_light_disabled, fog_disabled, shadows_disabled, specular_disabled, depth_draw_never;

uniform sampler2D depth_encoded : hint_normal, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform bool display_encoded_depth = false;
uniform bool display_real_depth = false;
uniform bool display_decoded_depth = false;
uniform bool display_depth_diff = false;

#include "res://addons/depth_buffer/depth_decode.gdshaderinc"

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec4 c = texture(depth_encoded, SCREEN_UV);
	vec4 c2 = texture(screen_texture, SCREEN_UV);
	float depth_real = texture(depth_texture, SCREEN_UV).r;
	float depth_decoded = decode_depth(c);

	if (display_encoded_depth) {
		ALBEDO = c.rgb;
		ALPHA = c.a;
	}
	else if (display_real_depth) {
		ALBEDO = vec3(depth_real);
		ALPHA = 1.0;
	}
	else if (display_decoded_depth) {
		ALBEDO = vec3(depth_decoded);
		ALPHA = 1.0;
	}
	else if (display_depth_diff) {
		ALBEDO = vec3(abs(depth_decoded - depth_real) * 500.0);
		ALPHA = 1.0;
	}
	else {
		ALBEDO = c2.rgb;
	}
}
