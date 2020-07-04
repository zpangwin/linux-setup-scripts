#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

if [[ ! -f "${SCRIPT_DIR}/usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy" ]]; then
    echo "Error: missing required file '${SCRIPT_DIR}/usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy'";
    echo "See 'How to install' section from README";
    exit;
fi

if [[ ! -f "${SCRIPT_DIR}/usr/bin/pkexec-system-config-samba" ]]; then
    echo "Error: missing required file '${SCRIPT_DIR}/usr/bin/pkexec-system-config-samba'";
    echo "See 'How to install' section from README";
    exit;
fi

if [[ ! -f "${SCRIPT_DIR}/usr/share/applications/system-config-samba.desktop" ]]; then
    echo "Error: missing required file '${SCRIPT_DIR}/usr/share/applications/system-config-samba.desktop'";
    echo "See 'How to install' section from README";
    exit;
fi

# get the sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

# 1. install SCS dependencies:
echo "Updating apt's local cache ...";
sudo apt-get update >/dev/null;

echo 'Checking dependencies ...';
is_samba_installed=$(which samba|wc -l);
if [[ "1" != "$is_samba_installed" ]]; then
	# sometimes samba wants to download a new config file. in this case, normally it will prompt you which
	# breaks automation. to avoid this, we are setting variable and additional flags to tell it to fuck off.
	# I opted to choose the NEW files since it is supposed to automatically backup old configs.
	# If you prefer to keep the old ones, then change it to "--force-confold"
	#
	# https://serverfault.com/questions/527789/how-to-automate-changed-config-files-during-apt-get-upgrade-in-ubuntu-12/839563
	# --force-confnew: always install the new version of the configuration file, the current version is kept in a file with the .dpkg-old suffix.
	#
	# cifs-utils and winbind are not strictly required but i tend to include them whenever i install samba
	#
	export DEBIAN_FRONTEND=noninteractive;
	sudo apt-get install -y -o Dpkg::Options::="--force-confnew" cifs-utils samba-common winbind samba;
fi

#====================================================================================================================
# with Ubuntu 20, system-config-samba is no longer available in the central repos
# workaround: manually install deb files from old packages
#	Based on:
#	1. askubuntu user N0rbert demonstrates the approach for fslint (another package that was removed for the same reason)
#
#		https://askubuntu.com/questions/1233710/where-is-fslint-duplicate-file-finder-for-ubuntu-20-04
#		https://askubuntu.com/a/1233818
#		-> this shows download and install of old packages from archive.ubuntu.com
#
#	2. We need to get DEBs for "system-config-samba"; you can google them and find them on "packages.ubuntu.com"
#		google -> ubuntu bionic "system-config-samba"
#		-> first link is "https://packages.ubuntu.com/bionic/system-config-samba"
#			-> scroll to table under "Download python-libuser" and pick "all"
#				-> you can use mirrors here directly
#				OR copy the relative path and find them under http://archive.ubuntu.com/ubuntu/
#			e.g. http://archive.ubuntu.com/ubuntu/pool/universe/s/system-config-samba/
# 			http://archive.ubuntu.com/ubuntu/pool/universe/s/system-config-samba/system-config-samba_1.2.63-0ubuntu6_all.deb
#
#		note: after getting system-config-samba deb, I skipped to step 3 to find "python-libuser" as a dependency
#		google -> ubuntu bionic "python-libuser"
#		-> first link is "https://packages.ubuntu.com/bionic/python-libuser"
#			-> scroll to table under "Download python-libuser" and pick "amd64"
#				-> you can use mirrors here directly
#				OR copy the relative path and find them under http://archive.ubuntu.com/ubuntu/
#
#	3. Use the -I (capital "i", pronounced 'eye') param of dpkg to look at depends.
#
#		$ dpkg -I system-config-samba_1.2.63-0ubuntu6_all.deb|grep -i depends
#			Depends: python, python:any (>= 2.7.5-5~), samba, python-libuser, python-glade2
#
#		-> python and samba are still present in central repo. only the last 2 are needed.
#		-> python-glade2 was already used in the example on askubuntu. Repeat step #2 for python-libuser
#
#		-> Repeat dpkg -I for the other libs; looking specifically for things that start with "python-"
#			as those have been deprecated in ubuntu 20. python-glade2 has a dependency on "python-gtk2"
#			but this is also handled in the example on askubuntu. "python-libuser" doesn't depend on any
#			legacy python plugins; the other stuff is present in the central repo on ubuntu 20.
#====================================================================================================================
startDir=$(pwd);
tmpDir=$(mktemp -d /tmp/XXX);
cd "${tmpDir}";

echo "Download DEB files for system-config-samba and legacy depends ...";
wget http://archive.ubuntu.com/ubuntu/pool/universe/p/pygtk/python-gtk2_2.24.0-6_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/p/pygtk/python-glade2_2.24.0-6_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/libu/libuser/python-libuser_0.62~dfsg-0.1ubuntu2_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/s/system-config-samba/system-config-samba_1.2.63-0ubuntu6_all.deb

# 2. install system-config-samba GUI
echo "Installing system-config-samba ...";
sudo apt-get install ./*.deb

cd "${startDir}";

# 3. Fix issue
echo "Fixing /etc/libuser.conf issue ...";
sudo touch /etc/libuser.conf;

# backup existing (ignore errors if doesn't exist)
sudo mv /usr/share/applications/system-config-samba.desktop /usr/share/applications/system-config-samba.desktop.$(date +'%Y%m%d%H%M%S').bak 2>/dev/null >/dev/null;

# copy script files
echo "Configuring Polkit authentication ...";
sudo cp -a "${SCRIPT_DIR}/usr/bin/pkexec-system-config-samba" /usr/bin/pkexec-system-config-samba;
sudo cp -a "${SCRIPT_DIR}/usr/share/applications/system-config-samba.desktop" /usr/share/applications/system-config-samba.desktop;

# Install policykit exception...
if [[ ! -f /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy ]]; then
	sudo cp -a "${SCRIPT_DIR}/usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy" /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy;
else
	# check if the policy is already defined...
	policy_defined=$(grep 'id="org.freedesktop.policykit.pkexec.run-system-config-samba"' /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy|wc -l);
	if [[ "0" == "${policy_defined}" ]]; then
		# make a backup of current policykit config first
		sudo cp -a /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy.$(date +'%Y%m%d%H%M%S').bak;

		# remove the closing tag from current file
		sudo sed -i -E 's/^<\/policyconfig>//g' /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy;

		# copy the <action> tag and new closing tag from file in install folder to actual policykit file
		cat "${SCRIPT_DIR}/usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy"|sed -n '/^.*<action/,$p'|sudo tee --append /usr/share/polkit-1/actions/org.freedesktop.policykit.pkexec.policy >/dev/null;
	fi
fi

echo "Setting permissions ...";

sudo chown root:root /usr/bin/pkexec-system-config-samba;
sudo chown root:root /usr/share/applications/system-config-samba.desktop;

sudo chmod 755 /usr/bin/pkexec-system-config-samba;
sudo chmod 644 /usr/share/applications/system-config-samba.desktop;

