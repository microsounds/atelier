# ![miku]quick ![miku] start ![miku]
* Create a user with the correct name and install `git`.
* `git --clone --bare [remote] ~/Git/atelier`
* `cp ~/Git/atelier/home/microsounds/.bash_aliases ~`
* `source .bashrc`
* `git-root reset --hard`
## On commiting changes
* `git-root` is an alias for working with bare repo `~/Git/atelier` with the work-tree starting at `/`
	* `git-root status` -- Ignore unmonitored files with `-u no`
* Push changes back to remote on occasion.

[miku]: https://i.imgur.com/Nr7HV9a.png
