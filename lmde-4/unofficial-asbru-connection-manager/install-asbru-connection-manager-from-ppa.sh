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
	# 2020-11-04 This repo currently only supports buster and bullseye
	# See:
	#	https://launchpad.net/asbru-cm/
	echo "Debian '${DEBIAN_CODENAME}' is either not supported by this repo or requires script updates."
	exit;
fi

# ================================================================================================================
# This script relies on the method described here:
#	http://www.webupd8.org/2014/10/how-to-add-launchpad-ppas-in-debian-via.html
#
# which is a workaround in Debian to use Launchpad PPAs as a source.
# this is done to allow us to both install asbru-cm AND to receive updates for it.
#
# this requires
#	1. Dependencies for being able to add PPAs:
#		sudo apt-get install software-properties-common python-software-properties
#	2. Adding the PPA from https://launchpad.net/~asbru-cm/+archive/ubuntu/releases
#	3. changing the apt source for the ppa to reference an ubuntu version whose debian base is the same as ours
#		https://askubuntu.com/questions/445487/what-debian-version-are-the-different-ubuntu-versions-based-on
#			19.10  eoan       buster  / sid   - 10
#			19.04  disco      buster  / sid
#			18.10  cosmic     buster  / sid
#			18.04  bionic     buster  / sid
# ================================================================================================================

# add ppa source - this does not work in Debian 10 buster (the article were it worked was frm 2014...)
#echo "Adding PPA source ... ";
#addPPAIfNotInSources 'ppa:asbru-cm/releases'


# ================================================================================================================
# Note: the page for the PPA also says you can add the source manually with:
#	deb http://ppa.launchpad.net/asbru-cm/releases/ubuntu YOUR_UBUNTU_VERSION_HERE main
# and as of Nov 5th, 2020 it supports bionic, disco, and eoan; bionic being the oldest is likely the best choice.
#	e.g.
#		# add repo source for Launchpad PPA
#		echo "Adding Launchpad source ... ";
#		addAptCustomSource unofficial-asbru-cm "deb http://ppa.launchpad.net/asbru-cm/releases/ubuntu bionic main";
#
# HOWEVER, doing so does NOT add the public key and will result in the following errors from apt-get update:
#
#	Err:20 http://ppa.launchpad.net/asbru-cm/releases/ubuntu bionic InRelease
#	The following signatures couldn't be verified because the public key is not available: NO_PUBKEY DDD6E33F73778C97
#	Reading package lists... Done
#	W: GPG error: http://ppa.launchpad.net/asbru-cm/releases/ubuntu bionic InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY DDD6E33F73778C97
#	E: The repository 'http://ppa.launchpad.net/asbru-cm/releases/ubuntu bionic InRelease' is not signed.
#	N: Updating from such a repository can't be done securely, and is therefore disabled by default.
#
# To avoid this the GPG key must be added first. This can be done manually as indicated here:
#	https://blog.zackad.dev/en/2017/08/17/add-ppa-simple-way.html
#
# 	which says: "Back to ppa webpage, find the signing key that look like 4096R/75BCA694 (What is this?).
#   Copy the portion after the slash but not including the help link; e.g. just 75BCA694."
#	sample:	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 75BCA694
#
# ================================================================================================================

PPA_FINGERPRINT="8B313BF49F30C78AEC27D25CDDD6E33F73778C97";
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "${PPA_FINGERPRINT}";

# add repo source for Launchpad PPA
echo "Adding Launchpad source ... ";
addAptCustomSource unofficial-asbru-cm "deb http://ppa.launchpad.net/asbru-cm/releases/ubuntu bionic main";
addAptCustomSource unofficial-asbru-cm "deb-src http://ppa.launchpad.net/asbru-cm/releases/ubuntu bionic main";

# update apt's local cache
echo "Updating apt's local cache; this may take a minute ... "
sudo apt-get update 2>/dev/null >/dev/null;

# install package
echo "Installing Asbru Connection Manager ... ";
sudo apt-get install --install-recommends -y asbru-cm;

