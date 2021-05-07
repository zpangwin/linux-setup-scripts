#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

export CHROME_WINDOWS_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";

APPLICATION_NAME="eclipse-jee";
APPLICATION_DISPLAY_NAME="Eclipse JEE";
APPLICATION_LOG_PREFIX="${APPLICATION_NAME}";
SERVER_URL_PREFIX="https://www.eclipse.org";
APPLICATION_DOWNLOAD_PAGE="https://www.eclipse.org/downloads/packages/";

# where will app be installed to
installDirParent="/opt";
installDir="${installDirParent}/${APPLICATION_NAME}";

mirrorServerPrefix="http://mirror.cc.columbia.edu/pub/software/eclipse";

#backup mirrors
#mirrorServerPrefix="http://www.gtlib.gatech.edu/pub/eclipse";
#mirrorServerPrefix="https://mirror.umd.edu/eclipse";

if [[ -d "${installDir}" ]]; then
	echo "ERROR: Install  dir '${installDir}' already exists.";
	exit 2
fi

echo ''
echo -e "Fetching archive link from Downloads page:\n\t${APPLICATION_DOWNLOAD_PAGE}";
RAW_HTML_SOURCE=$(/usr/bin/curl --location --user-agent "${CHROME_WINDOWS_UA}" "${APPLICATION_DOWNLOAD_PAGE}" 2>/dev/null);
ERROR_CODE="$?";
if [[ "0" != "${ERROR_CODE}" ]]; then
	echo "ERROR: curl returned error code of $ERROR_CODE while accessing download URL : ${APPLICATION_DOWNLOAD_PAGE}";
	echo "Aborting script";
	exit;
fi
if [[ "" == "${RAW_HTML_SOURCE}" ]]; then
	echo "ERROR: RAW_HTML_SOURCE was empty; please check download URL : ${APPLICATION_DOWNLOAD_PAGE}";
	echo "Aborting script";
	exit;
fi

PAGE_FILTER_REGEX='.*eclipse\-jee.*linux.*';

echo '';
echo 'Parsing download link from page source ...'
APPLICATION_DOWNLOAD_LINK=$(echo "${RAW_HTML_SOURCE}" | /usr/bin/perl -0pe "s/>\s*</>\n</g"|grep -P "${PAGE_FILTER_REGEX}"|/usr/bin/perl -pe "s/^.*(?:href=[\"']|url=)([^\"']+)[\"'].*\$/\$1/g");
if [[ '//' == "${APPLICATION_DOWNLOAD_LINK:0:2}" ]]; then
	APPLICATION_DOWNLOAD_LINK="$(echo "${APPLICATION_DOWNLOAD_PAGE}"|sed -E 's|^(https?:)//.*$|\1|g')${APPLICATION_DOWNLOAD_LINK}";
