#!/bin/bash

echo "Updating apt's local cache ...";
sudo apt-get update 2>&1 >/dev/null;

echo "Installing conky ...";
sudo apt-get install -y --install-recommends conky;

if [[ ! -e /usr/bin/conky ]]; then
	echo "ERROR: Install failed, please check repo.";
	exit;
fi

HOME_MENU_SHORTCUT="${HOME}/.local/share/applications/conky.desktop";
USR_MENU_SHORTCUT="/usr/share/applications/conky.desktop";
has_menu_shortcut="false";

# check for chroot environment
echo "Checking for chroot environment ...";
if [[ "root" == "${USER}" && "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]; then
	# if chroot, then change "Home" to mean
	# /etc/skel rather than /root
	HOME_MENU_SHORTCUT="/etc/skel/.local/share/applications/conky.desktop";

	# make sure folder exists
	mkdir -p "/etc/skel/.local/share/applications" 2>&1 >/dev/null;
fi

if [[ -e "${HOME_MENU_SHORTCUT}" || -e "${USR_MENU_SHORTCUT}" ]]; then
	has_menu_shortcut="true";
fi

echo "Checking for default conky icon ...";
if [[ ! -e "/usr/share/icons/conky-manager.png" ]]; then
	if [[ ! -e "/usr/share/icons/Mint-Y/apps/256@2x/conky-manager.png" ]]; then
		sudo cp -a "/usr/share/icons/Mint-Y/apps/256@2x/conky-manager.png" "/usr/share/icons/conky-manager.png";
		sudo chmod 644 "/usr/share/icons/conky-manager.png";
	fi
fi

echo "Checking for modern conky icon ...";
if [[ ! -f "/usr/share/icons/conky-logo.png" ]]; then
	currDir=$(pwd);
	tmpDir=$(mktemp -d /tmp/XXXX);
	cd "${tmpDir}";
	wget https://fossies.org/linux/conky/logo/conky-logomark-violet.png >/dev/null;
	if [[ -f "${tmpDir}/conky-logomark-violet.png" ]]; then
		sudo cp -a "${tmpDir}/conky-logomark-violet.png" "/usr/share/icons/conky-logo.png";
		sudo chmod 644 "/usr/share/icons/conky-logo.png";
	fi
	cd "${currDir}";
fi

echo "Checking for system menu ...";
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
	if [[ -f "/usr/share/icons/conky-logo.png" ]]; then
		echo 'Icon=conky-logo' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	else
		echo 'Icon=conky-manager' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	fi
	echo 'Categories=System;Accessories;' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'StartupNotify=true' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	sudo chmod 644 "${USR_MENU_SHORTCUT}";
fi
