#!/usr/bin/env sh

# repacks plaintext config into terse JSON format
# required by Vimium
final='vimium-options.json'

# append files found in the same directory as this script
cd "${0%/*}"

jsonify() {
	# rewrite tabs and newlines into escapes
	sed -e 's/$/\\n/' -e 's/	/\\t/' | tr -d '\n'
}

jq -M ".keyMappings = \"$(jsonify < keybinds.conf)\" \
	| .userDefinedLinkHintCss = \"$(jsonify < style.css)\"" < general.json \
	> "$final"
echo "Created '$PWD/$final'"

