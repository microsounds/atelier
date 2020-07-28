## ~/.profile: executed by the command interpreter for login shells.

# editor
export EDITOR='nano'

## ~/.local file hierarchy
export PATH="$HOME/.local/bin:$PATH"
export C_INCLUDE_PATH="$HOME/.local/include"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"

# redirect cache writes to pam_systemd's tmpfs or not at all
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/dev/null}"
export XDG_CACHE_HOME="$XDG_RUNTIME_DIR"

## login shell
# start X server if tty1
case $(tty) in
	*tty1) exec startx > /dev/null 2>&1;;
	*) case $0 in *bash) . "$HOME/.bashrc";; esac
esac
