#!/bin/bash

MOUNT_POINT_PATH="/media/windowsos";

# WINDOWS_USER_NAME should be left blank unless there are multiple user accounts and you want to explicitly define a specific one
WINDOWS_USER_NAME="";

# WINDOWS_FF_PROFILE_NAME should be left blank unless there are multiple firefox profiles and you want to explicitly define a specific one
WINDOWS_FF_PROFILE_NAME="";

# get sudo prompts out of the way up-front rather than having it appear in the middle of script output
sudo ls -acl 2>/dev/null >/dev/null;

# Confirm mount point first
wasAlreadyMounted="true";
if [[ ! -d "${MOUNT_POINT_PATH}" ]]; then
	echo "E: Mount point '${MOUNT_POINT_PATH}' does not exist. Please make sure it is defined in /etc/fstab and/or update the path.";
	exit;

elif [[ ! -d "${MOUNT_POINT_PATH}/Windows" || ! -d "${MOUNT_POINT_PATH}/Users" ]]; then
	wasAlreadyMounted="false";

	# attempt to mount...
	echo "Attempting to mount '${MOUNT_POINT_PATH}' ...";
	sudo mount "${MOUNT_POINT_PATH}";

	if [[ ! -d "${MOUNT_POINT_PATH}/Windows" || ! -d "${MOUNT_POINT_PATH}/Users" ]]; then
		echo "E: Mount point '${MOUNT_POINT_PATH}' is not a Windows OS Partition. Please check fstab definition and/or reboot.";
		exit;
	fi
fi

# Find Windows Firefox Profile (uses first profile if there are multiple unless WINDOWS_USER_NAME is defined)
pathToSearch="${MOUNT_POINT_PATH}/Users";
if [[ "" != "${WINDOWS_USER_NAME}" ]]; then
	pathToSearch="${pathToSearch}/${WINDOWS_USER_NAME}";
fi

findOpts='';
if [[ "" != "${WINDOWS_FF_PROFILE_NAME}" ]]; then
	findOpts="-iname '${WINDOWS_FF_PROFILE_NAME}'";
fi

# get full path to firefox profile
windowsFirefoxProfilePath=$(find "${pathToSearch}" -mindepth 7 -maxdepth 7 ${findOpts} -iregex '.*/AppData/Roaming/Mozilla/Firefox/Profiles/.*'|head -1);
windowsFirefoxProfileName=$(basename "${windowsFirefoxProfilePath}");

# Copy profile to temp folder
tmpFirefoxDir="/tmp/ff-temp-profile";
tmpProfileDir="${tmpFirefoxDir}/${windowsFirefoxProfileName}";

mkdir "${tmpFirefoxDir}" 2>/dev/null;
cp -a -t "${tmpFirefoxDir}" "${windowsFirefoxProfilePath}";
chmod -R 700 "${tmpProfileDir}";

# Check Linux profile definitions
winProfileName="windowsff";
tempProfileName="windowstemp";
linuxProfileIniPath="${HOME}/.mozilla/firefox/profiles.ini";

# profile on actual windows partition
alreadyHasWindowsProfileDefinition=$(grep -Pc "Name=${winProfileName}" "${linuxProfileIniPath}");
if [[ "0" == "${alreadyHasWindowsProfileDefinition}" ]]; then
	highestExistingIndex=$(grep -P '\[Profile' "${linuxProfileIniPath}"|sort -n|tail -1|sed -E 's/[^0-9]//g');
	if [[ "" == "${highestExistingIndex}" ]]; then
		highestExistingIndex="0";
	fi
	newIndex=$(( highestExistingIndex + 1 ));

	# add definition
	printf '\n[Profile%s]\nName=%s\nIsRelative=0\nPath=%s\nDefault=0\n\n' "${newIndex}" "${winProfileName}" "${windowsFirefoxProfilePath}" >> "${linuxProfileIniPath}";
fi

# copy of profile under /tmp
alreadyHasWindowsProfileDefinition=$(grep -Pc "Name=${tempProfileName}" "${linuxProfileIniPath}");
if [[ "0" == "${alreadyHasWindowsProfileDefinition}" ]]; then
	highestExistingIndex=$(grep -P '\[Profile' "${linuxProfileIniPath}"|sort -n|tail -1|sed -E 's/[^0-9]//g');
	if [[ "" == "${highestExistingIndex}" ]]; then
		highestExistingIndex="0";
	fi
	newIndex=$(( highestExistingIndex + 1 ));

	# add definition
	printf '\n[Profile%s]\nName=%s\nIsRelative=0\nPath=%s\nDefault=0\n\n' "${newIndex}" "${tempProfileName}" "${tmpProfileDir}" >> "${linuxProfileIniPath}";
fi