fi
if [[ ${#APPLICATION_DOWNLOAD_LINK} -lt 30 || ${#APPLICATION_DOWNLOAD_LINK} -gt 300 || "http" != "${APPLICATION_DOWNLOAD_LINK:0:4}" ]]; then
	if [[ "/" == "${APPLICATION_DOWNLOAD_LINK:0:1}" ]]; then
		APPLICATION_DOWNLOAD_LINK="${SERVER_URL_PREFIX}${APPLICATION_DOWNLOAD_LINK}";
	fi

	if [[ ${#APPLICATION_DOWNLOAD_LINK} -lt 30 || ${#APPLICATION_DOWNLOAD_LINK} -gt 300 || "http" != "${APPLICATION_DOWNLOAD_LINK:0:4}" ]]; then
		# dump source to temp file for debugging...
		echo "${RAW_HTML_SOURCE}" > /tmp/${APPLICATION_LOG_PREFIX}-sh-raw-source.txt

		# print error message
		echo "";
		echo "===========================================================================================";
		echo "ERROR: Invalid download link value. The script may need to be updated.";
		echo "       Displaying debug info then aborting script";
		echo "===========================================================================================";
		printDebugInfo;
		exit;
	fi
fi
echo "Found download link as '${APPLICATION_DOWNLOAD_LINK}' ";

echo 'Parsing version...'
APPLICATION_VERSION=$(echo "${APPLICATION_DOWNLOAD_LINK}" | sed -E 's/^.*eclipse\-jee\-([0-9][-0-9\.]*\-[0-9.A-Za-z]*)\-linux.*\.tar\.gz$/\1/g');
if [[ "" == "${APPLICATION_VERSION}" || "${APPLICATION_DOWNLOAD_LINK}" == "${APPLICATION_VERSION}" ]]; then
	# dump source to temp file for debugging...
	echo "${RAW_HTML_SOURCE}" > /tmp/${APPLICATION_LOG_PREFIX}-sh-raw-source.txt
	echo "${CLEANED_PAGE_HTML_SOURCE}" > /tmp/${APPLICATION_LOG_PREFIX}-sh-cleaned-source.txt

	# print error message
	echo "";
	echo "===========================================================================================";
	echo "ERROR: ${APPLICATION_DISPLAY_NAME} version could not be identified. The script may need to be updated.";
	echo "       Displaying debug info then aborting script";
	echo "===========================================================================================";
	printDebugInfo;
	exit;
fi

echo "Found app version as '${APPLICATION_VERSION}' ";

fileOnMirrorServer="${mirrorServerPrefix}$(echo "${APPLICATION_DOWNLOAD_LINK}" | sed -E 's/^.*?file=(.*)$/\1/g')";

STARTING_DIR=$(pwd);

# change to temp dir for download
TMP_DIR=$(mktemp -d /tmp/eclipse-install-XXXXX);
cd "${TMP_DIR}";

APPLICATION_FILE_NAME=$(basename "$APPLICATION_DOWNLOAD_LINK");
OUTPUT_FILEPATH="${TMP_DIR}/${APPLICATION_FILE_NAME}";

printf '\nAPPLICATION_FILE_NAME: %s\nOUTPUT_FILEPATH: %s\nTMP_DIR: %s\n\n' "'${APPLICATION_FILE_NAME}'" "'${OUTPUT_FILEPATH}'" "'${TMP_DIR}'";

#download the application
echo "Downloading file '${fileOnMirrorServer}' ...";
wget --user-agent "${CHROME_WINDOWS_UA}" "${fileOnMirrorServer}" --output-document="${OUTPUT_FILEPATH}" 2>/dev/null;

# set output file to executable
echo "Setting file permissions ...";
chmod a+r "${OUTPUT_FILEPATH}";

echo ''
echo "Extracting archive ...";
tar -xf "${OUTPUT_FILEPATH}" >/dev/null 2>/dev/null;
if [[ -d "${TMP_DIR}/eclipse" ]]; then
	sudo mv "${TMP_DIR}/eclipse" "${installDir}";
else
	echo "ERROR: Archive structure changed.";
	exit 3;
fi

# return to starting dir
cd "${STARTING_DIR}";

if [[ -f "${installDir}/eclipse" ]]; then
	echo "Creating system symlinks ...";
	sudo ln -s "${installDir}/eclipse" /usr/bin/eclipse 2>/dev/null;
	sudo ln -s "${installDir}/eclipse" /usr/bin/eclipse-jee 2>/dev/null;
fi

if [[ -f "${installDir}/icon.xpm" ]]; then
	echo "Adding system icon ...";
	sudo cp -a "${installDir}/icon.xpm" "/usr/share/pixmaps/eclipse-jee.xpm";
	sudo cp -a "${installDir}/icon.xpm" "/usr/share/icons/eclipse-jee.xpm";
fi

if [[ -f "${SCRIPT_DIR}/eclipse-jee.desktop" ]]; then
	echo "Adding menu shortcuts ...";

	# First, setup /etc/skel
	templateMenuDir="/etc/skel/.local/share/applications";
	sudo mkdir -p "${templateMenuDir}" 2>/dev/null;
	sudo cp -a -t "${templateMenuDir}" "${SCRIPT_DIR}/eclipse-jee.desktop";
	sudo sed -Ei "s#^Exec=.*\$#Exec=${installDir}/eclipse#g" "${templateMenuDir}/eclipse-jee.desktop";

	# then installing user (if not root)
	if [[ "root" != "${SUDO_USER:-$USER}" ]]; then
		mkdir -p "${HOME}/.local/share/applications" 2>/dev/null;
		if [[ -f "${HOME}/.local/share/applications/eclipse-jee.desktop" ]]; then
			cp -a "${HOME}/.local/share/applications/eclipse-jee.desktop" "${HOME}/.local/share/applications/eclipse-jee.desktop.$(date +'%Y%m%d%H%M%S').bak";
		fi
		cp -t "${HOME}/.local/share/applications" "${SCRIPT_DIR}/eclipse-jee.desktop";
		sed -Ei "s#^Exec=.*\$#Exec=${installDir}/eclipse -data '${HOME}/.${APPLICATION_NAME}-workspace'#g" "${HOME}/.local/share/applications/eclipse-jee.desktop";
	fi
fi

# tell menu to update
echo "Refreshing system menu database ...";
sudo update-desktop-database;
