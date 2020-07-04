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

echo "Adding ppa:unit193/encryption ...";
addPPAIfNotInSources ppa:unit193/encryption

# update apt's local cache
echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

# install package
echo "Installing Veracrypt ...";
sudo apt install -y veracrypt;


