#!/bin/bash

if [ -f ../functions.sh ]; then
    . ../functions.sh
else
	echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
	exit;
fi

# add ppa source
echo "Adding PPA source ... ";
addPPAIfNotInSources 'ppa:obsproject/obs-studio'

# update local apt cache
echo "Updating apt cache; this may take a minute ... "
sudo apt-get update 2>/dev/null >/dev/null;

# install OBS
echo "Installing obs-studio ... ";
sudo apt-get install --install-recommends -y obs-studio;

