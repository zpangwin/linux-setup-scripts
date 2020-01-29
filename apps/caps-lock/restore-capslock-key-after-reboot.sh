#!/bin/bash

#clear previous options
setxkbmap -layout us -option

if [[ -e /etc/default/keyboard.orig ]]; then
    echo "Restoring backup from /etc/default/keyboard.orig ... ";
	sudo cp -a /etc/default/keyboard.orig /etc/default/keyboard;
else
    echo "ERROR: No backup found at /etc/default/keyboard.orig ... ";
    echo "Please resolve manually";
    exit;
fi

#apply (wont actually take effect until reboot tho)
sudo udevadm trigger --subsystem-match=input --action=change

#tell user to reboot
echo "Changes applied; please reboot for changes to take effect.";

