#!/bin/bash

# get the sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

# 1. install SCS dependencies:
sudo apt update >/dev/null;
is_samba_installed=$(which samba|wc -l);
if [[ "1" != "$is_samba_installed" ]]; then
	sudo apt install -y samba;
fi

# 2. install SCS GUI
sudo apt install -y system-config-samba;

# 3. Fix issue
sudo touch /etc/libuser.conf;

# copy script files
sudo cp -a ./usr/bin/pkexec-system-config-samba /usr/bin/pkexec-system-config-samba;
sudo cp -a ./usr/share/applications/system-config-samba.desktop /usr/share/applications/system-config-samba.desktop;

sudo chown root:root /usr/bin/pkexec-system-config-samba;
sudo chown root:root /usr/share/applications/system-config-samba.desktop;

sudo chmod 755 /usr/bin/pkexec-system-config-samba;
sudo chmod 644 /usr/share/applications/system-config-samba.desktop;

