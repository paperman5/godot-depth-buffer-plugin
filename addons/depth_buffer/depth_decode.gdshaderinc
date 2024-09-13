float decode_depth(vec4 encoded_depth) {
	// Unpacks 4 8bit uints (encoded as floats) into 1 32bit float.
	// x -> w is MSB -> LSB of 32 bit float
	highp uint bits = uint(0x00000000);
	uvec4 float_bits = uvec4(round(encoded_depth * 255.0));
	bits = (float_bits.x << 24u) | (float_bits.y << 16u) | (float_bits.z << 8u) | (float_bits.w);
	highp float f = uintBitsToFloat(bits);
	return f;
}