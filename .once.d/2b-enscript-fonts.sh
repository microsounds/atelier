#!/usr/bin/env sh

# cherrypick *.ttf fonts to use in plaintext piped to lpr via GNU enscript

cd /usr/share/enscript/afm
sudo ttf2ufm /usr/share/fonts/fonts-go/Go-Mono.ttf go-mono
sudo mkafmmap *
