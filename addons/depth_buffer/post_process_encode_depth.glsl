#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform restrict writeonly image2D color_image;
layout(set = 0, binding = 1) uniform sampler2D depth_image;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 reserved;
} params;

// Converts a color from sRGB gamma to linear light gamma
vec3 srgb_to_linear(vec3 sRGB)
{
	bvec3 cutoff = lessThan(sRGB, vec3(0.04045));
	vec3 higher = pow((sRGB + vec3(0.055))/vec3(1.055), vec3(2.4));
	vec3 lower = sRGB/vec3(12.92);

	return mix(higher, lower, cutoff);
}

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);

	// Prevent reading/writing out of bounds.
	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	// Read from the depth buffer.
	float depth = texelFetch(depth_image, uv, 0).r;

	// Encode 32bit float to 4 float-encoded 8bit uints.
	uint float_bits = floatBitsToUint(depth);
	vec4 encoded_depth = vec4(0.0);
	encoded_depth.r = float((float_bits & 0xFF000000) >> 24) / 255.0;
	encoded_depth.g = float((float_bits & 0x00FF0000) >> 16) / 255.0;
	encoded_depth.b = float((float_bits & 0x0000FF00) >>  8) / 255.0;
	encoded_depth.a = float(float_bits & 0x000000FF) / 255.0;

	// transformed float to color information is theoretically in linear space already,
	// but will be converted to sRGB when rendered to the viewport (when viewport is not HDR).
	// in order to keep it linear when rendered we pre-emptively convert it.
	encoded_depth.rgb = srgb_to_linear(encoded_depth.rgb);

	// Write encoded depth to the color buffer.
	imageStore(color_image, uv, encoded_depth);
}
