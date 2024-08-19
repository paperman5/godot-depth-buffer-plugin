float unpack_uvec3_to_nfloat(uvec3 input) {
	// Unpacks 3 8bit uints into 1 32bit normalized float (0..1)
	// Assumes x & y are MSB of mantissa, z is exponent
	highp uint bits = uint(0x00000000);
	bits = bitfieldInsert(bits, input.x, 6, 8);
	bits = bitfieldInsert(bits, input.y, 14, 8);
	bits = bitfieldInsert(bits, input.z, 22, 8);
	highp float f = uintBitsToFloat(bits);
	return f;
}

float truncate_float(float input) {
	// Remove the least significant 6 bits of the float mantissa
	// Simple 'bitwise and' seems to not work here for some reason
	highp uint float_bits = floatBitsToUint(input);
	highp uint res_bits = uint(0x00000000);
	highp uint trunc_bits = bitfieldExtract(float_bits, 6, 26);
	res_bits = bitfieldInsert(res_bits, trunc_bits, 6, 26);
	highp float res = uintBitsToFloat(res_bits);
	return res;
}

float get_float_tolerance(float input) {
	// Returns the tolerance/EPSILON value for a truncated float as calculated above.
	highp uint float_bits = floatBitsToUint(input);
	highp uint res_bits = uint(0x00000000);
	highp uint trunc_bits = bitfieldExtract(float_bits, 6, 26);
	res_bits = bitfieldInsert(res_bits, uint(0x6), 0, 6);
	res_bits = bitfieldInsert(res_bits, trunc_bits, 6, 26);
	highp float res = uintBitsToFloat(res_bits);
	return res;
}