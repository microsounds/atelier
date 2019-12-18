[miku]: https://i.imgur.com/Nr7HV9a.png
# ![miku] quick ![miku] start ![miku]
* Install `git`, `gcc` and `make` at the bare minimum.
	* _`apt-get install $(tail -4 readme.md)`_
* `git clone --bare [remote] ~/Git/atelier`
* `git --git-dir=$HOME/Git/atelier --work-tree=$HOME checkout .gitconfig`
* `git root reset --hard` to restore configuration automatically.
* Run `~/.config/dwm/install.sh` to automatically build and install `dwm`.
* Install everything else, then `source .bashrc` to finish.
	* _You will be kicked from `tty1` if X exits with a non-zero exit code._

# Notes
* `git root` is an alias for working with bare repo `~/Git/atelier` with your home directory as the work-tree.
* Absolute filenames can be tracked if the work-tree is set to filesystem root.
	* Do _**NOT**_ track files that require root permissions unless you want to be root for every checkout and pull.

### Comforts
sudo htop git gcc make xorg wmctrl xclip xbacklight sxhkd acpi rxvt-unicode-256color
screenfetch feh ffmpeg mpv suckless-tools pulseaudio alsa-utils network-manager sshfs
fonts-liberation fonts-dejima-mincho fonts-noto-mono fonts-vlgothic
libx11-dev libxft-dev libxinerama-dev libdbus-glib-1-2 libgtk-3-0
