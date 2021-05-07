#!/bin/bash

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

rpmFile="$HOME/Desktop/antimicro-2.23-lp152.1.11.x86_64.rpm";
if [[ ! -f "${rpmFile}" ]]; then
	rpmFile="$HOME/Downloads/antimicro-2.23-lp152.1.11.x86_64.rpm";
	if [[ ! -f "${rpmFile}" ]]; then
		# https://opensuse.pkgs.org/15.2/opensuse-oss-x86_64/antimicro-2.23-lp152.1.11.x86_64.rpm.html
		echo "Downloading antimicro ...";
		wget --output-document="${rpmFile}" "https://ftp.lysator.liu.se/pub/opensuse/distribution/leap/15.2/repo/oss/x86_64/antimicro-2.23-lp152.1.11.x86_64.rpm"
	fi
fi

if [[ ! -f "${rpmFile}" ]]; then
	echo "E: Failed to download antimicro-2.23-lp152.1.11.x86_64.rpm";
	exit -1;
fi

echo "Installing antimicro ...";
sudo dnf install -y rpm "${rpmFile}";
