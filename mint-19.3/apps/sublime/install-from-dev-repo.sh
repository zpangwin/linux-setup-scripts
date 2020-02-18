#!/bin/bash

if [ -f ../functions.sh ]; then
    . ../functions.sh

elif [ -f ~/Scripts/functions.sh ]; then
    . ~/Scripts/functions.sh;

elif [ -f ~/Scripts/apps/functions.sh ]; then
    . ~/Scripts/apps/functions.sh;
fi

# add key
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -;

# add repo
addCustomSource sublimetext deb https://download.sublimetext.com/ apt/stable/

sudo apt update;

sudo apt install -y --install-recommends sublime-text;
