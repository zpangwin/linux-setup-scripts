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

ECLIPSE_INSTALL_TYPE="eclipse-jee";
ECLIPSE_PARENT_DIR="${HOME}";

# check for chroot environment
isChroot="false";
if [[ "root" == "${USER}" && "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]; then
	ECLIPSE_PARENT_DIR="/etc/skel";
	isChroot="true";
fi

ECLIPSE_INSTALL_DIR="${ECLIPSE_PARENT_DIR}/${ECLIPSE_INSTALL_TYPE}";
ECLIPSE_WORKSPACE_DIR="${ECLIPSE_PARENT_DIR}/${ECLIPSE_INSTALL_TYPE}-workspace";
ECLIPSE_MENU_SHORTCUT="${ECLIPSE_PARENT_DIR}/.local/share/applications/${ECLIPSE_INSTALL_TYPE}.desktop";
if [[ "root" == "${USER}" ]]; then
	ECLIPSE_MENU_SHORTCUT_DIR=$(dirname "${ECLIPSE_MENU_SHORTCUT}");
	sudo mkdir -p "${ECLIPSE_MENU_SHORTCUT_DIR}";
fi

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

# Add PPA
addPPAIfNotInSources "ppa:lyzardking/ubuntu-make";

# update apt's local cache
sudo apt-get update 2>&1 >/dev/null;

# install ubuntu-make
sudo apt-get install -y ubuntu-make;

# use ubuntu-make to install eclipse
sudo umake ide "${ECLIPSE_INSTALL_TYPE}" "${ECLIPSE_INSTALL_DIR}";

if [[ ! -e "${ECLIPSE_MENU_SHORTCUT}" ]]; then
	echo '#!/usr/bin/env xdg-open'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo ''|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo '[Desktop Entry]'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Version=1.0'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Name=Eclipse'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Comment=Eclipse Integrated Development Environment'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Keywords=Programming;Development;IDE;'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	if [[ "true" == "${isChroot}" ]]; then
		echo "Exec=${ECLIPSE_INSTALL_DIR}/eclipse"|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	else
		echo "Exec=${ECLIPSE_INSTALL_DIR}/eclipse -data ${ECLIPSE_WORKSPACE_DIR}"|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	fi
	echo 'Terminal=false'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'X-MultipleArgs=false'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Type=Application'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo "Icon=${ECLIPSE_INSTALL_DIR}/icon.xpm"|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'Categories=Programming;Development;IDE;'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo 'StartupNotify=true'|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;
	echo ''|sudo tee -a "${ECLIPSE_MENU_SHORTCUT}" 2>&1 >/dev/null;

	sudo chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${ECLIPSE_MENU_SHORTCUT}";
	sudo chmod 750 "${ECLIPSE_MENU_SHORTCUT}";
fi
