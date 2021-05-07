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

# ==================================================
# Define paths and strings
# ==================================================
userAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";

# where will app be installed to
installDir="/opt/waterfox-classic"

# page to scrap for download links
downloadPageUrl="https://www.waterfox.net/releases/";

appBinaryName="waterfox-classic";
appDisplayName="Waterfox Classic";

# Name of the launcher (minus file extension)
launcherName="waterfox-classic";
iconName="waterfox-classic";

menuLauncherPath="/usr/share/applications/${launcherName}.desktop";
iconPath="/usr/share/icons/${iconName}.png";

# if createBackupOfPreviousInstall=true, then where should it be saved? and how many to keep?
archivesDir="/opt/backups/waterfox-downloads";
maximumDownloadsToKeep="10";

# if keepDownloadedArchives=true, then where should it be saved?
backupsDir="/opt/backups/waterfox-installs";

# define flag values
createBackupOfPreviousInstall="true";
displayHelp="false";
enableDebug="false";
forceInstall="false";
forceReDownloadOfArchives="false";
isWaterfoxKpeInstalled="false";
keepDownloadedArchives="true";
keepKpeSymlinks="false";
noClobberSymlinks="false";
omitSymlinks="false";
recreateSymlinks="false";
requireAppVersionCheck="true";
skipPackageChecks="false";
skipFlagName="--no-verify-depends";

# ==================================================
# Check for passed args
# ==================================================
for passedarg in "$@"; do
    #echo "passedarg is $passedarg"
    if [[ "-h" == "${passedarg}" || "--help" == "${passedarg}" ]]; then
        displayHelp="true";

    elif [[ "-a" == "${passedarg}" || "--always-redownload" == "${passedarg}" ]]; then
        forceReDownloadOfArchives="true";
    elif [[ "-A" == "${passedarg}" || "--delete-archives" == "${passedarg}" ]]; then
        keepDownloadedArchives="false";
    elif [[ "-B" == "${passedarg}" || "--skip-backup" == "${passedarg}" ]]; then
        createBackupOfPreviousInstall="false";

    elif [[ "-d" == "${passedarg}" || "--debug" == "${passedarg}" ]]; then
        enableDebug="true";
    elif [[ "-f" == "${passedarg}" || "--force" == "${passedarg}" ]]; then
        forceInstall="true";
    elif [[ "-k" == "${passedarg}" || "--keep-kpe-symlinks" == "${passedarg}" ]]; then
        keepKpeSymlinks="true";
    elif [[ "-n" == "${passedarg}" || "--no-clobber" == "${passedarg}" ]]; then
        noClobberSymlinks="true";
    elif [[ "-o" == "${passedarg}" || "--omit-symlinks" == "${passedarg}" ]]; then
        omitSymlinks="true";
    elif [[ "-r" == "${passedarg}" || "--recreate-symlinks" == "${passedarg}" ]]; then
        recreateSymlinks="true";
    fi
done

echo '';
if [[ "true" == "${displayHelp}" ]]; then
    echo "Usage:  $(basename $0) [options]";
    echo '';
    echo 'Options:';
    echo '  -h, --help                 Displays this help text.';
    echo '';
    echo '  -a, --always-redownload    Force script to redownload archives, even if a local copy exists.';
    echo '                             Normally, the script only downloads the target archive the first';
    echo "                             time, then uses the downloaded copy from: '${archivesDir}'";
    echo '';
    echo '  -A, --delete-archives      Delete downloaded Archives after install.';
    echo "                             Normally, these are saved to: '${archivesDir}'";
    echo '';
    echo '  -B, --skip-backup          Do not create a backup of previous install folder.';
    echo "                             Normally, these are saved to: '${backupsDir}'";
    echo '';
    echo '  -d, --debug                Prints additional debug info.';
    echo '';
    echo '  -f, --force                Forces the install to continue, even if already installed or backups fail.';
    echo '                             Using this option might result in previous installs being overwritten without backup.';
    echo '';
    echo '  -n, --no-clobber           No symlinks will be overwritten.';
    echo '';
    echo '  -k, --keep-kpe-symlinks    Symlinks pointing to waterfox-classic-kpe will not be overwritten.';
    echo '';
    echo '  -o, --omit-symlinks        Script will not add any new symlinks/overwrite any existing symlinks.';
    echo '                             This option is only considered during initial install.';
    echo '';
    echo '  -r, --recreate-symlinks    Script will recreate symlinks even if application is already installed.';
    echo '                             Other options such as -n and -k will still apply.';
    echo '                             This option is not considered during initial install.';
    echo '';
    exit;
