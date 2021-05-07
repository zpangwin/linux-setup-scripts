#!/bin/bash

# https://linuxconfig.org/how-to-install-adobe-acrobat-reader-on-ubuntu-20-04-focal-fossa-linux
# https://linuxconfig.org/how-to-install-adobe-acrobat-reader-on-ubuntu-18-04-bionic-beaver-linux
# https://www.fosslinux.com/1776/how-to-install-adobe-acrobat-reader-in-ubuntu-and-linux-mint.htm
#	"The last available build for Linux is version 9.5.5"

# get sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

is_installed=$(which acroread 2>/dev/null|wc -l);
if [[ "0" == "${is_installed}" ]]; then
	echo "Enabling the i386 architecture ...";
	sudo dpkg --add-architecture i386 2>/dev/null;

	echo "Updating apt's local cache ...";
	sudo apt-get update -y 2>&1 >/dev/null

	echo "Installing dependencies ...";
	sudo apt-get install -y gdebi-core libxml2:i386 libcanberra-gtk-module:i386 gtk2-engines-murrine:i386 libatk-adaptor:i386;

	mkdir /tmp/acroreader;
	cd /tmp/acroreader;

	echo "Downloading Acrobat Reader DEB file ...";
	wget ftp://ftp.adobe.com/pub/adobe/reader/unix/9.x/9.5.5/enu/AdbeRdr9.5.5-1_i386linux_enu.deb >/dev/null;

	echo "Installing Acrobat Reader from DEB file ...";
	sudo gdebi --non-interactive AdbeRdr9.5.5-1_i386linux_enu.deb >/dev/null;
fi

is_installed=$(which acroread 2>/dev/null|wc -l);
if [[ "0" == "${is_installed}" ]]; then
	echo "ERROR: Install failed; no binary 'acroread' found.";
	exit;
fi

echo "Building out menu shortcuts ...";

HOME_MENU_SHORTCUT="${HOME}/.local/share/applications/acrobat-reader.desktop";
USR_MENU_SHORTCUT="/usr/share/applications/acrobat-reader.desktop";
has_menu_shortcut="false";
if [[ -e "${HOME_MENU_SHORTCUT}" || -e "${USR_MENU_SHORTCUT}" ]]; then
	has_menu_shortcut="true";
fi

if [[ "false" == "${has_menu_shortcut}" ]]; then
	echo '#!/usr/bin/env xdg-open' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo '' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo '[Desktop Entry]' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Version=1.0' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Name=Acrobat Reader' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Comment=Adobe Acrobat Reader' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Keywords=Office;Accessories;' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Exec=/usr/bin/acroread' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Terminal=false' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'X-MultipleArgs=false' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Type=Application' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Icon=acroread' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'Categories=Office;Accessories;' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	echo 'StartupNotify=false' | sudo tee -a "${USR_MENU_SHORTCUT}" >/dev/null;
	sudo chmod 644 "${USR_MENU_SHORTCUT}";
fi
