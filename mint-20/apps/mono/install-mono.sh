#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

# If function is already load (such as if this script is loaded into a calling script), do nothing.
# Otherwise, load functions
isFunctionLoaded=$(declare -f addAptCustomSource|wc -l);
if [[ "0" == "${isFunctionLoaded}" ]]; then
	if [[ ! -f "${SCRIPT_DIR_PARENT}/functions.sh" ]]; then
	    echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
	    exit;
	fi
	. "${SCRIPT_DIR_PARENT}/functions.sh";
fi

ubuntuVersion=$(grep DISTRIB_RELEASE /etc/upstream-release/lsb-release|sed -E 's/^\w+=([0-9[0-9]+\.[0-9][0-9])$/\1/g');
ubuntuCodeName=$(grep DISTRIB_CODENAME /etc/upstream-release/lsb-release|sed -E 's/^\w+=(\w+)$/\1/g');
if [[ "18.04" != "${ubuntuVersion}" && "20.04" != "${ubuntuVersion}" ]]; then
	echo "Error: Unsupported Ubuntu base version '${ubuntuVersion}'.";
	exit;
fi

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
	echo "Adding GNUPG certificates ...";
	sudo apt-get install -y gnupg ca-certificates;

	echo "Adding key ...";
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF;

	# See instructions at:
	# https://www.mono-project.com/download/stable/
	#
	echo "Adding custom repo source ...";
	if [[ "20.04" == "${ubuntuVersion}" ]]; then
		addAptCustomSource mono-official-stable "deb https://download.mono-project.com/repo/ubuntu stable-focal main";

	elif [[ "18.04" == "${ubuntuVersion}" ]]; then
		addAptCustomSource mono-official-stable "deb https://download.mono-project.com/repo/ubuntu stable-bionic main";
	fi

	echo "Updating apt's local cache ...";
	sudo apt-get update --quiet --yes;
fi

echo "Installing mono-complete ...";
MONO_PACKAGES="mono-runtime mono-devel mono-complete referenceassemblies-pcl ca-certificates-mono mono-xsp4";
echo -e "\nRunning: apt-get install --install-recommends -y $MONO_PACKAGES";
sudo apt-get install --install-recommends -y -q $MONO_PACKAGES;
