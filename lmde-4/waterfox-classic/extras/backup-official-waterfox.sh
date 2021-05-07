#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

if [[ ! -f "${SCRIPT_DIR_PARENT}/../functions.sh" ]]; then
    echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
    exit;
fi
. "${SCRIPT_DIR_PARENT}/../functions.sh";

skipFlagName="--no-verify-depends";

skipPackageChecks="false";
if [[ "${skipFlagName}" == "$1" ]]; then
	skipPackageChecks="true";
fi

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

appInstallDir="/opt/waterfox-classic";
appBinName="waterfox";
backupArchiveDir="/opt/backups/waterfox-installs";
backupArchiveName=$(date +"waterfox-classic.%Y%m%d%H%M.7z");
backupArchivePath="${backupArchiveDir}/${backupArchiveName}";

if [[ ! -d "${appInstallDir}" ]]; then
	echo "ERROR: appInstallDir '${appInstallDir}' does not exist.";
	echo "Aborting script ...";
	exit;
fi

#Script dependencies
requiredPackagesList="p7zip-full";
if [[ "false" == "${skipPackageChecks}" ]]; then
	verifyAndInstallPackagesFromList "${requiredPackagesList}";
	if [[ "$?" != "0" ]]; then
		echo "";
		echo "ERROR: Failed to validate one or more dependencies.";
		echo "Please check that following packages are installed:";
		echo "  ${requiredPackagesList}";
		echo "";
		echo "Then rerun script. If the problem persists, consider using the ${skipFlagName} option.";
		echo "";
		echo "Aborting script ...";
		exit;
	fi
fi

if [[ ! -e "${backupArchiveDir}" ]]; then
	sudo mkdir -p "${backupArchiveDir}" 2>/dev/null;
fi

echo "Backup archives will be stored in ARCHIVE_DIR: ${ARCHIVE_DIR}";

#Make sure that waterfox is not running
if [[ "" != "${appBinName}" ]]; then
	sudo /usr/bin/killall -9 ${appBinName} 2>/dev/null;
fi

echo '';
echo "Creating backup of current install to: ${backupArchivePath}  ... ";
sudo 7z a -t7z -m0=lzma2 -mx=9 -md=32m -ms=on "${backupArchivePath}" "${appInstallDir}" >/dev/null 2>/dev/null;
if [[ ! -e "${backupArchivePath}" ]]; then
	echo "ERROR: Failed to backup existing installation folder";
	echo "The script may need to be updated.";
	echo "Aborting script";
	exit;
else
	echo "SUCCESS: Backup '${backupArchiveName}' created.";
fi
