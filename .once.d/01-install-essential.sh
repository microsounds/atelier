#!/usr/bin/env sh

# installs essential packages
# ask to install optional packages

echo "$0"
prompt_user() {
	while read -r res; do
		case "$(echo "$res" | tr 'A-Z' 'a-z')" in
			y | yes) return 0;;
			n | no) return 1;;
		esac
		printf "%s" "Please confirm (y/n): "
	done
}

IFS='
'
unset pkgs
for f in $(cat ~/.comforts); do
	# package groups with an asterisk are optional, prompt user
	if [ "${f%${f#?}}" = '*' ]; then
		f="${f#?}"
		# don't ask if package is already installed
		dpkg -s "${f% *}" > /dev/null 2>&1 && continue
		printf "%s" "Install optional package(s) $f?: "
		prompt_user || continue
	fi
	pkgs="$pkgs $f"
done

echo "$pkgs" | xargs sudo apt-get -y install
sudo apt-get clean
