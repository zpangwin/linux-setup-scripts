#!/bin/bash

#get sudo prompt out of the way
sudo ls -acl >/dev/null;

echo "";
echo "================================================================";
echo "Fuck caps lock! Disabling that shit...";
echo "================================================================";

SYM_GROUP_NAME="none";

#clear previous options
setxkbmap -layout us -option

#set new option
setxkbmap -layout us -option caps:${SYM_GROUP_NAME};

# Notes:
#------------------------------
# Mint19 - doesn't work:
#------------------------------
#	a) gsettings set org.gnome.desktop.input-sources xkb-options "['caps:${SYM_GROUP_NAME}']";
#	b) https://unix.stackexchange.com/questions/130858/change-the-keyboard-layout-in-lightdm
#		/etc/lightdm/lightdm.conf.d/00-keyboard.conf: [SeatDefaults]\ndisplay-setup-script=x
#		or
#		/etc/lightdm/lightdm.conf.d/00-keyboard.conf: [SeatDefaults]\ngreeter-setup-script=x
#	c) https://wiki.archlinux.org/index.php/LightDM#NumLock_on_by_default
#		/etc/lightdm/lightdm.conf: [Seat:*]\ngreeter-setup-script=xxx
#	d) https://askubuntu.com/a/1050911
#		/etc/lightdm/lightdm.conf.d/99-disable-caps.conf: [Seat:*]\ndisplay-setup-script = x

#------------------------------
# Mint19 - WORKS!!!!
#------------------------------
#	https://unix.stackexchange.com/a/452803
if [[ ! -e "/etc/default/keyboard.orig" ]]; then
	#make a backup if one doesn't already exist
	sudo cp -a /etc/default/keyboard /etc/default/keyboard.orig;
fi
TIMESTAMP=$(date +"%Y%m%d-%H%M%S");
echo "Creating backup at /etc/default/keyboard.bak.$TIMESTAMP ... ";
sudo cp -a /etc/default/keyboard /etc/default/keyboard.bak.$TIMESTAMP;

#make changes
sudo sed -i "s|^\\([ ]*XKBOPTIONS\\).*|\\1=\"caps:${SYM_GROUP_NAME}\"|g" /etc/default/keyboard;

#apply (wont actually take effect until reboot tho)
sudo udevadm trigger --subsystem-match=input --action=change

#tell user to reboot
echo "Changes applied; please reboot for changes to take effect.";
