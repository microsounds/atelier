#!/usr/bin/env sh

# optimize all images in directory
# arrays are space-delimited

array() { echo "$1" | tr ' ' '\n' | sed -n "${2}p"; }

query="jpe?g png"
prog="jpegoptim optipng"

for file in *; do
	for i in $(seq 2); do
		if file "$file" | grep -E -i $(array "$query" $i) > /dev/null; then
			$(array "$prog" $i) "$file"
		fi
	done
done
