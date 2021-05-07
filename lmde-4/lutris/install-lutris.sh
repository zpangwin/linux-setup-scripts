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

if [[ 'buster' != "${DEBIAN_CODENAME}" ]]; then
	# 2020-11-07 This repo currently only supports buster
	# See:
	#	https://lutris.net/downloads/
	echo "Debian '${DEBIAN_CODENAME}' is either not supported by this repo or requires script updates."
	exit;
fi

HAS_WINE_STAGING=$(echo $(which wine 2>/dev/null && wine --version) | grep -Pci 'staging|devel');
if [[ "1" != "${HAS_WINE_STAGING}" ]]; then
	echo 'ERROR: install wine-staging first.';
	exit;
fi

HAS_NVIDIA=$(inxi -G|grep -Pci '(nvidia|GeForce)');
if [[ "0" != "${HAS_NVIDIA}" ]]; then
	HAS_NOUVEAU=$(inxi -G|grep -ic nouveau);
	if [[ "1" == "${HAS_NVIDIA_DRIVER}" ]]; then
		echo 'ERROR: Found active nouveau drivers; install proprietary nvidia drivers, reboot, then rerun script.';
		exit;
	fi

	HAS_NVIDIA_DRIVER=$(inxi -G|sed -E 's/^\s+|^\s+(Graphics:|OpenGL:)\s+//g'|sed -E 's/\s+(driver|Display|resolution|v|server|renderer):/\n\1:/g'|sort -u|grep -i driver|grep -ic nvidia);
	if [[ "0" == "${HAS_NVIDIA_DRIVER}" ]]; then
		echo 'ERROR: install proprietary nvidia drivers, reboot, then rerun script.';
		exit;
	fi

	HAS_VULKAN_DRIVER=$(apt search libvulkan1|grep -P '^i\s+libvulkan1\s'|wc -l);
	if [[ "1" != "${HAS_NVIDIA_DRIVER}" ]]; then
		echo 'ERROR: install libvulkan1 and libvulkan1:i386 first (and reboot).';
		exit;
	fi
fi

# add key for repo
echo "Adding signing key for OBS repo ... ";
wget -qO - https://download.opensuse.org/repositories/home:/strycore/Debian_10/Release.key | sudo apt-key add -;

# add repo source for Launchpad PPA
echo "Adding repo source ... ";
addAptCustomSource lutris "deb http://download.opensuse.org/repositories/home:/strycore/Debian_10/ ./";

# update apt's local cache
echo "Updating apt's local cache; this may take a minute ... "
sudo apt-get update 2>/dev/null >/dev/null;

# install package
echo "Installing lutris ...";
sudo apt-get install -y --install-recommends lutris;

