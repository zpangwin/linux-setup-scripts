#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

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

sudo apt-get update;

sudo apt-get install -y --install-recommends sublime-text;

if [[ "" != "${SCRIPT_DIR}" && -f "${SCRIPT_DIR}/usr/share/nemo/actions/edit-with-sublime.nemo_action" ]]; then
    if [[ ! -f "/usr/share/nemo/actions/edit-with-sublime.nemo_action" ]]; then
        sudo cp -a "${SCRIPT_DIR}/usr/share/nemo/actions/edit-with-sublime.nemo_action" "/usr/share/nemo/actions/edit-with-sublime.nemo_action";
    fi
    sudo chown root:root "/usr/share/nemo/actions/edit-with-sublime.nemo_action";
    sudo chmod 644 "/usr/share/nemo/actions/edit-with-sublime.nemo_action";
fi