fi

# remove trailing slashes from installDir and set installDirParent
if [[ "/" == "${installDir:${#installDir}-1:1}" ]]; then
	installDir="${installDir:0:${#installDir}-1}";
fi
installDirParent=$(dirname "${installDir}");

# check if the PPA version (waterfox-classic-kpe) is also installed ...
# this will be relevant near the end of the script when we create symlinks
tmpKpeCheck=$(apt search waterfox-classic-kpe|grep -P '^i\w*\s+waterfox-classic-kpe'|wc -l);
if [[ "0" != "${tmpKpeCheck}" ]]; then
	isWaterfoxKpeInstalled="true";
fi

# ==================================================
# Verify package dependencies
# ==================================================
requiredPackagesList="p7zip-full curl";
if [[ "false" == "${skipPackageChecks}" ]]; then
	echo "Verifying required packages are installed ...";
	verifyAndInstallPackagesFromList "${requiredPackagesList}";
	if [[ "$?" != "0" ]]; then
		echo '';
		echo 'ERROR: Failed to validate one or more dependencies.';
		echo 'Please check that following packages are installed:';
		echo "  ${requiredPackagesList}";
		echo '';
		echo "Then rerun script. If the problem persists, consider using the ${skipFlagName} option.";
		echo '';
		echo 'Aborting script ...';
		exit;
	fi
	echo "OK: Required packages are installed.";
fi

# ==================================================
# Verify variables
# ==================================================
if [[ "" == "${downloadPageUrl}" ]]; then
	echo 'ERROR: downloadPageUrl not defined.';
	echo 'Aborting script';
	exit;
elif [[ "" == "${userAgent}" ]]; then
	echo 'ERROR: userAgent not defined.';
	echo 'Aborting script';
	exit;
elif [[ "" == "${installDirParent}" ]]; then
	echo 'ERROR: installDir not defined.';
	echo 'Aborting script';
	exit;
fi

if [[ ! -e "${installDirParent}" ]]; then
	if [[ "${HOME}/" != "${installDirParent:0:${#HOME}+1}" ]]; then
		sudo mkdir -p "${installDirParent}" 2>&1 >/dev/null;
	else
		mkdir -p "${installDirParent}" 2>&1 >/dev/null;
	fi
	if [[ ! -e "${installDirParent}" ]]; then
		echo "ERROR: Cannot find or create parent dir '${installDirParent}'";
		echo 'Aborting script';
		exit;
	fi
	# if the first part of the path isn't the user's home dir, then make sure
	# that installDirParent is owned by root
	if [[ "${HOME}/" != "${installDirParent:0:${#HOME}+1}" ]]; then
		sudo chown root:root "${installDirParent}";
		sudo chmod 775 "${installDirParent}";
	fi
fi

if [[ "true" == "${keepDownloadedArchives}" ]]; then
	if [[ ! -e "${archivesDir}" ]]; then
		parentDir=$(dirname "${archivesDir}");
		if [[ "${HOME}/" != "${parentDir:0:${#HOME}+1}" ]]; then
			sudo mkdir -p "${parentDir}" 2>&1 >/dev/null;
			sudo chown root:root "${parentDir}";
			sudo chmod 775 "${parentDir}";
		else
			mkdir -p "${parentDir}" 2>&1 >/dev/null;
		fi

		if [[ "${HOME}/" != "${archivesDir:0:${#HOME}+1}" ]]; then
			sudo mkdir -p "${archivesDir}" 2>&1 >/dev/null;
			sudo chown root:root "${archivesDir}";
			sudo chmod 775 "${archivesDir}";
		else
			mkdir -p "${archivesDir}" 2>&1 >/dev/null;
		fi
	fi
