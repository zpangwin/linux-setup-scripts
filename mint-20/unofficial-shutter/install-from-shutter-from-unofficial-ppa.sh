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

# with Ubuntu 20, shutter is no longer available in the central repos
# workaround: add from PPA
#	https://www.linuxuprising.com/2018/10/shutter-removed-from-ubuntu-1810-and.html

if [[ -z "${UBUNTU_CODENAME}" ]]; then
	MINT_CODENAME=$(gawk -F'=' '$1 ~ /^DISTRIB_CODENAME$/ {print $2}' /etc/lsb-release);
	MINT_RELEASE=$(gawk -F'=' '$1 ~ /^DISTRIB_RELEASE$/ {print $2}' /etc/lsb-release);
	UBUNTU_CODENAME=$(gawk -F'=' '$1 ~ /^DISTRIB_CODENAME$/ {print $2}' /etc/upstream-release/lsb-release);
	UBUNTU_RELEASE=$(gawk -F'=' '$1 ~ /^DISTRIB_RELEASE$/ {print $2}' /etc/upstream-release/lsb-release);
fi

case "$UBUNTU_CODENAME" in
	bionic) a=ok ;;
	cosmic) a=ok ;;
	disco) a=ok ;;
	eoan) a=ok ;;
	focal) a=ok ;;
	*) a=FAIL ;;
esac

if [[ "ok" != "${a}" ]]; then
    echo "Error: This PPA only supports bionic, cosmic, disco, eoan, and focal as of 2020 August 15th.";
    exit;
fi

echo "Adding custom repo source ...";
addAptCustomSource unofficial-shutter-linuxuprising "deb http://ppa.launchpad.net/linuxuprising/shutter/ubuntu ${UBUNTU_CODENAME} main";

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

echo "Installing shutter ...";
sudo apt-get install -y --install-recommends shutter;
