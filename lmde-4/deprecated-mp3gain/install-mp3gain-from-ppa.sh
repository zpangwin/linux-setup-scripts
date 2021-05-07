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

# get the sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

#========================================================================
# -> As of 2020, July 06 attempting to add this repo results in an error message and fails to add to apt sources:
#	$ sudo add-apt-repository ppa:flexiondotorg/audio
#		Cannot add PPA: ''This PPA does not support focal''.
#========================================================================
#		echo "Adding ppa:flexiondotorg/audio ...";
#		addPPAIfNotInSources ppa:flexiondotorg/audio;
#
#		echo "Updating apt's local cache ...";
#		sudo apt-get update 2>&1 >/dev/null;
#
#		echo "Installing mp3gain ...";
#		sudo apt-get install -y --install-recommends mp3gain;
#========================================================================
# WORKAROUND: Manually download deb file from LaunchPad PPA and install
#			it manually.
#========================================================================

echo "Installing mp3gain ...";
startDir=$(pwd);
tmpDir=$(mktemp -d /tmp/XXX);
cd "${tmpDir}";

wget https://launchpad.net/~flexiondotorg/+archive/ubuntu/audio/+build/13635871/+files/mp3gain_1.5.2-r2-6~bionic1.0_amd64.deb

sudo apt-get install -y ./*.deb

cd "${startDir}";
