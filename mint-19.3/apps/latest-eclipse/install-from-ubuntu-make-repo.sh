#!/bin/bash

ECLIPSE_INSTALL_TYPE="eclipse-jee";
ECLIPSE_INSTALL_DIR="${HOME}/${ECLIPSE_INSTALL_TYPE}";
ECLIPSE_WORKSPACE_DIR="${HOME}/${ECLIPSE_INSTALL_TYPE}-workspace";
ECLIPSE_MENU_SHORTCUT="${HOME}/.local/share/applications/${ECLIPSE_INSTALL_TYPE}.desktop";

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

if [ -f ../functions.sh ]; then
    . ../functions.sh
else
	echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
	exit;
fi

# Add PPA
addPPAIfNotInSources "ppa:lyzardking/ubuntu-make";

# update local apt cache
sudo apt update;

# install ubuntu-make
sudo apt install -y ubuntu-make;

# use ubuntu-make to install eclipse
umake ide "${ECLIPSE_INSTALL_TYPE}" "${ECLIPSE_INSTALL_DIR}";

if [[ ! -e "${ECLIPSE_MENU_SHORTCUT}" ]]; then
	echo '#!/usr/bin/env xdg-open'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo ''|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo '[Desktop Entry]'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Version=1.0'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Name=Eclipse'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Comment=Eclipse Integrated Development Environment'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Keywords=Programming;Development;IDE;'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo "Exec=${ECLIPSE_INSTALL_DIR}/eclipse -data ${ECLIPSE_WORKSPACE_DIR}"|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Terminal=false'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'X-MultipleArgs=false'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Type=Application'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo "Icon=${ECLIPSE_INSTALL_DIR}/icon.xpm"|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Categories=Programming;Development;IDE;'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'StartupNotify=true'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo ''|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;

	sudo chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${ECLIPSE_MENU_SHORTCUT}";
	sudo chmod u+rw,g+r "${ECLIPSE_MENU_SHORTCUT}";
fi
