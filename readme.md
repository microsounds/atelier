[scrot]: https://i.imgur.com/VkmRvWr.png
[miku]: https://i.imgur.com/Nr7HV9a.png
# ![miku] _a t e l i e r_ ![miku]
![scrot]
> _Setup: Debian stable, vanilla Xorg, dwm + dmenu + sxhkd, urxvt + POSIX shell scripts._

# Quick start
* Install `sudo`, add yourself to the `sudo` group and install `git`.
* `git clone --bare [remote] ~/Git/atelier`
* `git --git-dir=$HOME/Git/atelier --work-tree=$HOME reset --hard`
	* _Restores configuration automatically, run `exec bash` to reload the environment._
* `cat ~/.pkgs | xargs apt-get install -y` to install essential packages.
* Run scripts in `~/.once.d` to build and install `dwm`, among other things.
	* _`for f in ~/.once.d/*; do $f; done`_
* `xinit` starts automatically upon login to `tty1`, you will be kicked if `dwm` isn't installed.

# Using `git` for managing dotfiles
The git alias _`root`_ treats the home directory as a detached work-tree belonging to bare repo `~/Git/atelier`, effectively turning `$HOME` into a git repository.
* Tracked files can be edited, versioned, reverted and synchronized in-place.
	* _This negates the need for symlinking, synchronizing copies stored in a seperate repo, etc._
* Untracked files are ignored by default.
	* _This is unwanted behavior when tracking only specific files in the home directory._

# Notes
* **Every effort is made to maintain a nominally reproducible GNU/Linux setup.**
*  Use of local, user-specific dotfiles that don't touch system defaults are preferred.
	* _Dotfiles in `$HOME` supersede any defaults stored in `/etc`, `/usr/share`, etc._
* System-wide changes that bypass the package manager are avoided when possible.
	* _Necessary system-wide changes are reproduced with `~/.once.d` scripts._
* See __[~/.pkgs](.pkgs)__ for the full list of essential packages.
