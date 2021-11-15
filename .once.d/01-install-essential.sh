#!/usr/bin/env sh

# installs from essential package list described in ~/.comforts
# ask to install optional package groups prepended with *asterisk

# force apt non-interactive mode
env='DEBIAN_FRONTEND=noninteractive'

IFS='
'
unset pkgs
for f in $(cat ~/.comforts | sed 's/#.*$//g'); do
	case "${f%${f#?}}" in
		\*) # package groups with an asterisk are optional, prompt user
			f="${f#?}"
			# don't ask if package group is fully installed
			unset IFS not_inst
			for g in $f; do
				printf '%s\r' "Checking '$g'..."
				dpkg -s "$g" > /dev/null 2>&1 || { not_inst=1; break; }
			done
			[ -z "$not_inst" ] && continue
			user-confirm "Install optional package(s) $f?" || continue;;
	esac
	pkgs="$pkgs $f"
done

# force completely unattended install
echo "$pkgs" | xargs sudo $env apt-get -y install || exit 1
sudo apt-get clean
