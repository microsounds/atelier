## ~/.profile: executed by the command interpreter for login shells.

## ~/.local file hierarchy
export PATH="$HOME/.local/bin:$PATH"
export C_INCLUDE_PATH="$HOME/.local/include"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"

# nothing important gets written here, force ramdisk usage
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/dev/null}"
export XDG_CACHE_HOME="$XDG_RUNTIME_DIR"

# is this a bash session?
if [ ! -z "$BASH_VERSION" ]; then
	for f in "$HOME/.bashrc"; do
		[ -f "$f" ] && source "$f"
	done
fi

## Xorg server / display manager
# hardware overrides
lspci | egrep -q 'VGA.*Intel' && rc='intel'

# start X on login, logout after X exits
if [ "$(tty)" = '/dev/tty1' ]; then
	[ ! -z "$rc" ] && rc="-- -config $HOME/.config/xorg/$rc.conf"
	exec startx $rc > /dev/null 2>&1
fi
