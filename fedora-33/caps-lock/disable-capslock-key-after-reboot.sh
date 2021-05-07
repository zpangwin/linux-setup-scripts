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

# There are several different methodologies for turning off capslock and there doesn't seem
# to be a single way that works consistently across all (or even most) distros. This will
# attempt to handle as many variations as possible...

TIMESTAMP=$(date +"%Y%m%d-%H%M%S");

if [[ -z "$SYM_GROUP_NAME" ]]; then
	echo "E: Empy XKB group name. Aborting script...";
	exit;
fi

# See https://wiki.archlinux.org/index.php/Xorg/Keyboard_configuration

if [[ -f /etc/X11/xorg.conf.d/00-keyboard.conf ]]; then
	# Make a backups
	if [[ ! -f "/etc/X11/xorg.conf.d/00-keyboard.conf.orig" ]]; then
		# If no 'orig' file exists, make one of that first...
		sudo cp -a /etc/X11/xorg.conf.d/00-keyboard.conf /etc/X11/xorg.conf.d/00-keyboard.conf.orig;
	fi

	# Make a timestamped backup regardless of orig existing or not
	echo "Creating backup at /etc/X11/xorg.conf.d/00-keyboard.conf.$TIMESTAMP.bak ... ";
	sudo cp -a /etc/X11/xorg.conf.d/00-keyboard.conf /etc/X11/xorg.conf.d/00-keyboard.conf.${TIMESTAMP}.bak;

	# ===================================================================
	# !!! IMPORTANT !
	#
	# "It's probably wise not to edit this file manually. Use localectl(1)
	# to instruct systemd-localed to update it."
	#
	# (read the file should be safe though)
	# ===================================================================
	XKB_OPTIONS='';
	hasXKBOPTIONS=$(grep -Pc 'Option\s+"XkbOptions".*' /etc/X11/xorg.conf.d/00-keyboard.conf);
	if [[ '0' != "$hasXKBOPTIONS" ]]; then
		XKB_OPTIONS=$(grep -P 'Option\s+"XkbOptions".*' /etc/X11/xorg.conf.d/00-keyboard.conf|sed -E 's/^\s+Option\s+"XkbOptions"\s+"|"\s*$//g');

		# if existing options already had something for 'cap:x' then remove it
		# remove ,caps:x in the middle and end positions
		XKB_OPTIONS=$(echo "$XKB_OPTIONS"|sed -E 's/,caps:[^,"]+//g');

		# remove leading caps:x, as well as caps:x by itself
		XKB_OPTIONS=$(echo "$XKB_OPTIONS"|sed -E 's/^caps:[^,"]+,?//g');
	fi

	if [[ -z "$XKB_OPTIONS" ]]; then
		XKB_OPTIONS="caps:${SYM_GROUP_NAME}";
	else
		XKB_OPTIONS="${XKB_OPTIONS},caps:${SYM_GROUP_NAME}";
	fi

	# See
	# https://wiki.archlinux.org/index.php/Xorg/Keyboard_configuration
	# https://superuser.com/questions/720538/multiple-xkboptions-in-xorg-conf
	# https://www.linuxsecrets.com/archlinux-wiki/wiki.archlinux.org/index.php/Keyboard_configuration_in_Xorg.html
	# https://unix.stackexchange.com/questions/43976/list-all-valid-kbd-layouts-variants-and-toggle-options-to-use-with-setxkbmap
	#
	# To view valid (predefined) configurations for capslock, run:
	#	localectl list-x11-keymap-options|grep ^caps:
	if [[ '1' != "$(localectl list-x11-keymap-options|grep ^caps:|grep -Pc "^caps:${SYM_GROUP_NAME}\$")" ]]; then
		echo "E: No XKB group name '${SYM_GROUP_NAME}' defined on the system.";
		echo "See: localectl list-x11-keymap-options  ";
	else
		XKB_LAYOUT=$(grep XkbLayout /etc/X11/xorg.conf.d/00-keyboard.conf|sed -E 's/^\s+Option\s+"XkbLayout"\s+"|"\s*$//g');
		if [[ -z "$XKB_LAYOUT" ]]; then
			XKB_LAYOUT='us';
		fi

		XKB_MODEL=$(grep XkbModel /etc/X11/xorg.conf.d/00-keyboard.conf|sed -E 's/^\s+Option\s+"XkbModel"\s+"|"\s*$//g');

		XKB_VARIANT=$(grep XkbVariant /etc/X11/xorg.conf.d/00-keyboard.conf|sed -E 's/^\s+Option\s+"XkbVariant"\s+"|"\s*$//g');

		sudo localectl set-x11-keymap "$XKB_LAYOUT" "$XKB_MODEL" "$XKB_VARIANT" "$XKB_OPTIONS"
	fi

	isSELinuxEnabled=$(sestatus 2>/dev/null|grep -Pci 'SELinux status:\s*enabled');
	if [[ 1 == $isSELinuxEnabled && 1 == $(which restorecon 2>/dev/null|wc -l) ]]; then
		echo "Restoring SELinux Filecontext...";
		sudo restorecon /etc/X11/xorg.conf.d/00-keyboard.conf*;
		echo "SELinux filecontext restored.";
	fi
