#!/usr/bin/env sh

# installs essential packages

echo "$0"
xargs sudo apt-get -y install < ~/.comforts

# hold chromium until further notice
sudo apt-mark hold chromium chromium-common chromium-sandbox
