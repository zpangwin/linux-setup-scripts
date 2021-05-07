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

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

# process partly based on:
#	https://fedoramagazine.org/fedora-32-simple-local-file-sharing-with-samba/
#	https://www.server-world.info/en/note?os=Fedora_31&p=samba&f=1
#
echo ''
echo 'Installing package ...';
sudo dnf install -y samba;

# create backups
if [[ -f /etc/samba/smb.conf ]]; then
	echo ''
	echo 'Creating backups ...';
	test ! -f /etc/samba/smb.conf.orig && sudo cp -a /etc/samba/smb.conf /etc/samba/smb.conf.orig;
	sudo cp -a /etc/samba/smb.conf /etc/samba/smb.conf-$(date +'%Y%m%d%H%M%S').bak;
elif [[ ! -d /etc/samba ]]; then
	sudo mkdir -m 0644 /etc/samba;
fi

# if custom smb.conf is present, then copy it to system config
if [[ -f "$SCRIPT_DIR/etc/samba/smb.conf" ]]; then
	echo ''
	echo 'Copying custom config ...';
	sudo -a cp "$SCRIPT_DIR/etc/samba/smb.conf" /etc/samba/smb.conf;
	sudo chown root:root /etc/samba/smb.conf;
	sudo chmod 644 root:root /etc/samba/smb.conf;
fi

if [[ -f /etc/samba/smb.conf ]]; then
	# check that smb.conf interface is correct ...
	isBindingByInterface=$(grep -Pc '^\s*interfaces' /etc/samba/smb.conf 2>/dev/null);
	if [[ '1' == "$isBindingByInterface" ]]; then
		echo ''
		echo 'Checking for smb interfaces  ...';
		configuredInterfaceName=$(grep -P '^\s*interfaces' /etc/samba/smb.conf 2>/dev/null|cut -d= -f2|sed -E 's/\s+/\n/g'|grep 'e.*'|head -1);

		if [[ $configuredInterfaceName =~ ^e.*$ ]]; then
			echo 'Confirming smb interface ...';
			configuredInterfaceExists=$(ip -4 -o link show|grep -Pv 'state DOWN|^\d+: (lo|tun\d+):'|cut -d: -f2|grep -Pc "\\b$configuredInterfaceName\\b");

			if [[ '1' != "$configuredInterfaceExists" ]]; then
				primaryInterfaceName=$(ip -4 -o link show|grep -Pv 'state DOWN|^\d+: (lo|tun\d+):'|cut -d: -f2|sed -E 's/\s+//g');

				if [[ $primaryInterfaceName =~ ^e.*$ ]]; then
					echo "Correcting smb.conf interface '$configuredInterfaceName' to '$primaryInterfaceName' ...";
					sudo sed -Ei "s/^(\s*interfaces\s*=.*) $configuredInterfaceName( .*$|$)/\1 $primaryInterfaceName/g" /etc/samba/smb.conf;
				fi
			fi

		fi
	fi

	# capture samba share paths as array and setup se linux perms on them
	sambaSharePathsArray=($(grep -P '^\s*path\s*=\s*/' /etc/samba/smb.conf|awk -F'\\s*=\\s*' '{print $2}'|sort -u));
	if [[ ! -z "${sambaSharePathsArray[@]}" && ${#sambaSharePathsArray[@]} -ge 1 ]]; then
		echo ''
		echo 'Attempting to add SELinux perms for regular smb shares ...';
		#	https://www.tecmint.com/setup-samba-file-sharing-for-linux-windows-clients/
		#	https://reticent.net/sharing-an-ntfs-partition-with-samba-and-selinux/
		#		"samba_export_all_ro / samba_export_all_rw would allow Samba to access any and all system folders/files, not just the NTFS shares."
		#		"samba_share_fusefs" allow Samba to share with FUSE

		sudo setsebool -P samba_export_all_ro=1 samba_export_all_rw=1;
		sudo setsebool -P samba_share_fusefs=1;

		for sambaShare in "${sambaSharePathsArray[@]}"; do
			echo "sambaShare in array is '$sambaShare'";

			# https://www.tecmint.com/setup-samba-file-sharing-for-linux-windows-clients/
			# https://ask.fedoraproject.org/t/how-to-setup-samba-on-fedora-the-easy-way/2551/19
			# https://linux.die.net/man/8/samba_selinux

			sudo semanage fcontext --add --type "samba_share_t" "${sambaShare}(/.*)?";
			# if you later need to remove the folder from this list, you can manually run:
			# 		sambaShare=/path-to-be-removed-from-selinux-whitelist
			#		sudo semanage fcontext --delete --type "samba_share_t" "${sambaShare}(/.*)?";

			sudo restorecon -R "${sambaShare}";

			# to confirm this context was set correctly, you can run
			#	ls -ldZ folder/
			# see:
			# https://www.linuxquestions.org/questions/linux-server-73/how-to-share-ntfs-partition-to-other-computers-using-samba-919827/
		done


		# https://linux.die.net/man/8/samba_selinux
		#
		#echo ''
		#echo 'Attempting to add SELinux perms for smb home shares ...';
		#sudo setsebool -P samba_enable_home_dirs on;
		# => this is only useful if using the samba home directories feature. from setsebool man page:
		#
		#	setsebool -P samba_create_home_dirs 1
		#
		#	If you want to allow samba to share users home directories, you must turn on the
		#	samba_enable_home_dirs boolean.
		#
	fi
fi

# add fw rules
# https://www.tecmint.com/setup-samba-file-sharing-for-linux-windows-clients/
# https://www.linuxjournal.com/content/understanding-firewalld-multi-zone-configurations
#	=> for example, samba rather than UDP ports 137 and 138 and TCP ports 139 and 445.
#
echo ''
echo 'Adding firewall rules ...';
sudo firewall-cmd --add-service=samba --permanent;
sudo firewall-cmd --reload;


#
#	https://ask.fedoraproject.org/t/how-to-setup-samba-on-fedora-the-easy-way/2551/4
#
#firewall-cmd --permanent --zone=public --add-port=139/tcp
#firewall-cmd --permanent --zone=public --add-port=445/tcp

# enable service
echo ''
echo 'Enabling and starting smb service ...';
sudo systemctl enable smb;
sudo systemctl start smb;

echo ''
echo 'Enabling and starting nmb service ...';
sudo systemctl enable nmb;
sudo systemctl start nmb;
