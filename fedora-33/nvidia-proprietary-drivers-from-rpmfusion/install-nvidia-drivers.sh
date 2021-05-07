#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")";

if [[ "root" == "${USER}" && "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]; then
	echo "E: Detected chroot environment. This should only be installed on bare-metal machines.";
	exit -1;
fi

hasInxi=0;
if [[ 1 == $(which inxi 2>/dev/null|wc -l) ]]; then
	hasInxi=1;
fi

hasLspci=0;
if [[ 1 == $(which lspci 2>/dev/null|wc -l) ]]; then
	hasLspci=1;
fi

hasNvidiaCard=0;
if [[ 1 == ${hasInxi} && 0 != $(inxi -G|grep -Pic 'NVIDIA|GeForce') ]]; then
	hasNvidiaCard=1;

elif [[ 1 == ${hasLspci} && 0 != $(lspci -vnn|grep -Pic 'VGA.*(NVIDIA|GeForce)') ]]; then
	hasNvidiaCard=1;
fi

if [[ 1 != ${hasNvidiaCard} ]]; then
	echo "E: No NVIDIA card detected. This should only be installed on when NVIDIA graphics cards are present.";
	echo "If you feel this message is mistaken, then install either inxi or lspci and try again.";
	exit -1;
fi

# check if nvidia driver is already installed
isNvidiaDriverAlreadyInstalled=0
if [[ 0 != $(dnf list installed --nogpgcheck --cacheonly --assumeno --quiet nvidia-driver* 2>/dev/null|grep -v "^Installed Packages") ]]; then
	# it is absolutely installed, per dpkg
	isNvidiaDriverAlreadyInstalled=1

elif [[ 1 == ${hasInxi} && 0 != $(inxi -G|inxi -G|grep -Pic 'driver:\s+nvidia') ]]; then
	# probably this block should not ever be reached unless the package name format changes
	# or is different for some certain setups.
	isNvidiaDriverAlreadyInstalled=1

elif [[ 1 == ${hasInxi} && 0 != $(inxi -G|inxi -G|grep -Pic 'driver:\s+nouveau') ]]; then
	# between no positive from dpkg and it definitively having nouveau driver, it is probably not installed
	# if it was installed without rebooting it might not be detected but also shouldn't cause
	# any problems if the same commands were issued again (package manager won't reinstall if already there)
	isNvidiaDriverAlreadyInstalled=0

elif [[ 1 == $(which lshw 2>/dev/null|wc -l) && 0 != $(sudo lshw -class video 2>/dev/null|grep -ic 'driver=nvidia') ]]; then
	isNvidiaDriverAlreadyInstalled=1;

elif [[ 1 == $(which lshw 2>/dev/null|wc -l) && 0 != $(sudo lshw -class video 2>/dev/null|grep -ic 'driver=nouveau') ]]; then
	isNvidiaDriverAlreadyInstalled=0;

else
	# if we went through all that and couldn't figure it out then assume it is not installed
	# it shouldn't cause any problems if the same commands were issued again as the
	# package manager won't reinstall if already there
	isNvidiaDriverAlreadyInstalled=0
fi

if [[ 1 == ${isNvidiaDriverAlreadyInstalled} ]]; then
	echo "E: Detected existing NVIDIA driver install. Driver is already installed; nothing to do.";
	exit 0;
fi

# determine if etckeeper is installed
if [[ -z "${IS_ETC_KEEPER_INSTALLED}" ]]; then
	IS_ETC_KEEPER_INSTALLED=0;
	etcKeeperBin="$(which etckeeper 2>/dev/null)";
	if [[ '' != "${etcKeeperBin}" && -f "${etcKeeperBin}" && -x "${etcKeeperBin}" ]]; then
	    IS_ETC_KEEPER_INSTALLED=1;
	fi
fi

if [[ -z "${IS_TIMESHIFT_INSTALLED}" ]]; then
	IS_TIMESHIFT_INSTALLED=$(which timeshift 2>/dev/null|wc -l);
fi

if [[ -z "${IS_TIMESHIFT_INSTALLED_AND_CONFIGURED}" ]]; then
	IS_TIMESHIFT_INSTALLED_AND_CONFIGURED=0;
fi

if [[ 1 != ${IS_TIMESHIFT_INSTALLED_AND_CONFIGURED} && 1 == ${IS_TIMESHIFT_INSTALLED} ]]; then
	hasValidUUID=0
	primaryFilesystemUUID=$(grep -P '^UUID.*\s/\s.*' /etc/fstab|gawk -F'\\s+' '{print $1}'|cut -d= -f2);
	if [[ '' != "${primaryFilesystemUUID}" && $primaryFilesystemUUID =~ ^[a-fA-F0-9]{8}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{12}$ ]]; then
		hasValidUUID=1;
	else
		echo "W: Unable to detect primary filesystem from /etc/fstab. Cannot verify timeshift configuration.";
	fi

	hasUUIDCorrectlyConfigured=0;
	hasExclusionsCorrectlyConfigured=0;
	timeshiftJson=''

	if [[ 1 == ${hasValidUUID} ]]; then
		if [[ 0 == $(which jq 2>/dev/null|wc -l) ]]; then
			echo "W: Package jq not installed. Unable to check if timeshift excludes are configured correctly.";

		elif [[ -f /etc/timeshift.json && -s /etc/timeshift.json ]]; then
			timeshiftJson='/etc/timeshift.json';
		fi
	fi

	if [[ 1 == ${hasValidUUID} && '' != "${timeshiftJson}" ]]; then
		# check for a strictly formatted unix-style UUID
		if [[ 1 != $(grep -Pc '"backup_device_uuid"\s*:\s*"[a-fA-F0-9]{8}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{12}"' "${timeshiftJson}" 2>/dev/null) ]]; then
			echo "";
			if [[	0 == $(grep -c '"backup_device_uuid"' "${timeshiftJson}" 2>/dev/null) || \
					0 != $(grep -Pc '"backup_device_uuid"\s*:\s*""' "${timeshiftJson}" 2>/dev/null) ]]; then
				echo "W: timeshift has no UUID configured for \"backup_device_uuid\".";
			else
				echo "W: timeshift has no valid UUID configured for \"backup_device_uuid\".";
			fi
			echo "   This field should contain the UUID of the HDD where timeshift backups";
			echo "   will be saved. It is recommended to set this to the primary drive's UUID:";
			echo "     ${primaryFilesystemUUID}";
			echo "";
			echo "   The target device must be formatted with a linux-based filesystem.";
			echo "";

		else
			# if exactly one match was returned for the strictly formatted unix-style UUID check
			# then confirm if it matches the primary drive's UUID => automatical pass
			#	if it does not match any UUIDs on the system => automatic fail
			#	if it matches an unsupported filesystem type like ntfs => automatic fail
			#	if it matches the filesystem of a different linux install => automatic fail
			#	=> is this sufficient to allow passing? might need to also exclude network drives,
			#	drives with limited space, drives that contain smart errors, etc
			if [[ 1 != $(grep -Pc "\"backup_device_uuid\"\s*:\s*\"${primaryFilesystemUUID}\"" "${timeshiftJson}" 2>/dev/null) ]]; then
				hasUUIDCorrectlyConfigured=1;

			else
				isDefinedInFstab=0;
				isValidLinuxFilesystem=0;
				fstabMountPount=''
				configuredUUID=$(grep -P '"backup_device_uuid"' "${timeshiftJson}" 2>/dev/null|sed -E 's/^\s*"backup_device_uuid"\s*:\s*"([^"]+)",?\s*/\1/g');

				# eliminate non-local, non-existing, and non-supported filesystems
				if [[ '' != "${configuredUUID}" ]]; then
					# https://askubuntu.com/questions/750743/change-backup-directory-in-timeshift
					#	The hard drive you want to use as a backup device must have one of the following filesystems:
					#		ext2/ext3/ext4/reiserfs/reiser4/xfs/jfs/btrfs/luks
					#
					#	e.g. matching the following regex:
					#		btrfs|ext[234]|reiser4|reiserfs|[jx]fs|luks
					isValidLinuxFilesystem=$(lsblk -f 2>/dev/null|grep -Pc "^.{1,2}sd\\w+\\s+(btrfs|ext[234]|reiser4|reiserfs|[jx]fs|luks)\\b.*${configuredUUID}");
				fi

				# eliminate unmapped/unmounted filesystems - if timeshift can't save to them, then they're invalid
				if [[ 1 == ${isValidLinuxFilesystem} ]]; then
					# note: '|[,\s]ro\b|' is used intentionally instead of '|\bro\b|' to avoid exclduing "errors=remount-ro"
					isDefinedInFstab=$(grep -P "^UUID=" /etc/fstab|grep -Pv 'noauto|[,\s]ro\b|ntfs'|grep -Pc "^UUID=${configuredUUID}");
				fi
				if [[ 1 == ${isValidLinuxFilesystem} && 1 == ${isDefinedInFstab} ]]; then
					# note: '|[,\s]ro\b|' is used intentionally instead of '|\bro\b|' to avoid exclduing "errors=remount-ro"
					fstabMountPount=$(grep -P "^UUID=" /etc/fstab|grep -Pv 'noauto|[,\s]ro\b|ntfs'|grep -P "^UUID=${configuredUUID}"|gawk -F'\\s+' '{print $2}');
				fi

				if [[ -d "${fstabMountPount}" && ! -d "${fstabMountPount}/boot" ]]; then
					hasUUIDCorrectlyConfigured=1;
				fi
			fi
			# end matched strict UUID format
		fi
		# end conditional IF/ELSE block based on strict UUID format matching

		# this checks that the entire /home folder (not just /home/$USER) is EXCLUDED
		# and the the entire /root folder is INCLUDED (indicated the "+" symbol)
		if [[ 2 == $(jq '.exclude' "${timeshiftJson}" 2>/dev/null|grep -Pc '"/home/\*\*"|"\+ /root/\*\*"') ]]; then
			hasExclusionsCorrectlyConfigured=1;

		elif [[ 0 == $(jq '.exclude' "${timeshiftJson}" 2>/dev/null|grep -Pc '"/home/\*\*"|"\+ /root/\*\*"') ]]; then
			echo "";
			echo "W: No timeshift exclusions found. Expected:";
			echo "  1. The entire /home folder should be excluded; not just /home/$USER"
			echo "     Otherewise other user's files could be lost or reverted after a restore.";
			echo "";
			echo "  2. The entire /root folder should be included";
			echo "     Otherwise a bad /root config could persist after a restore.";
			echo "";

		elif [[ 1 != $(jq '.exclude' "${timeshiftJson}" 2>/dev/null|grep -Pc '"/home/\*\*"') ]]; then
			echo "";
			echo "W: timeshift exclusions are not excluding the entire /home folder.";
			echo "This could result in other user's files being lost or reverted after a restore.";
			echo "";

		elif [[ 1 != $(jq '.exclude' "${timeshiftJson}" 2>/dev/null|grep -Pc '"\+ /root/\*\*"') ]]; then
			echo "";
			echo "W: timeshift exclusions are not including the /root folder";
			echo "This could result in a bad /root config persisting after a restore.";
			echo "";
		fi
		# end exclude section check

		# if both the UUID and the exclude section were valid then consider it as correctly
		# configured for the purpose of being able to create timeshift backups via a script
		if [[ 1 == ${hasUUIDCorrectlyConfigured} && 1 == ${hasExclusionsCorrectlyConfigured} ]]; then
			export IS_TIMESHIFT_INSTALLED_AND_CONFIGURED=1;
		fi
	fi
	# end handling for primary filesystem has valid UUID + timeshift.json exists
fi

if [[ 1 != ${IS_TIMESHIFT_INSTALLED_AND_CONFIGURED} ]]; then
	if [[ 1 != ${IS_TIMESHIFT_INSTALLED} ]]; then
		echo "E: Please install and configure timeshift before continuing.";
		exit -1;

	else
		echo "E: Please configure timeshift before continuing.";
		exit -1;
	fi
fi

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

if [[ 1 == ${IS_TIMESHIFT_INSTALLED_AND_CONFIGURED} ]]; then
	# --tags D stands for Daily Backup
	# --tags W stands for Weekly Backup
	# --tags M stands for Monthly Backup
	# --tags O stands for On-demand Backup
	sudo timeshift --create --comments "Before installing NVIDIA drivers via RPMFusion (${SCRIPT_NAME})." --tags O;
fi

# enable rpm fusion if it hasn't been already...
if [[ ! -f /etc/yum.repos.d/rpmfusion-free.repo ]]; then
	if [[ 1 == ${IS_ETC_KEEPER_INSTALLED} ]]; then
	    sudo etckeeper commit "${SCRIPT_NAME}: before installing rpmfusion (free)" 2>&1 >/dev/null;
	fi

	echo "Configuring RPMFusion (free) repo ...";
	sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm;

	if [[ 1 == ${IS_ETC_KEEPER_INSTALLED} ]]; then
	    sudo etckeeper commit "${SCRIPT_NAME}: after installing rpmfusion (free)" 2>&1 >/dev/null;
	fi
fi
if [[ ! -f /etc/yum.repos.d/rpmfusion-nonfree.repo ]]; then
	if [[ 1 == ${IS_ETC_KEEPER_INSTALLED} ]]; then
	    sudo etckeeper commit "${SCRIPT_NAME}: before installing rpmfusion (non-free)" 2>&1 >/dev/null;
	fi

	echo "Configuring RPMFusion (non-free) repo ...";
	sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm;

	if [[ 1 == ${IS_ETC_KEEPER_INSTALLED} ]]; then
	    sudo etckeeper commit "${SCRIPT_NAME}: after installing rpmfusion (non-free)" 2>&1 >/dev/null;
	fi
fi

if [[ 1 == ${IS_ETC_KEEPER_INSTALLED} ]]; then
    sudo etckeeper commit "${SCRIPT_NAME}: before running dnf update" 2>&1 >/dev/null;
fi

echo 'Running sudo dnf update -y ...'
sudo dnf update -y;

# This script will install using the RPMFusion method:
#	https://www.fosslinux.com/44725/how-to-install-nvidia-drivers-on-fedora-workstation.htm
#	https://itsfoss.com/install-nvidia-drivers-fedora/
#	https://linuxconfig.org/how-to-install-the-nvidia-drivers-on-fedora-32

# use the following links only for *DETECTING* nvidia versions:
# (the manual / *.run install method will result in a broken x-session in the future when kernel is updated!)
#	https://www.if-not-true-then-false.com/2015/fedora-nvidia-guide/
#	https://www.nvidia.com/Download/index.aspx
#
#	GeForce RTX 30 series cards works with 465.xx and 460.xx NVIDIA drivers, (RTX 3090, RTX 3080 and RTX 3070)
#	GeForce RTX 20 series cards works with 465.xx, 460.xx and 450.xx NVIDIA drivers (RTX 2080 Ti, RTX 2080, RTX 2070 Ti, RTX 2070, RTX 2060)
#	GeForce GT/GTX 600/700/800/900/10 series cards works with 465.xx, 460.xx, 450.xx and 390.xx NVIDIA drivers (GTX 1080 Ti, GTX 1080, GTX 1070, GTX 1060, GTX 1660 …)
#	GeForce GT/GTX 400/500 series cards works with 390.xx NVIDIA drivers
#	GeForce GT 8/9/200/300 series cards works with 340.xx NVIDIA drivers
#

driverVersion=0

echo 'Attempting to identify NVIDIA card series ...'

#
#	GeForce RTX 30 series cards works with 465.xx and 460.xx NVIDIA drivers, (RTX 3090, RTX 3080 and RTX 3070)
#
if [[ 0 == ${driverVersion} ]]; then
	if [[ 1 == ${hasInxi} && 0 != $(inxi -G|grep -Pic 'GeForce RTX 3\d\d\d\b') ]]; then
		echo 'Found GeForce RTX 30 series card.';
		driverVersion=newest;

	elif [[ 1 == ${hasLspci} && 0 != $(lspci -vnn|grep VGA|grep -Pic 'GeForce RTX 3\d\d\d\b') ]]; then
		echo 'Found GeForce RTX 30 series card.';
		driverVersion=newest;
	fi
fi

#
#	GeForce RTX 20 series cards works with 465.xx, 460.xx and 450.xx NVIDIA drivers (RTX 2080 Ti, RTX 2080, RTX 2070 Ti, RTX 2070, RTX 2060)
#
if [[ 0 == ${driverVersion} ]]; then
	if [[ 1 == ${hasInxi} && 0 != $(inxi -G|grep -Pic 'GeForce RTX 2\d\d\d\b') ]]; then
		echo 'Found GeForce RTX 20 series card.';
		driverVersion=newest;

	elif [[ 1 == ${hasLspci} && 0 != $(lspci -vnn|grep VGA|grep -Pic 'GeForce RTX 2\d\d\d\b') ]]; then
		echo 'Found GeForce RTX 20 series card.';
		driverVersion=newest;
	fi
fi

#
#	GeForce GT/GTX 600/700/800/900/10 series cards works with 465.xx, 460.xx, 450.xx and 390.xx NVIDIA drivers (GTX 1080 Ti, GTX 1080, GTX 1070, GTX 1060, GTX 1660 …)
#
if [[ 0 == ${driverVersion} ]]; then
	if [[ 1 == ${hasInxi} && 0 != $(inxi -G|grep -Pic 'GeForce GTX? ([6-9]\d\d|1\d\d\d)\b') ]]; then
		echo 'Found GeForce GT/GTX 600/700/800/900/10 series card.';
		driverVersion=newest;

	elif [[ 1 == ${hasLspci} && 0 != $(lspci -vnn|grep VGA|grep -Pic 'GeForce GTX? ([6-9]\d\d|1\d\d\d)\b') ]]; then
		echo 'Found GeForce GT/GTX 600/700/800/900/10 series card.';
		driverVersion=newest;
	fi
fi

#
#	GeForce GT/GTX 400/500 series cards works with 390.xx NVIDIA drivers
#
if [[ 0 == ${driverVersion} ]]; then
	if [[ 1 == ${hasInxi} && 0 != $(inxi -G|grep -Pic 'GeForce GTX? [45]\d\d\b') ]]; then
		echo 'Found Legacy GeForce GT/GTX 400/500 series card.';
		driverVersion=390;

	elif [[ 1 == ${hasLspci} && 0 != $(lspci -vnn|grep VGA|grep -Pic 'GeForce GTX? [45]\d\d\b') ]]; then
		echo 'Found Legacy GeForce GT/GTX 400/500 series card.';
		driverVersion=390;
	fi
fi

#
#	GeForce GT 8/9/200/300 series cards works with 340.xx NVIDIA drivers
#
if [[ 0 == ${driverVersion} ]]; then
	if [[ 1 == ${hasInxi} && 0 != $(inxi -G|grep -Pic 'GeForce GT ([89]|[23]\d\d)\b') ]]; then
		echo 'Found Legacy GeForce GT 8/9/200/300 series card.';
		driverVersion=340;

	elif [[ 1 == ${hasLspci} && 0 != $(lspci -vnn|grep VGA|grep -Pic 'GeForce GT ([89]|[23]\d\d)\b') ]]; then
		echo 'Found Legacy GeForce GT 8/9/200/300 series card.';
		driverVersion=340;
	fi
fi

#echo "driverVersion: ${driverVersion}"
if [[ 0 == ${driverVersion} ]]; then
	echo "E: Unable to identify NVIDIA card.";
	echo "";
	if [[ 1 == ${hasInxi} ]]; then
		echo "inxi -G|grep -Pi 'NVIDIA|GeForce'";
		inxi -G|grep -Pi 'NVIDIA|GeForce';

	elif [[ 1 == ${hasLspci} ]]; then
		echo "lspci -vnn|grep VGA|grep -Pi 'NVIDIA|GeForce';";
		lspci -vnn|grep VGA|grep -Pi 'NVIDIA|GeForce';
	fi
	exit -1;
fi

if [[ 1 == ${IS_ETC_KEEPER_INSTALLED} ]]; then
    sudo etckeeper commit "${SCRIPT_NAME}: before installing proprietary nvidia drivers from rpmfusion (non-free)" 2>&1 >/dev/null;
fi


if [[ 'newest' == "${driverVersion}" ]]; then
	echo "Installing ${driverVersion} nvidia driver version ...";
	sudo dnf install -y akmod-nvidia nvidia-settings;

# legacy drivers v390
elif [[ 390 == ${driverVersion} ]]; then
	echo "Installing legacy nvidia driver version ${driverVersion} ...";
	sudo dnf install -y xorg-x11-drv-nvidia-390xx akmod-nvidia-390xx nvidia-settings-390xx;

# legacy drivers v340
elif [[ 340 == ${driverVersion} ]]; then
	echo "Installing legacy nvidia driver version ${driverVersion} ...";
	sudo dnf install -y xorg-x11-drv-nvidia-340xx akmod-nvidia-340xx;
fi

# backup any /etc settings changed during install
if [[ 1 == ${IS_ETC_KEEPER_INSTALLED} ]]; then
    sudo etckeeper commit "${SCRIPT_NAME}: after installing proprietary nvidia drivers from rpmfusion (non-free)" 2>&1 >/dev/null;
fi

if [[ 1 == ${IS_TIMESHIFT_INSTALLED_AND_CONFIGURED} ]]; then
	# --tags D stands for Daily Backup
	# --tags W stands for Weekly Backup
	# --tags M stands for Monthly Backup
	# --tags O stands for On-demand Backup
	sudo timeshift --create --comments "After installing NVIDIA drivers via RPMFusion (${SCRIPT_NAME})." --tags O;
fi

