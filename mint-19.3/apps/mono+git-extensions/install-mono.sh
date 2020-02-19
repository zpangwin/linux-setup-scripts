#!/bin/bash

#get sudo prompt out of the way
sudo ls -acl >/dev/null

if [[ ! -e /etc/apt/sources.list.d/mono-official-stable.list ]]; then
	echo "";
	echo "================================================================";
	echo "Installing latest Mono from mono-project.org...";
	echo "================================================================";


	# Instructions from (last updated 2019-05-04 for ubuntu 18.04):
	#	https://www.mono-project.com/download/stable/#download-lin
	#
	sudo apt install gnupg ca-certificates
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
	echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list;
    sudo chmod 644 /etc/apt/sources.list.d/mono-official-stable.list;
	sudo apt update --yes;
fi

MONO_PACKAGES="mono-runtime mono-devel mono-complete referenceassemblies-pcl ca-certificates-mono mono-xsp4";
echo -e "\nRunning: apt install --install-recommends -y $MONO_PACKAGES";
sudo apt install --install-recommends -y $MONO_PACKAGES;
