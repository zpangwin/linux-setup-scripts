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

if [[ -z "${UBUNTU_CODENAME}" ]]; then
	MINT_CODENAME=$(gawk -F'=' '$1 ~ /^DISTRIB_CODENAME$/ {print $2}' /etc/lsb-release);
	MINT_RELEASE=$(gawk -F'=' '$1 ~ /^DISTRIB_RELEASE$/ {print $2}' /etc/lsb-release);
	UBUNTU_CODENAME=$(gawk -F'=' '$1 ~ /^DISTRIB_CODENAME$/ {print $2}' /etc/upstream-release/lsb-release);
	UBUNTU_RELEASE=$(gawk -F'=' '$1 ~ /^DISTRIB_RELEASE$/ {print $2}' /etc/upstream-release/lsb-release);
fi

case "$UBUNTU_CODENAME" in
	artful) a=ok ;;
	bionic) a=ok ;;
	cosmic) a=ok ;;
	disco) a=ok ;;
	eoan) a=ok ;;
	focal) a=ok ;;
	wily) a=ok ;;
	xenial) a=ok ;;
	yakkety) a=ok ;;
	zesty) a=ok ;;
	*) a=FAIL ;;
esac

if [[ "ok" != "${a}" ]]; then
    echo "Error: This PPA does not support '${UBUNTU_CODENAME}' releases as of 2020 August 18th.";
    exit;
fi

echo "Adding ppa ...";
addPPAIfNotInSources ppa:deki/firejail;

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

# install package
echo "Installing package ...";
sudo apt install -y firejail;


