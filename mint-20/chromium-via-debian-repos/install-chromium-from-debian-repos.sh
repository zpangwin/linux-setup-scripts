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

# Copy pre-configured debian apt files for chromium
# debian versions:	https://www.debian.org/releases/
#					https://unix.stackexchange.com/questions/222394/linux-debian-codenames
#					https://en.wikipedia.org/wiki/Debian_version_history
#
# As of 13 Aug, 2020:
# Buster is the current stable release; Bullseye will be the next stable release but has no release date set.
#
# IMPORTANT: NEVER USE SID -> sid (Still In Development)
#
if [[ ! -f "${SCRIPT_DIR}/etc/apt/sources.list.d/debian-chromium.list" ]]; then
	echo "Error: missing required file debian-chromium.list; Extract archive or clone git repo then run script from there.";
	exit;
fi

if [[ ! -f "${SCRIPT_DIR}/etc/apt/preferences.d/debian-chromium.pref" ]]; then
	echo "Error: missing required file debian-chromium.pref; Extract archive or clone git repo then run script from there.";
	exit;
fi

echo "Configuring apt for debian chromium ...";
if [[ -f "/etc/apt/sources.list.d/debian-chromium.list" ]]; then
	sudo mv "/etc/apt/sources.list.d/debian-chromium.list" "/etc/apt/sources.list.d/debian-chromium.list.$(date +'%Y%m%d%H%M%S').bak";
fi
sudo cp -a -t "/etc/apt/sources.list.d" "${SCRIPT_DIR}/etc/apt/sources.list.d/debian-chromium.list";
sudo chown root:root "/etc/apt/sources.list.d/debian-chromium.list";
sudo chmod 644 "/etc/apt/sources.list.d/debian-chromium.list";

if [[ -f "/etc/apt/preferences.d/debian-chromium.pref" ]]; then
	sudo mv "/etc/apt/preferences.d/debian-chromium.pref" "/etc/apt/preferences.d/debian-chromium.pref.$(date +'%Y%m%d%H%M%S').bak";
fi
sudo cp -a -t "/etc/apt/preferences.d" "${SCRIPT_DIR}/etc/apt/preferences.d/debian-chromium.pref";
sudo chown root:root "/etc/apt/preferences.d/debian-chromium.pref";
sudo chmod 644 "/etc/apt/preferences.d/debian-chromium.pref";


# add debian signing keys from ubuntu keyserver
# These commands pull the Debian signing keys from keyserver.ubuntu.com site so the things you get
# from the Debian repositories can be verified as legitimate. There are three key additions. Do all three.
echo "Adding Debian signing keys ...";
sudo apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys DCC9EFBF77E11517;
sudo apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 648ACFD622F3D138;
sudo apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 112695A0E562B32A;

echo "Updating apt's local cache ...";
sudo apt-get update 2>/dev/null >/dev/null;

echo "Remove any old chromium-browser installs to prevent conflicts / snaps ...";
sudp apt-get remove --purge chromium-browser 2>/dev/null;

echo "Installing chromium ...";
sudo apt-get install -y --install-recommends chromium;

# check for chroot environment
if [[ "root" == "${USER}" && "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]; then
	# make sure folder exists
	sudo mkdir -p /etc/skel/Desktop 2>&1 >/dev/null;
	# copy shortcut to /etc/skel/Desktop
	sudo cp -a -t /etc/skel/Desktop /usr/share/applications/chromium.desktop 2>&1 >/dev/null;

	sudo chmod 750 /etc/skel/Desktop/chromium.desktop 2>&1 >/dev/null;
fi
