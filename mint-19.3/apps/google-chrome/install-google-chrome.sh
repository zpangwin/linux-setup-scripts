#!/bin/bash

if [[ ! -f ../functions.sh ]]; then
	echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
	exit;
fi
. ../functions.sh

echo "";
echo "WARNING: Google adds proprietary code to Chrome that may contain privacy-violating \"features\" such as usage behavior tracking and other telemetry data."
echo "Google Chrome is based on the open-source project Chromium and the two are nearly identical except that Google adds non-open code on top."
echo "";
echo "While on Windows Chromium doesn't provide an auto-update service, on Linux you don't have to worry as you will get updates automatically through your package manager.";
echo "";
echo "If you value your privacy, it is highly recommended to install and use Chromium instead.";
echo "";
read -rsp $'Press enter to continue installing chrome or Ctrl+C to abort ...\n';

# add key
wget -qO - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -;

# add repo
addCustomSource google-chrome "deb http://dl.google.com/linux/chrome/deb/ stable main";

# update apt's local cache
sudo apt-get update 2>&1 >/dev/null;

# install package
sudo apt-get install -y google-chrome-stable;
