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

HAS_WINE_STAGING=$(echo $(which wine 2>/dev/null && wine --version) | grep -i staging|wc -l);
if [[ "1" != "${HAS_WINE_STAGING}" ]]; then
	echo 'ERROR: install wine-staging first.';
	exit;
fi

HAS_NVIDIA=$(inxi -G|grep -Pi '(nvidia|GeForce)'|wc -l);
if [[ "0" != "${HAS_NVIDIA}" ]]; then
	HAS_NVIDIA_DRIVER=$(apt search nvidia-driver|grep -P '^i\s+nvidia\-driver\-[0-9][0-9]*\s'|wc -l);
	if [[ "1" != "${HAS_NVIDIA_DRIVER}" ]]; then
		echo 'ERROR: install nvidia drivers, libvulkan1, and libvulkan1:i386 first (and reboot).';
		exit;
	fi

	HAS_VULKAN_DRIVER=$(apt search libvulkan1|grep -P '^i\s+libvulkan1\s'|wc -l);
	if [[ "1" != "${HAS_NVIDIA_DRIVER}" ]]; then
		echo 'ERROR: install libvulkan1 and libvulkan1:i386 first (and reboot).';
		exit;
	fi
fi

# add ppa
echo "Adding ppa:lutris-team/lutris ...";
addPPAIfNotInSources ppa:lutris-team/lutris;

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

echo "Installing lutris ...";
sudo apt-get install -y --install-recommends lutris;
