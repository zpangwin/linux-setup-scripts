#!/bin/bash
if [[ ! -f ../functions.sh ]]; then
    echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
    exit;
fi
. ../functions.sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

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

# Create symlinks for sublime
if [[ -f /opt/sublime_text/sublime_text ]]; then
    ln -s /opt/sublime_text/sublime_text /usr/bin/sublime;
    ln -s /opt/sublime_text/sublime_text /usr/bin/sublime-text;
    ln -s /opt/sublime_text/sublime_text /usr/bin/sublime_text;
fi
