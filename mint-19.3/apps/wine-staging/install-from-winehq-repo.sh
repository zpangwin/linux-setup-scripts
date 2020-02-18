#!/bin/bash

if [ -f ../functions.sh ]; then
    . ../functions.sh
else
	echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
	exit;
fi

#LIBFAUDIO fix
LIBFAUDIO_REPO="https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04";

# 32-bit support
sudo dpkg --add-architecture i386

# add key for winehq
wget -qO - https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -;

# add key for libfaudio
wget -qO - "${LIBFAUDIO_REPO}/Release.key" | sudo apt-key add -;

# add repo source for winehq
addCustomSource winehq 'deb http://dl.winehq.org/wine-builds/ubuntu/ bionic main';

# add repo source for libfaudio
addCustomSource libfaudio "deb ${LIBFAUDIO_REPO}/ ./";

# update local apt cache
sudo apt update;

# fix libfaudio issue (still needed in Mint 19.x)
# if unsure, try running 'sudp apt install --install-recommends winehq-staging'
# if it works, this is not needed.
# otherwise, if you get errors about wine-staging and held broken packages use this:
sudo dpkg --force-remove-reinstreq --force-remove-essential --purge wine-staging wine-staging-i386 wine-staging-i386:i386 libfaudio:i386 libfaudio0:i386 winehq-staging wine-staging-amd64;
sudo apt install --install-recommends -y libfaudio0:i386;

# install wine-staging
sudo apt install --install-recommends -y fonts-wine libwine winehq-staging;

# purge any old winetricks from official repo and install latest from github
# if you weren't aware, even winetricks in repo is actually just a shell script :-)
sudo apt-get -y purge winetricks 2>/dev/null;
wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks;
sudo chown root:root winetricks;
sudo mv -t /usr/bin winetricks;
sudo chmod a+rx /usr/bin/winetricks;
