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

sudo apt-get install -y apt-transport-https curl ffmpeg;

# add key
echo "Adding signing key ...";
wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | sudo apt-key add -;

# add repo
addCustomSource vivaldi-stable "deb https://repo.vivaldi.com/archive/deb/ stable main";

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

# install package
echo "Installing Vivaldi ...";
sudo apt-get install -y vivaldi-stable;

if [[ -f /opt/vivaldi/update-ffmpeg && -x /opt/vivaldi/update-ffmpeg ]]; then
	bash /opt/vivaldi/update-ffmpeg;
fi
