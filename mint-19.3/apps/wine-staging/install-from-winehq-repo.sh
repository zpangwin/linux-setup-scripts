#!/bin/bash

if [[ ! -f ../functions.sh ]]; then
	echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
	exit;
fi
. ../functions.sh

#LIBFAUDIO fix
# The OBS Repo contains FAudio (e.g. libfaudio0:i386) among other things
# FAudio is a dependency for the wine-staging build (but not for wine-stable)
#   https://forum.winehq.org/viewtopic.php?f=8&t=32545
#   https://forum.winehq.org/viewtopic.php?f=8&t=32192
#
#   The FAudio packages are not distributed from dl.winehq.org because FAudio is not part
#   of the Wine Project, and [their] building them is only a temporary workaround until
#   distros start providing FAudio packages. FYI, Fedora 29 and later and Debian Sid
#   have already added FAudio packages to their repositories.
#
LIBFAUDIO_REPO="https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04";
isfAudioInOfficialSources=$(apt search "libfaudio0:i386" | wc -l);

# 32-bit support
sudo dpkg --add-architecture i386

# add key for winehq
echo "Adding signing key for wine ... ";
wget -qO - https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -;

# add key for libfaudio
if [[ "0" == "$isfAudioInOfficialSources" ]]; then
	echo "Adding signing key for OBS repo (which contains faudio) ... ";
	wget -qO - "${LIBFAUDIO_REPO}/Release.key" | sudo apt-key add -;
fi

# add repo source for winehq
echo "Adding Wine PPA source ... ";
addCustomSource winehq 'deb http://dl.winehq.org/wine-builds/ubuntu/ bionic main';

# add repo source for libfaudio
if [[ "0" == "$isfAudioInOfficialSources" ]]; then
	echo "Adding OBS PPA source (for faudio) ... ";
	addCustomSource libfaudio "deb ${LIBFAUDIO_REPO}/ ./";
fi

# update apt's local cache
echo "Updating apt's local cache; this may take a few minutes ... ";
sudo apt-get update 2>/dev/null >/dev/null;

if [[ "0" == "$isfAudioInOfficialSources" ]]; then
	# fix libfaudio issue (still needed in Mint 19.x)
	# if unsure, try running 'sudp apt-get install --install-recommends winehq-staging'
	# if it works, this is not needed.
	# otherwise, if you get errors about wine-staging and held broken packages use this:
	echo "Attempting to resolve any potential conflicts (warnings can be ignored) ... ";
	sudo dpkg --force-remove-reinstreq --force-remove-essential --purge wine-staging wine-staging-i386 wine-staging-i386:i386 libfaudio:i386 libfaudio0:i386 winehq-staging wine-staging-amd64;

	echo "Installing libfaudio0 dependency ... ";
	sudo apt-get install --install-recommends -y libfaudio0:i386;
else
	sudo apt-get install --install-recommends -y libfaudio0;
fi

# install wine-staging
echo "Installing winehq-staging ... ";
sudo apt-get install --install-recommends -y fonts-wine libwine winehq-staging;

# purge any old winetricks from official repo and install latest from github
# if you weren't aware, even winetricks in repo is actually just a shell script :-)
echo "Installing winetricks from source ... ";
sudo apt-get -y purge winetricks 2>/dev/null;
wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks;
sudo chown root:root winetricks;
sudo mv -t /usr/bin winetricks;
sudo chmod a+rx /usr/bin/winetricks;
