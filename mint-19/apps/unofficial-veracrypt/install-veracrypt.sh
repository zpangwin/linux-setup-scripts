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

if [[ "bionic" != "${UBUNTU_CODENAME}" || "focal" != "${UBUNTU_CODENAME}" || "xenial" != "${UBUNTU_CODENAME}" || ]]; then
    echo "Error: This PPA only supports bionic, focal, and xenial as of 2020 August 15th.";
    exit;
fi

echo "Adding custom repo source ...";
addAptCustomSource unofficial-veracrypt-unit193 "deb http://ppa.launchpad.net/unit193/encryption/ubuntu ${UBUNTU_CODENAME} main";

if [[ -f /etc/apt/sources.list.d/unofficial-veracrypt-unit193.list ]]; then
	# insert comment line at top for benefit of someone checking from files
	# note - these insertions are done in reverse order so that they appear correct when reading from file
	sudo sed -i '1s/^/#\n\n/' /etc/apt/sources.list.d/unofficial-veracrypt-unit193.list;
	sudo sed -i '1s|^|# See:\n# https://askubuntu.com/questions/929195/\n|' /etc/apt/sources.list.d/unofficial-veracrypt-unit193.list;
	sudo sed -i '1s/^/# Unit193 is an Xubuntu developer and well known in the open source community.\n/' /etc/apt/sources.list.d/unofficial-veracrypt-unit193.list;
fi

# update apt's local cache
echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

# install package
echo "Installing Veracrypt ...";
sudo apt install -y veracrypt;


