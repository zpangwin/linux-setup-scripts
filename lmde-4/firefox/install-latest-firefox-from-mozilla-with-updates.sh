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
userAgent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.111 Safari/537.36";

# where will app be installed to
installDir="/opt/firefox"

# page to scrap for download links
#downloadPageUrl="https://www.mozilla.org/en-US/firefox/new/";
downloadPageUrl="https://www.mozilla.org/en-US/firefox/linux/";

appBinaryName="firefox";
appDisplayName="firefox";

# Name of the launcher (minus file extension)
launcherName="${appDisplayName}";
iconName="${appDisplayName}";

menuLauncherPath="/usr/share/applications/${launcherName}.desktop";
iconPath="/usr/share/icons/${iconName}.png";

# define flag values
displayHelp="false";
enableDebug="false";

# ==================================================
# Uninstall existing old versions from main repo
# ==================================================
sudo apt-get purge ${appBinaryName}* 2>/dev/null;

# ==================================================
# Check for passed args
# ==================================================
for passedarg in "$@"; do
    #echo "passedarg is $passedarg"
    if [[ "-h" == "${passedarg}" || "--help" == "${passedarg}" ]]; then
        displayHelp="true";

    elif [[ "-d" == "${passedarg}" || "--debug" == "${passedarg}" ]]; then
        enableDebug="true";
    fi
done

echo '';
if [[ "true" == "${displayHelp}" ]]; then
    echo "Usage:  $(basename $0) [options]";
    echo '';
    echo 'Options:';
    echo '  -h, --help                 Displays this help text.';
    echo '';
    echo '  -d, --debug                Prints additional debug info.';
    echo '';
    exit;
fi

# remove trailing slashes from installDir and set installDirParent
if [[ "/" == "${installDir:${#installDir}-1:1}" ]]; then
	installDir="${installDir:0:${#installDir}-1}";
fi
installDirParent=$(dirname "${installDir}");

if [[ -d "${installDir}" ]]; then
	echo "${appDisplayName} already exists at ${installDir}. Aborting script.";
	exit;
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
downloadPageFilterRegex='<a.*href\S*firefox.*linux64\S*';

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
downloadLinkFilterRegex='(linux64)'

echo '';
echo 'Parsing filtered source for download link...'
appDownloadLink=$(echo "${filteredDownloadPageSource}"| grep -Pi "${downloadLinkFilterRegex}" | /usr/bin/perl -pe 's/^.*href="([^"]+)".*$/$1/g' | /usr/bin/sort -u | /usr/bin/tail -n 1 | sed -E 's/(&)amp;/\1/g');
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
# Download archive
# ==================================================
startingDir=$(pwd);
tmpDir=$(mktemp -d /tmp/${appDisplayName}-XXXX);

echo '';
echo 'Downloading archive ...';

cd "${tmpDir}";

if [[ ! $appDownloadLink =~ ^.*tar.*$ ]]; then
	# resolve download file name
	resolvedAppLink=$(/usr/bin/curl --silent --head --location --user-agent "${userAgent}" "${appDownloadLink}"|grep -P "Location:.*${appDisplayName}"|sed -E 's/^Location: |[\r\n\t ]//g');
	if [[ "" != "${resolvedAppLink}" && "http" == "${resolvedAppLink:0:4}" && $resolvedAppLink =~ ^.*tar.*$ ]]; then
		downloadedArchiveName="${resolvedAppLink##*/}";
	else
		echo "ERROR: Failed to resolve filename from ${appDownloadLink} - resolvedAppLink: ${resolvedAppLink}";
		exit;
	fi
else
	downloadedArchiveName="${appDownloadLink##*/}";
fi
downloadedArchivePath="${tmpDir}/${downloadedArchiveName}";

#download the file from der InterWebs
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

# ==================================================
# Extract archive and setup install dir
# ==================================================
echo ''
echo "Extracting '${appBinaryName}' from archive to ${installDir} ...";
sudo tar -xvjf "${downloadedArchivePath}" -C "${installDirParent}" >/dev/null 2>/dev/null;

if [[ ! -e "${installDir}" ]]; then
	echo 'ERROR: Failed to extract archive. Please resolve manually.';
	exit;
fi

# ==================================================
# Setup additional symlinks
# ==================================================
if [[ "true" != "${omitSymlinks}" ]]; then
	echo ''
	echo "Creating symlinks ...";

    applicationBinPath="${installDir}/${appBinaryName}";

    symlinkList="${appBinaryName} ff";

	if [[ "true" == "${enableDebug}" ]]; then
		echo '';
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

        # finally, check that the existing symlink does not
        # already point to the correct location
        if [[ "${symlinkDest}" != "${applicationBinPath}" ]]; then
            sudo ln -sf "${applicationBinPath}" "/usr/bin/${symlinkName}";
        fi
    done
fi

# ==================================================
# Setup app icons
# ==================================================
if [[ -f "${SCRIPT_DIR}/fix-ugly-firefox-icons.sh" ]]; then
	/bin/bash "${SCRIPT_DIR}/fix-ugly-firefox-icons.sh";
fi

# ==================================================
# Setup app menu shortcuts
# ==================================================
if [[ -f "${SCRIPT_DIR}/firefox.desktop" ]]; then
	sudo cp -a -t /usr/share/applications "${SCRIPT_DIR}/firefox.desktop";

	sudo mkdir /etc/skel/Desktop 2>/dev/null;
	sudo cp -a -t /etc/skel/Desktop "${SCRIPT_DIR}/firefox.desktop";

	sudo chown root:root /usr/share/applications/firefox.desktop /etc/skel/Desktop/firefox.desktop;
	sudo chmod 755 /usr/share/applications/firefox.desktop /etc/skel/Desktop/firefox.desktop;

	if [[ 'root' != "$USER" ]]; then
		cp -a -t "${HOME}/Desktop" "${SCRIPT_DIR}/firefox.desktop";
		sudo chmod 755 "${HOME}/Desktop/firefox.desktop";
	fi
fi
