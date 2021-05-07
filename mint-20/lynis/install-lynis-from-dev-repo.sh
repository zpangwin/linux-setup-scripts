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

# depends
sudo apt install -y apt-transport-https;

# configure APT to skip downloading translations. This saves bandwidth and prevents additional load on the repository servers.
if [[ ! -e /etc/apt/apt.conf.d/99disable-translations ]]; then
	echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99disable-translations >/dev/null;
fi

# add key
echo "Adding key ...";
sudo wget -O - https://packages.cisofy.com/keys/cisofy-software-public.key | sudo apt-key add -;

# add repo
echo "Adding custom repo source ...";
addAptCustomSource 'cisofy-lynis' 'deb https://packages.cisofy.com/community/lynis/deb/ stable main'

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

echo "Installing sublime ...";
sudo apt-get install -y --install-recommends lynis;
