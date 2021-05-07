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

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

# add key
echo "Adding key ...";
wget -qO - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -;

# add repo
echo "Adding custom repo source ...";
addAptCustomSource google-earth-pro "deb [arch=amd64] http://dl.google.com/linux/earth/deb/ stable main";

# update apt's local cache
echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

# install package
echo "Installing Google Earth Pro ...";
sudo apt-get install -y google-earth-pro-stable;
