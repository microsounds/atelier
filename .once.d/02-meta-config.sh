#!/usr/bin/env sh

# git meta upstream configuration
upstream='github.com/microsounds/atelier'
ssh='ssh://git@'
https='https://'

# set to push only through ssh
git meta remote remove origin
git meta remote add origin "$https$upstream"
git meta remote set-url origin --push "$ssh$upstream"
git meta fetch || exit 1
git meta branch -u origin/master

# set to ignore all untracked files in $HOME when calling git status
git meta config status.showUntrackedFiles no
