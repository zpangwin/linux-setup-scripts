#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

if [[ ! -f "${SCRIPT_DIR_PARENT}/functions.sh" ]]; then
    echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
    exit;
fi
. "${SCRIPT_DIR_PARENT}/functions.sh";

# get the sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

# copy script files
sudo cp -a "${SCRIPT_DIR}/usr/bin/pkexec-pince" /usr/bin/pkexec-pince;
sudo cp -a "${SCRIPT_DIR}/usr/share/applications/pince.desktop" /usr/share/applications/pince.desktop;

sudo chown root:root /usr/bin/pkexec-pince;
sudo chown root:root /usr/share/applications/pince.desktop;

sudo chmod 755 /usr/bin/pkexec-pince;
sudo chmod 644 /usr/share/applications/pince.desktop;

# Install policykit exception...
if [[ ! -f /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy ]]; then
	sudo cp -a "${SCRIPT_DIR}/usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy" /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy;
else
	# check if the policy is already defined...
	policy_defined=$(grep 'id="org.freedesktop.policykit.pkexec.run-pince"' /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy|wc -l);
	if [[ "0" == "${policy_defined}" ]]; then
		# make a backup of current policykit config first
		sudo cp -a /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy.$(date +'%Y%m%d%H%M%S').bak;

		# remove the closing tag from current file
		sudo sed -i -E 's/^<\/policyconfig>//g' /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy;

		# copy the <action> tag and new closing tag from file in install folder to actual policykit file
		cat "${SCRIPT_DIR}/usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy"|sed -n '/^.*<action/,$p'|sudo tee --append /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy >/dev/null;
	fi
fi