fi


# This approach was working as of Mint 19.3 but not for Fedora-33
if [[ ! -f /etc/default/keyboard ]]; then
	# if the file doesn't exist at all, then create on with some default values (based on modified presets from LM19)

	echo '# KEYBOARD CONFIGURATION FILE'			| sudo tee -a /etc/default/keyboard >/dev/null;
	echo ''											| sudo tee -a /etc/default/keyboard >/dev/null;
	echo '# Consult the keyboard(5) manual page.'	| sudo tee -a /etc/default/keyboard >/dev/null;
	echo ''											| sudo tee -a /etc/default/keyboard >/dev/null;
	echo 'XKBMODEL="pc105"'							| sudo tee -a /etc/default/keyboard >/dev/null;
	echo 'XKBLAYOUT="us"'							| sudo tee -a /etc/default/keyboard >/dev/null;
	echo 'XKBVARIANT=""'							| sudo tee -a /etc/default/keyboard >/dev/null;
	echo "XKBOPTIONS=\"caps:${SYM_GROUP_NAME}\""	| sudo tee -a /etc/default/keyboard >/dev/null;
	echo ''											| sudo tee -a /etc/default/keyboard >/dev/null;
	echo 'BACKSPACE="guess"'						| sudo tee -a /etc/default/keyboard >/dev/null;
	echo ''											| sudo tee -a /etc/default/keyboard >/dev/null;
	echo ''											| sudo tee -a /etc/default/keyboard >/dev/null;

	sudo chmod 644 /etc/default/keyboard;

	isSELinuxEnabled=$(sestatus 2>/dev/null|grep -Pci 'SELinux status:\s*enabled');
	if [[ 1 == $isSELinuxEnabled && 1 == $(which restorecon 2>/dev/null|wc -l) ]]; then
		echo "Restoring SELinux Filecontext...";
		sudo restorecon /etc/default/keyboard*;
		echo "SELinux filecontext restored.";
	fi

else
	# Make a backups
	if [[ ! -f "/etc/default/keyboard.orig" ]]; then
		# If no 'orig' file exists, make one of that first...
		sudo cp -a /etc/default/keyboard /etc/default/keyboard.orig;
	fi

	# Make a timestamped backup regardless of orig existing or not
	echo "Creating backup at /etc/default/keyboard.$TIMESTAMP.bak ... ";
	sudo cp -a /etc/default/keyboard /etc/default/keyboard.${TIMESTAMP}.bak;

	hasXKBOPTIONS=$(grep -c XKBOPTIONS /etc/default/keyboard);
	if [[ '0' == "$hasXKBOPTIONS" ]]; then
		# append to file
		# https://unix.stackexchange.com/a/452803
		echo "XKBOPTIONS=\"caps:${SYM_GROUP_NAME}\"" | sudo tee -a /etc/default/keyboard >/dev/null;
	else
		hasExistingCapsOption=$(grep -Pc '^\s*XKBOPTIONS\s*=.*caps:.*' /etc/default/keyboard);

		if [[ '0' == "$hasXKBOPTIONS" ]]; then
			# alter line to remove any existing caps lock option (if multiple values, should be comma-delimited)
			# per https://askubuntu.com/questions/950020/setting-multiple-options-in-etc-default-keyboard
			# and https://wiki.archlinux.org/index.php/Xorg/Keyboard_configuration

			# remove ,caps:x in the middle and end positions
			sudo sed -Ei 's/^(\s*XKBOPTIONS\s*=.*),caps:[^,"]+/\1/g' /etc/default/keyboard;

			# remove leading caps:x, as well as caps:x by itself
			sudo sed -Ei 's/^(\s*XKBOPTIONS\s*=[\s"]*)caps:[^,"]+,?/\1/g' /etc/default/keyboard;
		fi

		# if other options are present, then append 'caps:x' to the end
		sudo sed -Ei "s/^\\s*(XKBOPTIONS)\\s*=\\s*\"?(\w[^\"]*)\"?\s*$/\1=\"\2,caps:${SYM_GROUP_NAME}\"/g" /etc/default/keyboard;

		# but if there is an empty value, then just set it as the whole string
		sudo sed -Ei "s/^\\s*(XKBOPTIONS)\\s*=\\s*\"?\"?\s*$/\1=\"caps:${SYM_GROUP_NAME}\"/g" /etc/default/keyboard;
	fi

	isSELinuxEnabled=$(sestatus 2>/dev/null|grep -Pci 'SELinux status:\s*enabled');
	if [[ 1 == $isSELinuxEnabled && 1 == $(which restorecon 2>/dev/null|wc -l) ]]; then
		echo "Restoring SELinux Filecontext...";
		sudo restorecon /etc/default/keyboard*;
		echo "SELinux filecontext restored.";
	fi
fi

#apply (wont actually take effect until reboot tho)
sudo udevadm trigger --subsystem-match=input --action=change

#tell user to reboot
echo "Changes applied; please reboot for changes to take effect.";