fi

if [[ "true" == "${createBackupOfPreviousInstall}" ]]; then
	if [[ ! -e "${backupsDir}" ]]; then
		parentDir=$(dirname "${backupsDir}");
		if [[ "${HOME}/" != "${parentDir:0:${#HOME}+1}" ]]; then
			sudo mkdir -p "${parentDir}" 2>&1 >/dev/null;
			sudo chown root:root "${parentDir}";
			sudo chmod 775 "${parentDir}";
		else
			mkdir -p "${parentDir}" 2>&1 >/dev/null;
		fi

		if [[ "${HOME}/" != "${backupsDir:0:${#HOME}+1}" ]]; then
			sudo mkdir -p "${backupsDir}" 2>&1 >/dev/null;
			sudo chown root:root "${backupsDir}";
			sudo chmod 775 "${backupsDir}";
		else
			mkdir -p "${backupsDir}" 2>&1 >/dev/null;
		fi
	fi
fi

# ==================================================
# Define debug function
# ==================================================
function printDebugInfo () {
	echo '   ------------------------';
	echo '   Variables from script:';
	echo '   ------------------------';
	echo "   downloadPageUrl=\"${downloadPageUrl}\";";
	echo "   userAgent=\"${userAgent}\";";
	echo "   rawDownloadPageSource=\$(/usr/bin/curl --location --user-agent \"\${userAgent}\" \"\${downloadPageUrl}\" 2>/dev/null);";
	echo "   echo \"length(rawDownloadPageSource): \${#rawDownloadPageSource}\";";
	echo "";
	echo "   echo \"downloadPageFilterRegex='${downloadPageFilterRegex}'";
	echo "   filteredDownloadPageSource=\$(echo \"\${rawDownloadPageSource}\"|/usr/bin/perl -0pe 's/>\\s*</>\\n</g'|grep -Pi \"\${downloadPageFilterRegex}\");";
	echo "   echo \"length(filteredDownloadPageSource): \${#filteredDownloadPageSource}\";";
	echo "";
	echo "   appDownloadLink=$(echo \"\${filteredDownloadPageSource}\"| grep -P \"href\\S*en-US.linux\\S*.tar.bz2\" | grep -Pvi '(aurora|alpha|waterfox\\-[6-9]\\d|waterfox\\-[\\d\\.]+a[\\d\\.]*\\.en\\-US.linux\\-x86_64.tar.bz2)' | /usr/bin/perl -pe 's/^.*href=\"([^\"]+)\".*\$/\$1/g' | /usr/bin/sort -u | /usr/bin/tail -n 1);";
	echo "   echo \"download link size is: \${#appDownloadLink}\";";
	echo "   echo \"\${rawDownloadPageSource}\" > /tmp/${appBinaryName}-cli-raw-source.txt";
	echo "   echo \"\${filteredDownloadPageSource}\" > /tmp/${appBinaryName}-cli-filtered-source.txt";
	echo '';
	echo '   ------------------------';
	echo '   Values from script:';
	echo '   ------------------------';
	echo "   Raw Page Source Size:      ${#rawDownloadPageSource}"
	echo "   Filtered Page Source Size: ${filteredDownloadPageSource}"
	echo "   Download Link Size:        ${#appDownloadLink}";
	echo "   Download Link Value:       '${appDownloadLink}'";
	echo "   Application version:       '${newAppVersion}'";
	echo '';
	echo '   ------------------------';
	echo '   Source dump from script:';
	echo '   ------------------------';
	echo '   cat /tmp/${appBinaryName}-sh-raw-source.txt';
	echo '   cat /tmp/${appBinaryName}-sh-filtered-source.txt';
	echo '';
	echo '   diff /tmp/${appBinaryName}-sh-raw-source.txt /tmp/${appBinaryName}-cli-raw-source.txt';
	echo '   diff /tmp/${appBinaryName}-sh-filtered-source.txt /tmp/${appBinaryName}-cli-filtered-source.txt';
	echo '';
}

