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

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

echo "Installing indicator-sound-switcher ...";
sudo apt-get install -y --install-recommends indicator-sound-switcher;
