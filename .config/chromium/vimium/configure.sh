#!/usr/bin/env sh

# stuffs plaintext config into terse JSON format
final='vimium-options.json'

jsonify() {
	# rewrite tabs and newlines into escapes
	sed -e 's/$/\\n/' -e 's/	/\\t/' | tr -d '\n'
}

cat settings.json \
	| jq -M ". += { \"keyMappings\": \"$(jsonify < keybinds.conf)\" }" \
	| jq -M ". += { \"userDefinedLinkHintCss\": \"$(jsonify < style.css)\" }" \
	> "$final"

echo "Generated '$final'"
