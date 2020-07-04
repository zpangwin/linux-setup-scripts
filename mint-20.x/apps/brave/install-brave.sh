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

sudo apt-get install -y apt-transport-https curl;

# add key
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -;

# add repo
addCustomSource brave-browser-release "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main";

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

# install package
echo "Installing Brave ...";
sudo apt-get install -y brave-browser;


