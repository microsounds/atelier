[scrot]: https://i.imgur.com/VkmRvWr.png
[miku]: https://i.imgur.com/Nr7HV9a.png
# ![miku] _a t e l i e r_ ![miku]
![scrot]
> _Setup: Debian stable, vanilla Xorg, dwm + dmenu + sxhkd, urxvt + POSIX shell scripts._

# Quick start
* Bootstrap the system by installing `git`.
* `git clone --bare [remote] ~/Git/atelier`
* `git --git-dir=$HOME/Git/atelier --work-tree=$HOME reset --hard`
	* _Restores configuration automatically._
* `cat ~/.packages | xargs apt-get install -y` to install everything else.
* Run `~/.config/dwm/install.sh` to build and install `dwm`.
	* _X starts automatically on `tty1`, you will be kicked if `dwm` isn't installed._
* Log back in to finish.

# Using `git` for managing dotfiles
The git alias _`root`_ treats the home directory as a detached work-tree belonging to bare repo `~/Git/atelier`, effectively turning the home directory into a git repository.
* Tracked files can be edited, versioned, reverted and synchronized in-place.
	* _This negates the need for symlinking, synchronizing copies stored in a seperate repo, etc._
* Untracked files are ignored by default.
	* _This is not helpful behavior when tracking only specific files in the home directory._

# Notes
* See __[~/.packages](.packages)__ for the full list of required packages.
