#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

if [[ ! -f "${SCRIPT_DIR_PARENT}/functions.sh" ]]; then
    echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
    exit;
fi
. "${SCRIPT_DIR_PARENT}/functions.sh";

# 32-bit support
echo "Adding support for running 32-bit programs on 64-bit OS ... ";
sudo dpkg --add-architecture i386

# add key for winehq
echo "Adding signing key for wine ... ";
wget -qO - https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -;

# add repo source for winehq
echo "Adding Wine PPA source ... ";
addCustomSource winehq 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main';

# update apt's local cache
echo "Updating apt's local cache; this may take a few minutes ... ";
sudo apt-get update 2>/dev/null >/dev/null;

# install wine-staging
echo "Installing winehq-staging ... ";
sudo apt-get install --install-recommends -y libfaudio0 fonts-wine libwine winehq-staging;

# purge any old winetricks from official repo and install latest from github
# if you weren't aware, even winetricks in repo is actually just a shell script :-)
echo "Installing winetricks from source ... ";
sudo apt-get -y purge winetricks 2>/dev/null;
wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks;
sudo chown root:root winetricks;
sudo mv -t /usr/bin winetricks;
sudo chmod a+rx /usr/bin/winetricks;
