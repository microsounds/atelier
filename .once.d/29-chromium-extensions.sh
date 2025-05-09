#!/usr/bin/env sh

# automatically install useful extensions from chrome webstore
# using system-wide chrome policy overrides

conf='/etc/chromium/policies/managed/extensions.json'
crx_url='https://clients2.google.com/service/update2/crx'

# create policy directories
sudo mkdir -pv "${conf%/*}"

{
	cat <<- EOF
		{
			"ExtensionInstallForcelist": [
	EOF

	cat <<- EOF | while read -r key _; do
		ddkjiahejlhfcafbddmgiahcphecmpfh # uBlock Origin Lite
		mnjggcdmjocbbbhaepdhchncahnbgone # SponsorBlock for YouTube
		gebbhagfogifgggkldgodflihgfeippi # Return YouTube Dislike
		ckkdlimhmcjmikdlpkmbgfkaikojcbjk # Markdown Viewer
		dbepggeogbaibhgnhhndojpepiihcmeb # Vimium
		jinjaccalgkegednnccohejagnlnfdag # Violentmonkey
		hhinaapppaileiechjoiifaancjggfjm # Web Scrobbler
	EOF
		printf '\t"%s;%s",\n' "$key" "$crx_url"
	done

	cat <<- EOF
			]
		}
	EOF
} | sudo tee "$conf"
