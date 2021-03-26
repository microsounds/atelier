#!/usr/bin/env sh

# installs essential package list
# ask to install optional package groups

# bypass interactive prompts during unit testing
! in-container || env='DEBIAN_FRONTEND=noninteractive'

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
	case "${f%${f#?}}" in
		\#) continue;; # comments
		\*) # package groups with an asterisk are optional, prompt user
			f="${f#?}"
			# don't ask if package group is fully installed
			unset IFS not_inst
			for g in $f; do
				printf '%s\r' "Checking '$g'..."
				dpkg -s "$g" > /dev/null 2>&1 || { not_inst=1; break; }
			done
			[ -z "$not_inst" ] && continue
			printf "%s" "Install optional package(s) $f?: "
			prompt_user || continue;;
	esac
	pkgs="$pkgs $f"
done

echo "$pkgs" | xargs sudo $env apt-get -y install || exit 1
sudo apt-get clean
