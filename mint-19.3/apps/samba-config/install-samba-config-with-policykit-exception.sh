#!/bin/bash

# get the sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

# 1. install SCS dependencies:
sudo apt-get update >/dev/null;
is_samba_installed=$(which samba|wc -l);
if [[ "1" != "$is_samba_installed" ]]; then
	sudo apt-get install -y samba;
fi

# 2. install SCS GUI
sudo apt-get install -y system-config-samba;

# 3. Fix issue
sudo touch /etc/libuser.conf;

# copy script files
sudo cp -a ./usr/bin/pkexec-system-config-samba /usr/bin/pkexec-system-config-samba;
sudo cp -a ./usr/share/applications/system-config-samba.desktop /usr/share/applications/system-config-samba.desktop;

# Install policykit exception...
if [[ ! -f /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy ]]; then
	sudo cp -a ./usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy;
else
	# check if the policy is already defined...
	policy_defined=$(grep 'id="org.freedesktop.policykit.pkexec.run-system-config-samba"' /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy|wc -l);
	if [[ "0" == "${policy_defined}" ]]; then
		# make a backup of current policykit config first
		sudo cp -a /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy.$(date +'%Y%m%d%H%M%S').bak;

		# remove the closing tag from current file
		sudo sed -i -E 's/^<\/policyconfig>//g' /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy;

		# copy the <action> tag and new closing tag from file in install folder to actual policykit file
		cat ./usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy|sed -n '/^.*<action/,$p'|sudo tee --append /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy >/dev/null;
	fi
fi

sudo chown root:root /usr/bin/pkexec-system-config-samba;
sudo chown root:root /usr/share/applications/system-config-samba.desktop;

sudo chmod 755 /usr/bin/pkexec-system-config-samba;
sudo chmod 644 /usr/share/applications/system-config-samba.desktop;

