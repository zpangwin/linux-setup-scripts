#!/bin/bash

# get the sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

# copy script files
sudo cp -a ./usr/bin/pkexec-pince /usr/bin/pkexec-pince;
sudo cp -a ./usr/share/applications/pince.desktop /usr/share/applications/pince.desktop;

# Install policykit exception...
if [[ ! -f /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy ]]; then
	sudo cp -a ./usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy;
else
	# check if the policy is already defined...
	policy_defined=$(grep 'id="org.freedesktop.policykit.pkexec.run-pince"' /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy|wc -l);
	if [[ "0" == "${policy_defined}" ]]; then
		# make a backup of current policykit config first
		sudo cp -a /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy.$(date +'%Y%m%d%H%M%S').bak;

		# remove the closing tag from current file
		sudo sed -i -E 's/^<\/policyconfig>//g' /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy;

		# copy the <action> tag and new closing tag from file in install folder to actual policykit file
		cat ./usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy|sed -n '/^.*<action/,$p'|sudo tee --append /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy >/dev/null;
	fi
fi

sudo chown root:root /usr/bin/pkexec-pince;
sudo chown root:root /usr/share/applications/pince.desktop;

sudo chmod 755 /usr/bin/pkexec-pince;
sudo chmod 644 /usr/share/applications/pince.desktop;

