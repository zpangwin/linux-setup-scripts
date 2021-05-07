#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

isSambaInstalled=$(dnf list installed --cacheonly samba 2>/dev/null|wc -l);
if [[ 0 == $isSambaInstalled ]]; then
	echo "Samba package is not installed. Please make sure package is installed";
	exit;
fi

isSambaServiceStarted=$(systemctl status smb 2>/dev/null|grep -P 'Active:.*active \(running\)');
if [[ 0 == $isSambaServiceStarted ]]; then
	echo "Samba 'smb' service is not running. Please correct and try again";
	exit;
fi

isSambaServiceStarted=$(systemctl status nmb 2>/dev/null|grep -P 'Active:.*active \(running\)');
if [[ 0 == $isSambaServiceStarted ]]; then
	echo "Samba 'nmb' service is not running. Please correct and try again";
	exit;
fi

isSELinuxEnabled=$(sestatus 2>/dev/null|grep -Pci 'SELinux status:\s*enabled');
if [[ 0 == $isSELinuxEnabled ]]; then
	echo "SELinux is not currently enabled. Please make sure it is enabled and try again";
	exit;
fi

sambaUserCount=$(getent passwd 2>/dev/null|grep -Pci 'smb|samba')
if [[ 0 == $sambaUserCount ]]; then
	echo "No samba/smb users defined on system. Please make sure users are created and setup before retrying.";
	exit;
fi

sambaGroupCount=$(getent group 2>/dev/null|grep -Pci '^\w*(smb|samba)\w*:.*:[^,]*(smb|samba)[^,]*')
if [[ 0 == $sambaGroupCount ]]; then
	echo "No samba/smb groups defined on system. Please make sure groups are created and setup before retrying.";
	exit;
fi

if [[ ! -f /etc/samba/smb.conf ]]; then
	echo "File /etc/samba/smb.conf does not exist. Please create it and try again";
	exit;
fi

shareablePathsCount=$(grep -P '^\s*path\s*=\s*/(gaming|media|home)' /etc/samba/smb.conf 2>/dev/null);
if [[ 0 == $shareablePathsCount ]]; then
	echo "File /etc/samba/smb.conf does not have any valid shared paths defined. Please correct and try again";
	exit;
fi

# check that smb.conf interface is correct ...
isBindingByInterface=$(grep -Pc '^\s*interfaces' /etc/samba/smb.conf 2>/dev/null);
if [[ 1 == $isBindingByInterface ]]; then
	configuredInterfaceName=$(grep -P '^\s*interfaces' /etc/samba/smb.conf 2>/dev/null|cut -d= -f2|sed -E 's/\s+/\n/g'|grep '^e.*'|head -1);

	if [[ $configuredInterfaceName =~ ^e.*$ ]]; then
		configuredInterfaceExists=$(ip -4 -o link show 2>/dev/null|grep -Pv 'state DOWN|^\d+: (lo|tun\d+):'|cut -d: -f2|grep -Pc "\\b$configuredInterfaceName\\b");
		if [[ 1 != "$configuredInterfaceExists" ]]; then
			echo "File /etc/samba/smb.conf is using a non-existing nterface: '${configuredInterfaceName}'. Please correct and try again";
			exit;
		fi
	else
		echo "File /etc/samba/smb.conf has a bad interfaces defininition: '${configuredInterfaceName}'. Please correct and try again";
		exit;
	fi
fi

primaryInterfaceName=$(ip -4 -o link show|grep -Pv 'state DOWN|^\d+: (lo|tun\d+):'|cut -d: -f2|sed -E 's/\s+//g');


# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

isSambaAllowedThruFW=$(sudo firewall-cmd --list-all 2>/dev/null|grep -Pci 'services:.*samba');
if [[ 0 == $isSambaAllowedThruFW ]]; then
	echo "Samba is not currently an allowed service on the firewall. Please correct and try again";
	exit;
fi

# set SELinux boolean flags
sudo setsebool -P samba_export_all_ro=1;
sudo setsebool -P samba_export_all_rw=1;
sudo setsebool -P samba_share_fusefs=1;

# process partly based on:
#	https://fedoramagazine.org/fedora-32-simple-local-file-sharing-with-samba/
#	https://www.server-world.info/en/note?os=Fedora_31&p=samba&f=1
#	https://www.tecmint.com/setup-samba-file-sharing-for-linux-windows-clients/
#	https://reticent.net/sharing-an-ntfs-partition-with-samba-and-selinux/
#	https://linux.die.net/man/8/samba_selinux

# capture samba share paths as array and setup se linux perms on them
sambaSharePathsArray=($(grep -P '^\s*path\s*=\s*/' /etc/samba/smb.conf|awk -F'\\s*=\\s*' '{print $2}'|sort -u));
if [[ ! -z "${sambaSharePathsArray[@]}" && ${#sambaSharePathsArray[@]} -ge 1 ]]; then
	for sambaShare in "${sambaSharePathsArray[@]}"; do
		echo "";
		echo "Processing sambaShare: '${sambaShare}'";

		if [[ ! -d "${sambaShare}" ]]; then
			echo "W: Shared path '${sambaShare}' does not exist; skipping...";
			continue;
		fi

		# should return correct filesystem for linux fs's such as ext4. windows filesystems sometimes are returned as "fuseblk" instead of "ntfs"/"fat" though
		isLinuxFilesystemPath=$(df -T "${sambaShare}" 2>/dev/null|tail -1|grep -Pc '^/dev/\w+\s+(ext[234]|btrfs)\s+');
		if [[ 1 != ${isLinuxFilesystemPath} ]]; then
			echo "W: Shared path '${sambaShare}' is not a linux filesystem (and must be handled via fstab options or selinux flags); skipping...";
			echo "Example /etc/fstab entry for ntfs partition with selinux flags:"
			echo "  UUID=<UUID> /mountpoint ntfs-3g defaults,nofail,x-systemd.device-timeout=3s,windows_names,locale=en_US.utf8,uid=1000 \\";
			echo "          0 0 -o context=\"system_u:object_r:samba_share_t:s0\"";
			continue;
		fi

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
fi
