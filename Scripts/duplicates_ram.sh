#!/usr/bin/env sh

# generate a list of all identical files for manual review

trap cleanup 1 2 3 6

dir="$(mktemp -q -d)"
list="$(mktemp -q -p $dir)"
sums="$(mktemp -q -p $dir)"
find . > "$list"

cleanup() { rm -rf "$dir"; exit 0; }

count=$(cat "$list" | wc -l)
i=1
cat "$list" | while read -r file; do
	# progress
	pct=$(echo "scale=2; ($i / $count) * 100" | bc | cut -d '.' -f1)
	for _ in $(seq $(tput cols)); do printf " "; done # clear
	printf "\rProgress: %d / %d (%d%%) %s\r" $i $count $pct "$file"
	# checksum
	hash="$(sha1sum "$file" 2> /dev/null)"
	if [ ! -z "$hash" ]; then mem="$mem\n$hash"; fi # dump to memory
	if [ $i -eq $count ]; then echo "$mem" > "$sums"; fi # dump to file
	i=$((i + 1))
done

results="duplicates-$(date +%s).txt"
bytes=$(cat "$sums" | sed -n 1p | cut -d ' ' -f1 | wc -m)
cat "$sums" | sort | uniq -w $bytes --all-repeated=separate > "$results"
echo "List of duplicate files saved to '$results'."
cleanup
