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

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

# Detemine Debian info
DEBIAN_VERSION="$(cat /etc/debian_version)";
if [[ $DEBIAN_VERSION =~ ^[A-Za-z].*$ ]]; then
	DEBIAN_CODENAME="$(echo "${DEBIAN_VERSION}"|sed -E 's/^(\w+)\W.*$/\1/g'|tr '[:upper:]' '[:lower:]')";
	case "${DEBIAN_CODENAME}" in
		buster) DEBIAN_VERSION='10.x' ;;
		bullseye) DEBIAN_VERSION='11.x' ;;
		bookworm) DEBIAN_VERSION='12.x' ;;
		*) DEBIAN_VERSION=UNKNOWN ;;
	esac
	if [[ $DEBIAN_CODENAME =~ ^.*sid.*$ ]]; then
		DEBIAN_CODENAME="$DEBIAN_CODENAME (sid = still in development; aka unstable)";
	fi
else
	# ${DEBIAN_VERSION%%.*} - outputs only the number to the left of the decimal (e.g. the major version)
	case "${DEBIAN_VERSION%%.*}" in
		10) DEBIAN_CODENAME='buster' ;;
		11) DEBIAN_CODENAME='bullseye' ;;
		12) DEBIAN_CODENAME='bookworm' ;;
		*) DEBIAN_CODENAME=UNKNOWN ;;
	esac
fi

if [[ 'buster' != "${DEBIAN_CODENAME}" && 'bullseye' != "${DEBIAN_CODENAME}" ]]; then
	# 2020-11-04 WineHQ currently only supports buster and bullseye
	# See:
	#	https://wiki.winehq.org/Debian
	echo "Debian '${DEBIAN_CODENAME}' is either not supported by winehq or requires script updates."
	exit;
fi

# 32-bit support
echo "Adding support for running 32-bit programs on 64-bit OS ... ";
sudo dpkg --add-architecture i386

# libfaudio0 should be present in the debian bullseye (11) repos but is not present in debian buster (10) repos
# or in the lmde4 repos which are based on buster.
#
if [[ 'buster' == "${DEBIAN_CODENAME}" ]]; then
	#LIBFAUDIO fix
	# The OBS Repo contains FAudio (e.g. libfaudio0:i386) among other things
	# FAudio is a dependency for the wine-staging build (but not for wine-stable)
	#	https://www.linuxuprising.com/2019/09/how-to-install-wine-staging-development.html
	#   https://forum.winehq.org/viewtopic.php?f=8&t=32545
	#   https://forum.winehq.org/viewtopic.php?f=8&t=32192
	#
	#   The FAudio packages are not distributed from dl.winehq.org because FAudio is not part
	#   of the Wine Project, and [their] building them is only a temporary workaround until
	#   distros start providing FAudio packages. FYI, Fedora 29 and later and Debian Sid
	#   have already added FAudio packages to their repositories.
	#
	LIBFAUDIO_REPO="https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10";
	isfAudioInOfficialSources=$(apt search "libfaudio0:i386" | wc -l);

	if [[ "0" == "$isfAudioInOfficialSources" ]]; then
		# add key for libfaudio
		echo "Adding signing key for OBS repo (which contains faudio) ... ";
		wget -qO - "${LIBFAUDIO_REPO}/Release.key" | sudo apt-key add -;

		# add repo source for libfaudio
		echo "Adding OBS source (for faudio) ... ";
		addAptCustomSource unofficial-libfaudio-obs "deb ${LIBFAUDIO_REPO}/ ./";

		# update apt's local cache
		echo "Updating apt's local cache; this may take a few minutes ... ";
		sudo apt-get update 2>/dev/null >/dev/null;
	fi

	# refresh value
	isfAudioInOfficialSources=$(apt search "libfaudio0:i386" | wc -l);
	if [[ "0" == "$isfAudioInOfficialSources" ]]; then
		echo "ERROR: Installing custom source for libfaudio0 dependency. Please resolve manually before continuing.";
		exit;
	fi

	# fix libfaudio issue (still needed in Mint 19.x / LMDE 4)
	# if unsure, try running 'sudp apt-get install --install-recommends winehq-staging'
	# if it works, this is not needed.
	# otherwise, if you get errors about wine-staging and held broken packages use this:
	echo "Attempting to resolve any potential conflicts (warnings can be ignored) ... ";
	sudo dpkg --force-remove-reinstreq --force-remove-essential --purge wine-staging wine-staging-i386 wine-staging-i386:i386 libfaudio:i386 libfaudio0:i386 winehq-staging wine-staging-amd64;

	echo "Installing libfaudio0 dependency ... ";
	sudo apt-get install --install-recommends -y libfaudio0:i386;
fi

# add key for winehq
echo "Adding signing key for wine ... ";
wget -qO - https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -;

# add repo source for winehq
echo "Adding WineHQ source ... ";
addAptCustomSource winehq "deb https://dl.winehq.org/wine-builds/debian/ ${DEBIAN_CODENAME} main";

# update apt's local cache
echo "Updating apt's local cache; this may take a few minutes ... ";
sudo apt-get update 2>/dev/null >/dev/null;

# install wine-stable
echo "Installing winehq-stable ... ";
sudo apt-get install --install-recommends -y libfaudio0 fonts-wine libwine winehq-stable;

# purge any old winetricks from official repo and install latest from github
# if you weren't aware, even winetricks in repo is actually just a shell script :-)
echo "Installing winetricks from source ... ";
sudo apt-get -y purge winetricks 2>/dev/null;
wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks;
sudo chown root:root winetricks;
sudo mv -t /usr/bin winetricks;
sudo chmod a+rx /usr/bin/winetricks;
