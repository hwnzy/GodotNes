class_name UTILS

func copy_byte_array_elements(src, src_pos, dest, dest_pos, length):
	for i in range(length):
		dest.set(dest_pos+i, src[src_pos+i])
