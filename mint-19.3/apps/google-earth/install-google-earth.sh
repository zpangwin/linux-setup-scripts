#!/bin/bash
if [[ ! -f ../functions.sh ]]; then
	echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
	exit;
fi
. ../functions.sh

# add key
wget -qO - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -;

# add repo
addCustomSource google-earth "deb [arch=amd64] http://dl.google.com/linux/earth/deb/ stable main";

# update apt's local cache
sudo apt-get update 2>&1 >/dev/null;

# install package
sudo apt-get install -y google-earth-pro-stable;
