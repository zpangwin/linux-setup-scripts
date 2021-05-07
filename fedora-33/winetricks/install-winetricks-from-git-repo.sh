#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

# purge any old winetricks from official repo and install latest from github
# if you weren't aware, even winetricks in repo is actually just a shell script :-)
echo "Installing winetricks from source ... ";
sudo dnf erase -y winetricks 2>/dev/null;
wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks;
sudo chown root:root winetricks;
sudo mv -t /usr/bin winetricks;
sudo chmod a+rx /usr/bin/winetricks;

isSELinuxEnabled=$(sestatus 2>/dev/null|grep -Pci 'SELinux status:\s*enabled');
if [[ 1 == $isSELinuxEnabled && 1 == $(which restorecon 2>/dev/null|wc -l) ]]; then
	echo "Restoring SELinux Filecontext...";
	sudo restorecon /usr/bin/winetricks;
	echo "SELinux filecontext restored.";
fi
