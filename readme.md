[scrot]: https://i.imgur.com/VkmRvWr.png
[miku]: https://i.imgur.com/Nr7HV9a.png
# ![miku] _a t e l i e r quick start_ ![miku]
![scrot]
> _Setup: Debian stable, vanilla Xorg, dwm + dmenu + sxhkd, urxvt + POSIX shell scripts._
* Install `git`, `gcc` and `make` at the bare minimum.
	* _Hint: `apt-get install $(tail -5 readme.md)`_
* `git clone --bare [remote] ~/Git/atelier`
* `git --git-dir=$HOME/Git/atelier --work-tree=$HOME checkout .gitconfig`
* `git root reset --hard` to restore configuration automatically.
* Run `~/.config/dwm/install.sh` to automatically build and install `dwm`.
* Install everything else, then `source .bashrc` to finish.
	* _You will be kicked from `tty1` if X exits with a non-zero exit code._

# Notes
* `git root` is an alias for working with bare repo `~/Git/atelier` with the work-tree set to the home directory.
	* Absolute filenames can be tracked if the work-tree is set to filesystem root.
	* Do _**NOT**_ track files that require root permissions unless you want to be root for every checkout and pull.

# Comforts
sudo htop git gcc make m4 xorg wmctrl xclip xbacklight xdiskusage sxhkd acpi rxvt-unicode-256color
nnn screenfetch mpv suckless-tools bluez pulseaudio pulseaudio-module-bluetooth alsa-utils
network-manager sshfs pmount feh ffmpeg curl progress qrencode
fonts-liberation fonts-dejima-mincho fonts-noto-mono fonts-vlgothic
libx11-dev libxft-dev libxinerama-dev libgtk-3-0
