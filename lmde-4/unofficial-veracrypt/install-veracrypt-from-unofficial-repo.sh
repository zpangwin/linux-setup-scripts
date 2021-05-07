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

if [[ 'buster' != "${DEBIAN_CODENAME}"  ]]; then
	# 2020-11-04 Unofficial Veracrypt repo currently only supports buster
	# See:
	#	https://download.opensuse.org/repositories/home:stevenpusser:veracrypt/
	echo "Debian '${DEBIAN_CODENAME}' is either not supported by this repo or requires script updates."
	exit;
fi

# add key for unofficial veracrypt repo
echo "Adding signing key for OBS repo ... ";
wget -qO - https://download.opensuse.org/repositories/home:stevenpusser:veracrypt/Debian_10/Release.key | sudo apt-key add -;

# add unofficial repo source for veracrypt
APT_SOURCES_FILE="/etc/apt/sources.list.d/unofficial-veracrypt-stevenpusser.list";
echo "Adding OBS source (for faudio) ... ";
addAptCustomSource unofficial-veracrypt-stevenpusser 'deb http://download.opensuse.org/repositories/home:/stevenpusser:/veracrypt/Debian_10/ /';

if [[ -f "${APT_SOURCES_FILE}" ]]; then
	# insert comment line at top for benefit of someone checking from files
	# note - these insertions are done in reverse order so that they appear correct when reading from file
	sudo sed -i '1s/^/#\n\n/' "${APT_SOURCES_FILE}";
	sudo sed -i '1s|^|# See:\n# https://software.opensuse.org/download.html?project=home%3Astevenpusser%3Averacrypt&package=veracrypt\n|' "${APT_SOURCES_FILE}";
	sudo sed -i '1s/^/# stevenpusser is a Pale Moon packager and active in the open source community. See: https://antixlinux.com/forum-archive/latest-palemoon-browser-t7203.html\n\n/' "${APT_SOURCES_FILE}";
fi

# update apt's local cache
echo "Updating apt's local cache; this may take a few minutes ... ";
sudo apt-get update 2>/dev/null >/dev/null;

# install package
echo "Installing Veracrypt ...";
sudo apt-get install -y veracrypt;