# ==================================================
# Get download link from page source
# ==================================================
echo ''
echo 'Fetching Downloads page source from:'
echo "  ${downloadPageUrl}";
rawDownloadPageSource=$(/usr/bin/curl --location --user-agent "${userAgent}" "${downloadPageUrl}" 2>/dev/null);
if [[ "0" != "$?" ]]; then
	echo "ERROR: curl returned error code of $? while accessing download URL : ${downloadPageUrl}";
	echo 'Aborting script';
	exit;
fi
rawPageSourceSize="${#rawDownloadPageSource}";
if [[ "0" == "${rawPageSourceSize}" ]]; then
	echo "ERROR: rawDownloadPageSource was empty; please check download URL : ${downloadPageUrl}";
	echo 'Aborting script';
	exit;
fi
if [[ "true" == "${enableDebug}" ]]; then
	echo '';
	echo "Found raw page source with length: ${rawPageSourceSize}";
fi

# set filter for finding link in page
downloadPageFilterRegex='<a.*href\S*classic.*linux\S*.tar.bz2';

# Clean up page source to only show relevant lines
echo '';
echo 'Filtering page source ...';
filteredDownloadPageSource=$(echo "${rawDownloadPageSource}"|/usr/bin/perl -0pe 's/>\s*</>\n</g'|grep -Pi "${downloadPageFilterRegex}");
filteredPageSourceSize="${#filteredDownloadPageSource}";
if [[ "true" == "${enableDebug}" ]]; then
	echo "Filtered to source to length: ${filteredPageSourceSize}";
	echo '';
	echo "Filtered page source: ${filteredDownloadPageSource}";
fi

# set filters
#excludedDownloadLinksRegex='(aurora|alpha|beta|current|waterfox\-[6-9]\d|waterfox\-[\d\.]+a[\d\.]*\.en\-US.linux\-x86_64.tar.bz2)'
downloadLinkFilterRegex='(classic)'

