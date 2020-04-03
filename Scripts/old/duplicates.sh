#!/usr/bin/env sh

# generate a list of all identical files for manual review

trap cleanup 1 2 3 6

dir="$(mktemp -q -d)"
list="$(mktemp -q -p $dir)"
sums="$(mktemp -q -p $dir)"

printf "Indexing files...\r"
find . > "$list"

cleanup() { rm -rf "$dir"; exit 0; }
wipe() { for _ in $(seq $(tput cols)); do printf " "; done } # clear

count=$(cat "$list" | wc -l)
i=1
cat "$list" | while read -r file; do
	# progress
	if [ $((i % (count / 100))) -eq 0 ]; then
		pct=$(((i * 100) / count))
		wipe; printf "\rProgress: %d / %d (%d%%) %s %s\r" $i $count $pct "$file"
	fi
	# checksum
	sha1sum "$file" 2> /dev/null >> "$sums"
	i=$((i + 1))
done
results="duplicates-$(date +%s).txt"
bytes=$(sed -n 1p "$sums" | cut -d ' ' -f1 | wc -m)

cat "$sums" | sort | uniq -w $bytes --all-repeated=separate > "$results"
if [ ! -s "$results" ]; then
	wipe; echo "\rNo duplicate files were found."
	rm "$results"
else
	wipe; echo "\rList of duplicate files saved to '$results'."
fi
cleanup
