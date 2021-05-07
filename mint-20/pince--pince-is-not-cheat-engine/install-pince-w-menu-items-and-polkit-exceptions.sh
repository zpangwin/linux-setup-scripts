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

COPMBILE_GDB_WITH_PYTHON_SUPPORT="false";

# get the sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

STARTING_DIR=$(pwd);

#equivalents to cheat engine
#===========================================================================================================
# PINCE
# PINCE is a front-end/reverse engineering tool for the GNU Project Debugger (GDB), focused on games.
# However, it can be used for any reverse-engineering related stuff. PINCE is an abbreviation for "PINCE is not Cheat Engine"
# PINCE is in development right now, read Features part of the project to see what is done and Roadmap part to see what is
# currently planned. Also, please read Wiki Page of the project to understand how PINCE works.
#
# See:
#   https://github.com/korcankaraokcu/PINCE
#
# 1. install PINCE dependencies:
# 	texinfo -> contains makeinfo which you otherwise get a warning about while building gdb
sudo apt-get install -y python3-setuptools python3-pip python3-pyqt5 python3-dev gcc g++ git texinfo autoconf automake autotools-dev intltool libltdl-dev libncurses-dev libreadline-dev libtool;
sudo -H pip3 install psutil pexpect distorm3 pygdbmi;

# 2. Download PINCE source code project
PINCE_SOURCE_DIR="/opt/PINCE";

#sudo mkdir -p "${PINCE_SOURCE_DIR}";
rm -R /tmp/PINCE 2>/dev/null;
git clone https://github.com/korcankaraokcu/PINCE.git /tmp/PINCE;
if [[ "0" != "$?" ]]; then
    echo "ERROR: Failed to download PINCE code from github; aborting script...";
    exit;
fi
sudo mv -t /opt /tmp/PINCE;

# 3. Handle permission issues that can potentially block install
mkdir "${HOME}/.cache/pip" 2>/dev/null;
sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${HOME}/.cache" 2>/dev/null;

sudo chmod ug+rx "${PINCE_SOURCE_DIR}/"*.sh;
sudo find "${PINCE_SOURCE_DIR}" -type f -iname '*.py' -exec chmod ug+rx "{}" \;;

if [[ ! -f "${PINCE_SOURCE_DIR}/install_pince.sh" ]]; then
    echo "ERROR: Install failed or install_pince.sh script not present; aborting script...";
    exit;
fi

# 4. Compiling gdb with python support
if [[ "true" == "${COPMBILE_GDB_WITH_PYTHON_SUPPORT}" ]]; then
	sudo mkdir "${PINCE_SOURCE_DIR}/libPINCE/gdb_pince" 2>/dev/null;
	sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${PINCE_SOURCE_DIR}/libPINCE/gdb_pince";

	cd "${PINCE_SOURCE_DIR}/libPINCE/gdb_pince";

	wget "http://ftp.gnu.org/gnu/gdb/gdb-8.3.1.tar.gz"
	tar -zxvf gdb-8.3.1.tar.gz;
	cd gdb-8.3.1;
	CC=gcc CXX=g++ ./configure --prefix="$(pwd)" --with-python=python3 && make && sudo make -C gdb install;
	sudo cp -R gdb/data-directory/* share/gdb/
	sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} share/gdb/;
fi

# 5. Run the install script (note the install will take a fairly long time... was 10-15 minutes for me)
cd "${PINCE_SOURCE_DIR}";
bash ./install_pince.sh

cd "${STARTING_DIR}";

# 6. Copy icon to central location. Note main image is a transparency and looks like shit in menus
#    So first we are making a temp copy, then adding a background, then using one of the copies that
#    has a background.
LOGOS_DIR="${PINCE_SOURCE_DIR}/media/logo/ozgurozbek";
sudo mkdir -p "${LOGOS_DIR}/converted";

#pick one of the colored logos...doesn't matter which
sudo cp "${LOGOS_DIR}/pince_small_cyan.png" "/usr/share/icons/pince.png"
sudo cp "${LOGOS_DIR}/pince_small_cyan.png" "/usr/share/pixmaps/pince.png"

# ================================================================================================

# copy script files
sudo cp -a "${SCRIPT_DIR}/usr/bin/pkexec-pince" /usr/bin/pkexec-pince;
sudo cp -a "${SCRIPT_DIR}/usr/share/applications/pince.desktop" /usr/share/applications/pince.desktop;

sudo chown root:root /usr/bin/pkexec-pince;
sudo chown root:root /usr/share/applications/pince.desktop;

sudo chmod 755 /usr/bin/pkexec-pince;
sudo chmod 644 /usr/share/applications/pince.desktop;

# Install policykit exception...
if [[ ! -f /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy ]]; then
	sudo cp -a "${SCRIPT_DIR}/usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy" /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy;
else
	# check if the policy is already defined...
	policy_defined=$(grep 'id="org.freedesktop.policykit.pkexec.run-pince"' /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy|wc -l);
	if [[ "0" == "${policy_defined}" ]]; then
		# make a backup of current policykit config first
		sudo cp -a /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy.$(date +'%Y%m%d%H%M%S').bak;

		# remove the closing tag from current file
		sudo sed -i -E 's/^<\/policyconfig>//g' /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy;

		# copy the <action> tag and new closing tag from file in install folder to actual policykit file
		cat "${SCRIPT_DIR}/usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy"|sed -n '/^.*<action/,$p'|sudo tee --append /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy >/dev/null;
	fi
fi

# tell menu to update
sudo update-desktop-database;