echo '';
echo 'Parsing filtered source for download link...'
#appDownloadLink=$(echo "${filteredDownloadPageSource}"| grep -Pvi "${excludedDownloadLinksRegex}" | /usr/bin/perl -pe 's/^.*href="([^"]+)".*$/$1/g' | /usr/bin/sort -u | /usr/bin/tail -n 1);
appDownloadLink=$(echo "${filteredDownloadPageSource}"| grep -Pi "${downloadLinkFilterRegex}" | /usr/bin/perl -pe 's/^.*href="([^"]+)".*$/$1/g' | /usr/bin/sort -u | /usr/bin/tail -n 1);
if [[ ${#appDownloadLink} -lt 30 || ${#appDownloadLink} -gt 300 || "http" != "${appDownloadLink:0:4}" ]]; then
	if [[ "true" == "${enableDebug}" ]]; then
		# dump source to temp file for debugging...
		echo "${rawDownloadPageSource}" > /tmp/${appBinaryName}-sh-raw-source.txt
		echo "${filteredDownloadPageSource}" > /tmp/${appBinaryName}-sh-filtered-source.txt
	fi

	# print error message
	echo '';
	echo '===========================================================================================';
	echo 'ERROR: Invalid download link value. The script may need to be updated.';
	echo '       Displaying debug info then aborting script';
	echo '===========================================================================================';
	if [[ "true" == "${enableDebug}" ]]; then
		printDebugInfo;
	fi
	exit;
fi
echo '';
echo 'Found download link as:';
echo "  ${appDownloadLink}";

# ==================================================
# Verify archive and application version
# ==================================================
echo '';
echo "Verifying application version ...";

newAppVersion="";
if [[ "true" == "${requireAppVersionCheck}" ]]; then
	echo 'Parsing application version from link ...'
	newAppVersion=$(echo "${appDownloadLink}" | sed -E "s/^.*${appBinaryName//-/\\-}\\-([0-9][0-9\\.]*)\\.en.*\$/\\1/g");
	if [[ "0" != "$?" || "" == "${newAppVersion}" || "${appDownloadLink}" == "${newAppVersion}" ]]; then
		if [[ "true" == "${enableDebug}" ]]; then
			# dump source to temp file for debugging...
			echo "${rawDownloadPageSource}" > /tmp/${appBinaryName}-sh-raw-source.txt
			echo "${filteredDownloadPageSource}" > /tmp/${appBinaryName}-sh-filtered-source.txt
		fi

		# print error message
		echo '';
		echo '===========================================================================================';
		echo "ERROR: ${appDisplayName} version could not be identified. The script may need to be updated.";
		echo '       Displaying debug info then aborting script';
		echo '===========================================================================================';
		if [[ "true" == "${enableDebug}" ]]; then
			printDebugInfo;
		fi
		exit;
	fi
	echo '';
	echo "Found new app version as: ${newAppVersion}";

	if [[ ! $newAppVersion =~ ^2[0-9]{3}\.[0-9]{2}(\.[0-9]{1,})?$ && ! $newAppVersion =~ ^56.*$ ]]; then
		if [[ "true" == "${enableDebug}" ]]; then
			# dump source to temp file for debugging...
			echo "${rawDownloadPageSource}" > /tmp/${appBinaryName}-sh-raw-source.txt
			echo "${filteredDownloadPageSource}" > /tmp/${appBinaryName}-sh-filtered-source.txt
		fi

		# print error message
		echo '';
		echo '===========================================================================================';
		echo "ERROR: Invalid ${appDisplayName} version detected. The script may need to be updated.";
		echo '       Displaying debug info then aborting script';
		echo '===========================================================================================';
		echo ""
		echo "Waterfox Classic is recommended over Waterfox Current."
		echo "Some issues with Waterfox Current have been noticed under Mint 19.x / Ubuntu 18.04:"
		echo '  - It requires glibc v2.28, creating compatibility issues on Ubuntu 18.04/Mint 19.x'
		echo '  - Legacy firefox addons require heavy modification to work';
		echo ""
		if [[ "true" == "${enableDebug}" ]]; then
			printDebugInfo;
		fi
		exit;
	fi
fi

# Check new version vs old version
latestVersionAlreadyInstalled="false";
if [[ "false" == "${forceInstall}" && -f "${installDir}/version" ]]; then
	echo 'Checking version ...';
	installedAppVersion=$(head -n 1 "${installDir}/version");
	if [[ "${newAppVersion}" == "${installedAppVersion}" ]]; then
		echo "The installed app version is already the latest version (${newAppVersion})";
		latestVersionAlreadyInstalled="true";
		if [[ "false" == "${recreateSymlinks}" ]]; then
			echo "No changes required; exiting script...";
			echo 'To reinstall anyway, rerun the script with either -f or --force options.';
			exit;
		fi
	fi
fi

# ==================================================
# Download archive
# ==================================================
startingDir=$(pwd);
tmpDir=$(mktemp -d /tmp/waterfox-XXXX);

downloadedArchiveName="${appDownloadLink##*/}";
downloadedArchivePath="${tmpDir}/${downloadedArchiveName}";
if [[ "true" == "${enableDebug}" ]]; then
	echo '';
	echo "downloadedArchiveName will be:";
	echo "  ${downloadedArchiveName}";
	echo '';
	echo "downloadedArchivePath will be:";
	echo "  ${downloadedArchivePath}";
	echo '';
	echo "latestVersionAlreadyInstalled: ${latestVersionAlreadyInstalled}";
fi
if [[ "" == "${downloadedArchiveName}" ]]; then
	echo 'ERROR: downloadedArchiveName not captured.';
	echo 'Aborting script';
	exit;
fi
if [[ "" == "${downloadedArchivePath}" ]]; then
	echo 'ERROR: downloadedArchivePath not captured.';
	echo 'Aborting script';
	exit;
fi

if [[ "false" == "${latestVersionAlreadyInstalled}" ]]; then
	if [[ "false" == "{forceReDownloadOfArchives}" && -f "${archivesDir}/${downloadedArchiveName}" ]]; then
		echo '';
		echo 'Using previously downloaded copy of archive to save bandwidth ...';
		cp -a "${archivesDir}/${downloadedArchiveName}" "${downloadedArchivePath}";

	else
		echo '';
		echo 'Downloading archive ...';

		#download the tar file from der InterWebs
		/usr/bin/wget --user-agent "${userAgent}" "${appDownloadLink}" --output-document="${downloadedArchivePath}" 2>/dev/null;
		if [[ ! -e "${downloadedArchivePath}" ]]; then
			echo "ERROR: Failed to download the file from '${appDownloadLink}'";
			echo 'The script may need to be updated.';
			echo 'Aborting script';
			exit;
		fi
		echo 'Download complete; verifying size ...';

		downloadFileSizeInKb=$(du -k "${downloadedArchivePath}" | cut -f1)
		if [[ "0" == "${downloadFileSizeInKb}" ]]; then
			echo "ERROR: Found 0 byte size for file ${downloadedArchivePath}";
			echo 'The script may need to be updated.';
			echo 'Aborting script';
			exit;
		fi

		echo '';
		echo 'Download size successfully verified.';
		if [[ "true" == "${keepDownloadedArchives}" ]]; then
			echo "Saving archive to '${archivesDir}' ...";
			if [[ "${HOME}/" != "${archivesDir:0:${#HOME}+1}" ]]; then
				sudo cp -a "${downloadedArchivePath}" "${archivesDir}/${downloadedArchiveName}";
				sudo chown root:root "${archivesDir}/${downloadedArchiveName}";
				sudo chmod 664 "${archivesDir}/${downloadedArchiveName}";
			else
				cp -a "${downloadedArchivePath}" "${archivesDir}/${downloadedArchiveName}";
			fi

			#If there are too many old archives in the archivesDir, then delete the oldest one...
			if [[ $maximumDownloadsToKeep =~ ^[1-9][0-9]*$ ]]; then
				backupFileExt="tar.bz2";
				maxPlusOne=$((maximumDownloadsToKeep+1));
				currentArchiveTotal=$(find "${archivesDir}" -type f -iname "*.${backupFileExt}"|wc -l);
				if [[ $currentArchiveTotal -gt $maximumDownloadsToKeep ]]; then
					ls -t -d -1 $archivesDir/*.${backupFileExt} | tail -n +$maxPlusOne | xargs -d '\n' sudo rm;
				fi
			fi
		fi
	fi
fi

# ==================================================
# Make sure that waterfox is not running
# ==================================================
sudo /usr/bin/killall -9 waterfox 2>/dev/null;

# ==================================================
# Check for previous installs and make backups
# ==================================================
if [[ "true" == "${enableDebug}" ]]; then
	echo '';
	echo "latestVersionAlreadyInstalled: ${latestVersionAlreadyInstalled}";
	echo "createBackupOfPreviousInstall: ${createBackupOfPreviousInstall}";
	echo "backupsDir: ${backupsDir}";
fi
if [[ "false" == "${latestVersionAlreadyInstalled}" ]]; then
	if [[ "true" == "${createBackupOfPreviousInstall}" && -e "${installDir}" ]]; then
		echo '';
		echo 'Creating backup of previous install ...';

		#Backup existing installation
		backupTimestamp=$(date +'%Y-%m-%d@%H%M%S');
		backupFileName="${appBinaryName}-install-${backupTimestamp}.7z";
		backupFullPath="${backupsDir}/${backupFileName}";

		if [[ ! -f "${backupFullPath}" ]]; then
			echo '';
			echo 'Creating backup of current install at:'
			echo "  ${backupFullPath}";
			sudo /usr/bin/7z a -t7z -m0=lzma2 -mx=9 -md=32m -ms=on "${backupFullPath}" "${installDir}" >/dev/null 2>/dev/null;
			if [[ ! -f "${backupFullPath}" && "true" != "${forceInstall}" ]]; then
				echo 'ERROR: Failed to backup existing installation folder';
				echo 'The script may need to be updated.';
				echo 'Aborting script';
				exit;
			fi
		fi

		#If successful and if not first install, then delete the old install
		if [[ -e "${installDir}" ]]; then
			echo "Removing old install folder (see above)..."
			sudo rm -r "${installDir}";
		fi
	fi
fi

# ==================================================
# Extract archive and setup install dir
# ==================================================
if [[ "true" == "${enableDebug}" ]]; then
	echo '';
	echo "latestVersionAlreadyInstalled: ${latestVersionAlreadyInstalled}";
	echo "appBinaryName: ${appBinaryName}";
fi
if [[ "false" == "${latestVersionAlreadyInstalled}" ]]; then
	#Finally, extract the new file to the parent folder
	echo ''
	echo "Extracting '${appBinaryName}' from archive to ${installDir} ...";
	sudo tar -xvjf "${downloadedArchivePath}" -C "${installDirParent}" >/dev/null 2>/dev/null;

	if [[ ! -e "${installDir}" ]]; then
		echo 'ERROR: Failed to extract archive. Please resolve manually.';
		exit;
	fi

	# save newly installed version to file for reference during next install...
	if [[ "${HOME}/" != "${installDirParent:0:${#HOME}+1}" ]]; then
		echo "${newAppVersion}" | sudo tee "${installDir}/version" >/dev/null;
		sudo chown root:root "${installDir}/version";
		sudo chmod 664 "${installDir}/version";
	else
		echo "${newAppVersion}" | tee "${installDir}/version" >/dev/null;
	fi

	# hack to hopefully future-proof against the binary getting renamed...
	if [[ ! -e "${installDir}/waterfox" ]]; then
	    # check if it has been renamed...
	    if [[ -e "${installDir}/waterfox-classic" ]]; then
	        # if so, create a symlink to avoid breaking the script and shortcuts...
	        sudo ln -s "${installDir}/waterfox-classic" "${installDir}/waterfox";
	    fi
	else
	    if [[ ! -e "${installDir}/waterfox-classic" ]]; then
	        # might as well...
	        sudo ln -s "${installDir}/waterfox" "${installDir}/waterfox-classic";
	    fi
	fi
fi

# ==================================================
# Setup additional symlinks
# ==================================================
waterfoxKpeBinPath="";
if [[ "true" == "${isWaterfoxKpeInstalled}" ]]; then
	waterfoxKpeBinPath=$(realpath /usr/bin/waterfox-classic);
	if [[ "/opt/waterfox-classic/" == "${waterfoxKpeBinPath:0:22}" || "/opt/waterfox/" == "${waterfoxKpeBinPath:0:14}" ]]; then
		if [[ -f "/usr/lib/waterfox-classic/waterfox-classic-bin.sh" ]]; then
			waterfoxKpeBinPath="/usr/lib/waterfox-classic/waterfox-classic-bin.sh";
		else
			waterfoxKpeBinPath="";
		fi
	fi
fi

if [[ "true" != "${omitSymlinks}" && "true" == "${isWaterfoxKpeInstalled}" ]]; then
	echo ''
	echo "Creating symlinks ...";

    applicationBinPath="${installDir}/waterfox-classic";

    symlinkList="waterfox waterfox-classic wf wfc";

	if [[ "true" == "${enableDebug}" ]]; then
		echo '';
		echo "omitSymlinks: ${omitSymlinks}";
		echo "isWaterfoxKpeInstalled: ${isWaterfoxKpeInstalled}";
		echo "waterfoxKpeBinPath: ${waterfoxKpeBinPath}";
		echo "noClobberSymlinks: ${noClobberSymlinks}";
		echo "keepKpeSymlinks: ${keepKpeSymlinks}";
		echo "applicationBinPath: ${applicationBinPath}";
		echo "symlinkList: ${symlinkList}";
	fi

    for symlinkName in $(echo "${symlinkList}"); do
        # if symlink does not exist, simply create it and go to next iteration
        if [[ ! -L "/usr/bin/${symlinkName}" ]]; then
            sudo ln -s "${applicationBinPath}" "/usr/bin/${symlinkName}";
            continue;
        fi

        # otherwise, if the -n/--no-clobber flag is set, then also
        # skip to the next iteration without making any changes
        if [[ "true" == "${noClobberSymlinks}" ]]; then
            continue;
        fi

        # get the symlink target
        symlinkDest=$(realpath "/usr/bin/${symlinkName}");

        # if the -k/--keep-kpe-symlinks flag is set
        # and the target is under either waterfox-classic-kpe location
        # then skip to next iteration without changes
        if [[ "" != "${waterfoxKpeBinPath}" && "true" == "${keepKpeSymlinks}" ]]; then
            if [[ "${waterfoxKpeBinPath}" == "${symlinkDest}" ]]; then
                continue;
            fi
        fi

        # finally, check that the existing symlink does not
        # already point to the correct location
        if [[ "${symlinkDest}" != "${applicationBinPath}" ]]; then
            sudo ln -sf "${applicationBinPath}" "/usr/bin/${symlinkName}";
        fi
    done
fi

# ==================================================
# Make sure icon and system menu are installed
# ==================================================
if [[ -e "${installDir}/waterfox" ]]; then
	if [[ "true" == "${enableDebug}" ]]; then
		# On successful install...
		echo 'Checking for successful install...';
		echo "   installDir: '${installDir}'";
		echo "   iconPath:   '${iconPath}'";
		echo "   menuLauncherPath:   '${menuLauncherPath}'";
	fi

    # Make sure applicaiton icon exists
    if [[ ! -e "${iconPath}" ]]; then
		echo ''
		echo "Installing system icon ...";

        if [[ -e "${installDir}/browser/chrome/icons/default/default256.png" ]]; then
            sudo cp "${installDir}/browser/chrome/icons/default/default256.png" "${iconPath}";
    		sudo chown root:root "${iconPath}";
    		sudo chmod a+r "${iconPath}";
        fi
    fi

	# Make sure system menu exists
	if [[ ! -f "${menuLauncherPath}" ]]; then
		echo ''
		echo "Installing launcher for system menu ...";

		sudo touch "${menuLauncherPath}";
		echo '#!/usr/bin/env xdg-open'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo '[Desktop Entry]'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Version=1.0'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo "Name=${appDisplayName}"|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Keywords=Internet;WWW;Browser;Web;Explorer'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Exec=waterfox'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Terminal=false'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'X-MultipleArgs=false'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Type=Application'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Icon=waterfox'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Categories=GNOME;GTK;Network;WebBrowser;'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'StartupNotify=true'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Actions=new-window;new-private-window;'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo ''|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo '[Desktop Action new-window]'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Name=Open a New Window'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Exec=waterfox -new-window'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo ''|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo '[Desktop Action new-private-window]'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Name=Open a New Private Window'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo 'Exec=waterfox -private-window'|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;
		echo ''|sudo tee -a "${menuLauncherPath}" 2>&1 >/dev/null;

		sudo chown root:root "${menuLauncherPath}";
		sudo chmod a+rx "${menuLauncherPath}";
	fi
fi

echo "Script complete."
