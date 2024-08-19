shader_type spatial;
render_mode unshaded, cull_disabled, ambient_light_disabled, fog_disabled, shadows_disabled, specular_disabled, depth_draw_never;

// Screen textures
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

uvec3 pack_nfloat_to_uvec3(float input) {
	// Convert the bits of a normalized (0..1) float to 3 uints
	// x & y are most significant bits of mantissa, z is exponent
	// Sign is assumed to be positive (sign bit is 0)
	// Additionally, since float is (0..1), last exponent bit will always be 0
	// according to IEEE754 so we can leave that out as well.
	highp uint b = floatBitsToUint(input);
	lowp uvec3 packed = uvec3(	bitfieldExtract(b, 6, 8),
								bitfieldExtract(b, 14, 8),
								bitfieldExtract(b, 22, 8));
	return packed;
}

// Converts a color from sRGB gamma to linear light gamma
vec3 srgb_to_linear(vec3 sRGB)
{
    bvec3 cutoff = lessThan(sRGB, vec3(0.04045));
    vec3 higher = pow((sRGB + vec3(0.055))/vec3(1.055), vec3(2.4));
    vec3 lower = sRGB/vec3(12.92);

    return mix(higher, lower, cutoff);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);

	highp float d = texture(depth_texture, SCREEN_UV).r;
	lowp uvec3 packed = pack_nfloat_to_uvec3(d);
	// transformed float to color information is theoretically in linear space already,
	// but will be converted to sRGB when rendered to the viewport.
	// in order to keep it linear when rendered we pre-emptively convert it.
	vec3 transformed = srgb_to_linear(vec3(packed) / 255.0);
	ALBEDO = transformed;
	ALPHA = c.a;
}
