# ![miku]quick ![miku] start ![miku]
* Create a user with the correct name and install `git`.
* `git clone --bare [remote] ~/Git/atelier`
	* _This is your local copy._
* `git --work-tree=/ --git-dir=Git/atelier checkout .bash_aliases`
* `source .bashrc`
* `git-root reset --hard`
	* _Do not log out, you will be kicked from `tty1`._
* Initialize `~/.config/dwm`, pull from `https://git.suckless.org/dwm` and then `make install`.

## On committing and restoring changes
* `git-root` is an alias for working with bare repo `~/Git/atelier` with the work-tree starting at `/`
	* `git-root status` -- Ignore unmonitored files with `-uno`
* All normal git commands _(diff, checkout, etc.)_ should work.
	* `git-root add -u` and push changes back to remote on occasion.
	* _Keep things simple and **DO NOT** stage files that require root file permissions._

### Tools
```
sudo htop git gcc make xorg wmctrl acpi rxvt-unicode-256color screenfetch feh
ffmpeg mpv suckless-tools pulseaudio alsa-utils network-manager sshfs
```
### Fonts
```
fonts-liberation fonts-dejima-mincho # dwm
fonts-noto-mono fonts-vlgothic # term
```
### Libs
``` 
libx11-dev libxft-dev libxinerama-dev # dwm
libdbus-glib-1-2 libgtk-3-0 # firefox
```

[miku]: https://i.imgur.com/Nr7HV9a.png
