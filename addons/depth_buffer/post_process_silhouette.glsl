#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform restrict image2D color_image;
layout(set = 0, binding = 1) uniform sampler2D depth_image;
layout(set = 0, binding = 2) uniform sampler2D silhouette_depth_encoded;
layout(set = 0, binding = 3) uniform sampler2D obstruction_depth_encoded;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 reserved;
	vec4 silhouette_color;
} params;

const float EPS = 1.0E-6;

// Converts a color from sRGB gamma to linear light gamma
vec3 srgb_to_linear(vec3 sRGB)
{
	bvec3 cutoff = lessThan(sRGB, vec3(0.04045));
	vec3 higher = pow((sRGB + vec3(0.055))/vec3(1.055), vec3(2.4));
	vec3 lower = sRGB/vec3(12.92);

	return mix(higher, lower, cutoff);
}

float decode_depth(vec4 encoded_depth) {
	// Unpacks 4 8bit uints (encoded as floats) into 1 32bit float.
	// x -> w is MSB -> LSB of 32 bit float
	uint bits = uint(0x00000000);
	uvec4 float_bits = uvec4(round(encoded_depth * 255.0));
	bits = (float_bits.x << 24u) | (float_bits.y << 16u) | (float_bits.z << 8u) | (float_bits.w);
	float f = uintBitsToFloat(bits);
	return f;
}

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);

	// Prevent reading/writing out of bounds.
	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	// Read from the color/depth buffers.
	vec4 c = imageLoad(color_image, uv);
	float depth = texelFetch(depth_image, uv, 0).r;
	float depth_silhouette = decode_depth(texelFetch(silhouette_depth_encoded, uv, 0));
	float depth_obstruction = decode_depth(texelFetch(obstruction_depth_encoded, uv, 0));

	bool do_silhouette = depth - depth_silhouette > EPS && depth_silhouette - depth_obstruction > EPS && depth > 0.0;
	vec4 final_color = do_silhouette ? vec4(mix(c.rgb, srgb_to_linear(params.silhouette_color.rgb), params.silhouette_color.a), c.a) : c;

	imageStore(color_image, uv, final_color);
}
