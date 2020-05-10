## ~/.profile: executed by the command interpreter for login shells.

## ~/.local file hierarchy
export PATH="$HOME/.local/bin:$PATH"
export C_INCLUDE_PATH="$HOME/.local/include"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"

# redirect wasteful SSD writes to pam_systemd tmpfs or not at all
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/dev/null}"
export XDG_CACHE_HOME="$XDG_RUNTIME_DIR"

## is this a bash session?
[ ! -z "$BASH_VERSION" ] && source "$HOME/.bashrc"

## Xorg server / display manager
# hardware overrides
lspci | egrep -q 'VGA.*Intel' && rc='intel'

# start X on login, logout after X exits
if [ "$(tty)" = '/dev/tty1' ]; then
	[ ! -z "$rc" ] && rc="-- -config $HOME/.config/xorg/$rc.conf"
	exec startx $rc > /dev/null 2>&1
fi
