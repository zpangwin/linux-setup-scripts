#!/bin/bash

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

export CHROME_WINDOWS_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";

APPLICATION_DISPLAY_NAME="PIA Client";
APPLICATION_LOG_PREFIX="pia";
SERVER_URL_PREFIX="https://www.privateinternetaccess.com";
APPLICATION_DOWNLOAD_PAGE="https://www.privateinternetaccess.com/installer/x/download_installer_linux";

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

PAGE_FILTER_REGEX='meta.*refresh.*pia.*\.run';

echo '';
echo 'Parsing download link from page source ...'
APPLICATION_DOWNLOAD_LINK=$(echo "${RAW_HTML_SOURCE}" | /usr/bin/perl -0pe "s/>\s*</>\n</g"|grep -P "${PAGE_FILTER_REGEX}"|/usr/bin/perl -pe 's/^.*(?:href="|url=)([^"]+)".*$/$1/g');

if [[ ${#APPLICATION_DOWNLOAD_LINK} -lt 30 || ${#APPLICATION_DOWNLOAD_LINK} -gt 300 || "http" != "${APPLICATION_DOWNLOAD_LINK:0:4}" ]]; then
	APPLICATION_DOWNLOAD_LINK=$(echo "${RAW_HTML_SOURCE}" | /usr/bin/perl -0pe "s/>\s*</>\n</g"|grep -P "href\S*linux\S*"|grep -i 'restart'|/usr/bin/perl -pe 's/^.*href="([^"]+)".*$/$1/g');

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
APPLICATION_VERSION=$(echo "${APPLICATION_DOWNLOAD_LINK}" | sed -E 's/^.*pia-linux\-([0-9][-0-9\.]*)\.run$/\1/g');
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

STARTING_DIR=$(pwd);

# change to temp dir for download
TMP_DIR=$(mktemp -d /tmp/pia-install-XXXXX);
cd "${TMP_DIR}";

APPLICATION_FILE_NAME=$(basename "$APPLICATION_DOWNLOAD_LINK");
OUTPUT_FILEPATH="${TMP_DIR}/${APPLICATION_FILE_NAME}";

#download the application
echo "Downloading file '${APPLICATION_DOWNLOAD_LINK}' ...";
wget --user-agent "${CHROME_WINDOWS_UA}" "${APPLICATION_DOWNLOAD_LINK}" --output-document="${OUTPUT_FILEPATH}" 2>/dev/null;

# set output file to executable
echo "Setting file permissions ...";
chmod 777 "${OUTPUT_FILEPATH}";

sudo env UID=0 EUID=1000 bash -c "${OUTPUT_FILEPATH}";

# return to starting dir
cd "${STARTING_DIR}";

# close pop-up; configuration can be done later...
sleep 10;
#echo "Closing configuration dialog ...";
#sudo pkill --signal 9 --full --ignore-case pia-client;
