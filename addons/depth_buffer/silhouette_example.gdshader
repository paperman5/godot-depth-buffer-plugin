shader_type spatial;
render_mode unshaded, cull_disabled, ambient_light_disabled, fog_disabled, shadows_disabled, specular_disabled, depth_draw_never;

#include "res://addons/depth_buffer/depth_decode.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
// Use `hint_normal` to read as linear data instead of sRGB data
uniform sampler2D silhouette_layer_depth : hint_normal, repeat_disable, filter_nearest;
uniform sampler2D obstruction_layer_depth : hint_normal, repeat_disable, filter_nearest;

uniform vec4 silhouette_color = vec4(0.1, 0.1, 0.1, 0.9);

const float EPS = 1.0E-6;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 silhouette_depth = texture(silhouette_layer_depth, SCREEN_UV);
	vec4 obstruction_depth = texture(obstruction_layer_depth, SCREEN_UV);

	float f1 = decode_depth(silhouette_depth);
	float f2 = decode_depth(obstruction_depth);
	ALBEDO = (depth - f1 > EPS && f1 - f2 > EPS && depth > 0.0) ? mix(c.rgb, silhouette_color.rgb, silhouette_color.a) : c.rgb;
}
