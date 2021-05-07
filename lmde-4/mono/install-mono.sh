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
	# 2020-11-04 Mono currently only supports buster
	# See:
	#	https://www.mono-project.com/download/stable/#download-lin-debian
	echo "Debian '${DEBIAN_CODENAME}' is either not supported by Mono or requires script updates."
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
	#	https://www.mono-project.com/download/stable/#download-lin-debian
	#
	echo "Installing dependencies ...";
	sudo apt-get install -y apt-transport-https dirmngr gnupg ca-certificates;

	echo "Adding key ...";
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF;

	# See instructions at:
	# https://www.mono-project.com/download/stable/
	#
	echo "Adding custom repo source ...";
	addAptCustomSource mono-official-stable "deb https://download.mono-project.com/repo/debian stable-buster main";

	echo "Updating apt's local cache ...";
	sudo apt-get update --quiet --yes 2>/dev/null >/dev/null;
fi

echo "Installing mono-complete ...";
MONO_PACKAGES="mono-runtime mono-devel mono-complete referenceassemblies-pcl ca-certificates-mono mono-xsp4";

echo -e "\nRunning: apt-get install --install-recommends -y $MONO_PACKAGES";
sudo apt-get install --install-recommends -y -q $MONO_PACKAGES;
