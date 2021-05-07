#!/bin/bash

#get sudo prompt out of the way
sudo ls -acl >/dev/null;

echo "";
echo "================================================================";
echo "Restoring default caps lock settings ...";
echo "================================================================";

#clear previous options
setxkbmap -layout us -option

TIMESTAMP=$(date +"%Y%m%d-%H%M%S");

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

	# See
	# https://wiki.archlinux.org/index.php/Xorg/Keyboard_configuration
	# https://superuser.com/questions/720538/multiple-xkboptions-in-xorg-conf
	# https://www.linuxsecrets.com/archlinux-wiki/wiki.archlinux.org/index.php/Keyboard_configuration_in_Xorg.html
	# https://unix.stackexchange.com/questions/43976/list-all-valid-kbd-layouts-variants-and-toggle-options-to-use-with-setxkbmap
	#
	# To view valid (predefined) configurations for capslock, run:
	#	localectl list-x11-keymap-options|grep ^caps:

	XKB_LAYOUT=$(grep XkbLayout /etc/X11/xorg.conf.d/00-keyboard.conf|sed -E 's/^\s+Option\s+"XkbLayout"\s+"|"\s*$//g');
	if [[ -z "$XKB_LAYOUT" ]]; then
		XKB_LAYOUT='us';
	fi

	XKB_MODEL=$(grep XkbModel /etc/X11/xorg.conf.d/00-keyboard.conf|sed -E 's/^\s+Option\s+"XkbModel"\s+"|"\s*$//g');

	XKB_VARIANT=$(grep XkbVariant /etc/X11/xorg.conf.d/00-keyboard.conf|sed -E 's/^\s+Option\s+"XkbVariant"\s+"|"\s*$//g');

	sudo localectl set-x11-keymap "$XKB_LAYOUT" "$XKB_MODEL" "$XKB_VARIANT" "$XKB_OPTIONS"

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
	echo "XKBOPTIONS=\"\""							| sudo tee -a /etc/default/keyboard >/dev/null;
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
		echo "XKBOPTIONS=\"\"" | sudo tee -a /etc/default/keyboard >/dev/null;
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
