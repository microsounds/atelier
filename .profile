## ~/.profile: executed by the command interpreter for login shells.

# editor
export EDITOR='nano -R'

## ~/.local file hierarchy
# append shell libraries, normal executables
export PATH="$HOME/.local/lib:$HOME/.local/bin:$PATH"
export C_INCLUDE_PATH="$HOME/.local/include"
export LD_LIBRARY_PATH="$HOME/.local/lib"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"

# force cache writes to ramdisk
# fallback to /tmp if pam_systemd doesn't provide ramdisk
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
export XDG_CACHE_HOME="$XDG_RUNTIME_DIR"

# persist for current session only, return 0 on logout
trap 'ssh-agent -k > /dev/null || :' 0 1 3 6 15

## login shell
# start ssh-agent as daemon
eval "$(ssh-agent -st 3600)" > /dev/null

# start X server if tty1
case $(tty) in
	*tty1) exec startx;;
	*) case "$0" in *bash) . "$HOME/.bashrc";; esac
esac
