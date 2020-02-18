#!/bin/bash

sudo apt update;

sudo apt install -y --install-recommends conky;

if [[ ! -e /usr/bin/conky ]]; then
	echo "ERROR: Install failed, please check repo.";
	exit;
fi

HOME_MENU_SHORTCUT="${HOME}/.local/share/applications/conky.desktop";
USR_MENU_SHORTCUT="/usr/share/applications/conky.desktop";
has_menu_shortcut="false";
if [[ -e "${HOME_MENU_SHORTCUT}" || -e "${USR_MENU_SHORTCUT}" ]]; then
	has_menu_shortcut="true";
fi
if [[ ! -e "/usr/share/icons/conky-manager.png" ]]; then
	if [[ ! -e "/usr/share/icons/Mint-Y/apps/256@2x/conky-manager.png" ]]; then
		sudo cp -a "/usr/share/icons/Mint-Y/apps/256@2x/conky-manager.png" "/usr/share/icons/conky-manager.png";
		sudo chmod 644 "/usr/share/icons/conky-manager.png";
	fi
fi

if [[ "false" == "${has_menu_shortcut}" ]]; then
	echo '#!/usr/bin/env xdg-open' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo '' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo '[Desktop Entry]' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Version=1.0' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Name=Conky' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Comment=Conky System Monitor' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Keywords=System;Accessories;' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Exec=/usr/bin/conky' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Terminal=false' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'X-MultipleArgs=false' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Type=Application' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Icon=/usr/share/icons/conky-manager.png' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Categories=System;Accessories;' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'StartupNotify=true' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	sudo chmod 644 "${USR_MENU_SHORTCUT}";
fi
