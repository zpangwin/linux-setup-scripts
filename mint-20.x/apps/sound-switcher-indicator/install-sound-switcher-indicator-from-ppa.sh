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

# add ppa
echo "Adding ppa:yktooo/ppa ...";
addPPAIfNotInSources ppa:yktooo/ppa;

if [[ -f /etc/apt/sources.list.d/yktooo-ppa-focal.list ]]; then
	# rename so it's more obvious what this is from the filename...
	sudo mv "/etc/apt/sources.list.d/yktooo-ppa-focal.list" "/etc/apt/sources.list.d/yktooo-soundswitcher-focal.list";
fi

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

echo "Installing indicator-sound-switcher ...";
sudo apt-get install -y --install-recommends indicator-sound-switcher;

