#!/usr/bin/env sh

# automatically install useful extensions from chrome webstore
# using system-wide google chrome enterprise policy overrides

conf='/etc/chromium/policies/managed/extensions.json'
crx_url='https://clients2.google.com/service/update2/crx'

# create policy directories
sudo mkdir -pv "${conf%/*}"

cat << EOF | sudo tee "$conf"
{
	"ExtensionInstallForcelist": [
EOF

cat <<- EOF | while read -r key _; do
	cjpalhdlnbpafiamejdnhcphjbkeiagm # ublock origin
	ckkdlimhmcjmikdlpkmbgfkaikojcbjk # markdown viewer
	jfpdlihdedhlmhlbgooailmfhahieoem # disable javascript
EOF
	printf '\t\t"%s;%s",\n' "$key" "$crx_url" | sudo tee -a "$conf"
done

cat << EOF | sudo tee -a "$conf"
	]
}
EOF
