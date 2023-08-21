#!/usr/bin/env sh

# installs from essential package list described in ~/.comforts
# ask to install optional package groups prepended with *asterisk

# force apt non-interactive mode
env='DEBIAN_FRONTEND=noninteractive'

IFS='
'
unset pkgs
for f in $(sed -e 's/#.*//' -e '/^$/d' < ~/.comforts); do
	case "${f%${f#?}}" in
		\*) # package groups with an asterisk are optional, prompt user
			f="${f#?}"
			# don't ask if package group is fully installed
			is-installed $f > /dev/null ||
				user-confirm "Install optional package(s) $f?" || continue
	esac
	pkgs="$pkgs $f"
done

# force completely unattended install
echo "$pkgs" | xargs sudo $env apt-get -y install || exit 1
sudo apt-get clean
