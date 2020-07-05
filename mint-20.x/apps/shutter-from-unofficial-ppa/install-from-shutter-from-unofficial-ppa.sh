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

# add ppa
echo "Adding ppa:linuxuprising/shutter ...";
addPPAIfNotInSources ppa:linuxuprising/shutter;

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

echo "Installing shutter ...";
sudo apt-get install -y --install-recommends shutter;
