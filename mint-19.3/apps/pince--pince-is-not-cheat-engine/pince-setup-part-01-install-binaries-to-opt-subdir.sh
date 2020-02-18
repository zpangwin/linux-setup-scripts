#!/bin/bash

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
sudo apt install -y python3-setuptools python3-pip python3-pyqt5 python3-dev gcc g++ git;
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
sudo mv /tmp/PINCE /opt/;

# 3. Handle permission issues that can potentially block install
mkdir "${HOME}/.cache/pip" 2>/dev/null;
sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${HOME}/.cache" 2>/dev/null;

sudo chmod u+x "${PINCE_SOURCE_DIR}/"*.py;
sudo chmod u+x "${PINCE_SOURCE_DIR}/"*.sh;

if [[ ! -e "${PINCE_SOURCE_DIR}/install.sh" ]]; then
    echo "ERROR: Install failed or install script not present; aborting script...";
    exit;
fi

# 4. Run the install script (note the install will take a fairly long time... was 10-15 minutes for me)
cd "${PINCE_SOURCE_DIR}";
./install.sh;

# 5. Copy icon to central location. Note main image is a transparency and looks like shit in menus
#    So first we are making a temp copy, then adding a background, then using one of the copies that
#    has a background.
LOGOS_DIR="${PINCE_SOURCE_DIR}/media/logo/ozgurozbek";
sudo mkdir -p "${LOGOS_DIR}/converted";

sudo cp "${LOGOS_DIR}/pince_big.png" "${LOGOS_DIR}/converted/black_on_transparent.png";
sudo convert "${LOGOS_DIR}/pince_big.png" -negate "${LOGOS_DIR}/converted/white_on_transparent.png";
sudo convert "${LOGOS_DIR}/pince_big.png" -background white -flatten -negate "${LOGOS_DIR}/converted/white_on_black.png";
sudo convert "${LOGOS_DIR}/pince_big.png" -background white -flatten "${LOGOS_DIR}/converted/black_on_white.png";
sudo convert "${LOGOS_DIR}/pince_big.png" -background 'rgb(51,119,255)' -flatten -negate "${LOGOS_DIR}/converted/white_on_orange.png";
sudo convert "${LOGOS_DIR}/pince_big.png" -background 'rgb(51,119,255)' -flatten "${LOGOS_DIR}/converted/black_on_blue-51-119-255.png";
sudo convert "${LOGOS_DIR}/pince_big.png" -background 'rgb(179,218,255)' -flatten "${LOGOS_DIR}/converted/black_on_blue-179-218-255.png";
sudo convert "${LOGOS_DIR}/pince_big.png" -background 'rgb(128,193,255)' -flatten "${LOGOS_DIR}/converted/black_on_blue-128-193-255.png";
sudo convert "${LOGOS_DIR}/converted/white_on_transparent.png" -background 'rgb(179,179,179)' -flatten "${LOGOS_DIR}/converted/white_on_gray.png";
sudo convert "${LOGOS_DIR}/converted/white_on_transparent.png" -background 'rgb(51,119,255)' -flatten "${LOGOS_DIR}/converted/white_on_blue-51-119-255.png";
sudo convert "${LOGOS_DIR}/converted/white_on_transparent.png" -background 'rgb(51,119,255)' -flatten -negate "${LOGOS_DIR}/converted/black_on_orange.png";

#pick one of the colored logos...doesn't matter which
sudo cp "${LOGOS_DIR}/converted/black_on_blue-128-193-255.png" "/usr/share/icons/pince.png"

