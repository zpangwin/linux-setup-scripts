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

# get the sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

# add key
echo "Adding key ...";
curl -fsSL https://download.opensuse.org/repositories/home:ungoogled_chromium/Ubuntu_Focal/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home:ungoogled_chromium.gpg > /dev/null

# add repo
echo "Adding custom repo source ...";
addAptCustomSource ungoogled_chromium 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Focal/ /';

# update apt's local cache
echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

# install package
echo "Installing Chromium ...";
sudo apt-get install -y ungoogled-chromium;
