# ![miku]quick ![miku] start ![miku]
* Create a user with the correct name and install `git`.
* `git clone --bare [remote] ~/Git/atelier`
	* _This is your local copy._
* Make local clone from this repo and copy `.bash_aliases` to home directory.
* `source .bashrc`
* `git-root reset --hard` and log back in.

## On committing and restoring changes
* `git-root` is an alias for working with bare repo `~/Git/atelier` with the work-tree starting at `/`
	* `git-root status` -- Ignore unmonitored files with `-uno`
* All normal git commands _(diff, checkout, etc.)_ should work.
	* `git-root add -u` and push changes back to remote on occasion.
	* _Keep things simple and **DO NOT** stage files that require root file permissions._

## Comforts
```
sudo htop git gcc make xorg wmctrl rxvt-unicode-256color screenfetch ranger
ffmpeg mpv suckless-tools pulseaudio alsa-utils network-manager fonts-liberation
fonts-noto-mono fonts-vlgothic
libx11-dev libxinerama-dev # required by dwm
libdbus-glib-1-2 libgtk-3-0 # required by google-chrome/firefox
```

[miku]: https://i.imgur.com/Nr7HV9a.png
