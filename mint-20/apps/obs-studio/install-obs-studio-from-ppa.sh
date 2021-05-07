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

# add ppa source
echo "Adding PPA source ... ";
addPPAIfNotInSources 'ppa:obsproject/obs-studio'

# update apt's local cache
echo "Updating apt's local cache; this may take a minute ... "
sudo apt-get update 2>/dev/null >/dev/null;

# install OBS
echo "Installing obs-studio ... ";
sudo apt-get install --install-recommends -y obs-studio;

