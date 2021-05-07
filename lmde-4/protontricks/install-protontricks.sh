#!/bin/bash

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

# check for chroot environment
if [[ "root" == "${USER}" && "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]; then
	# make sure folder exists
	mkdir ~/.local/bin 2>&1 >/dev/null;
fi

echo "Installing dependencies ...";
sudo apt-get install -y git python3 python3-pip python3-setuptools python3-venv;
python3 -m pip install pipx;

echo "Installing protontricks ...";
~/.local/bin/pipx ensurepath;
pipx install protontricks;

