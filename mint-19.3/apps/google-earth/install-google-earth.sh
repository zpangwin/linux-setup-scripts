#!/bin/bash

if [ -f ../functions.sh ]; then
    . ../functions.sh

elif [ -f ~/Scripts/functions.sh ]; then
    . ~/Scripts/functions.sh;

elif [ -f ~/Scripts/apps/functions.sh ]; then
    . ~/Scripts/apps/functions.sh;
fi

# add key
wget -qO - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -;

# add repo
addCustomSource google-earth "deb [arch=amd64] http://dl.google.com/linux/earth/deb/ stable main";

# update local apt cache
sudo apt update 2>&1 >/dev/null;

# install package
sudo apt install -y google-earth-pro-stable;