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

# see:
#	https://github.com/Genymobile/scrcpy
#	https://www.linuxuprising.com/2019/03/control-android-devices-from-your.html
#

# requires rpm fusion free
if [[ ! -f /etc/yum.repos.d/rpmfusion-free.repo ]]; then
	sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm;
fi

# install depends
sudo dnf install -y android-tools ffmpeg SDL2-devel ffms2-devel meson gcc make;

# alternate approach:
#	https://www.reddit.com/r/linuxquestions/comments/ir0jy5/whats_the_best_way_to_install_scrcpy_on_fedora/
# sudo dnf copr enable zeno/scrcpy
#	sudo dnf install scrcpy
if [[ ! -f "/etc/yum.repos.d/copr-scrcpy.repo" ]]; then
	if [[ ! -z "${SCRIPT_DIR}" && -f "${SCRIPT_DIR}/etc/yum.repos.d/copr-scrcpy.repo" ]]; then
		sudo cp -a "${SCRIPT_DIR}/etc/yum.repos.d/copr-scrcpy.repo" "/etc/yum.repos.d/copr-scrcpy.repo";
	fi
fi
if [[ -f "/etc/yum.repos.d/copr-scrcpy.repo" ]]; then
	sudo dnf install -y scrcpy;
fi
