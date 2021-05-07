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

userAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";

# As of Mar 11h, 2019, the old libregeek PPA appears to be abandoned/not updated to
# ubuntu 18.04 (bionic). Older posts referencing "sudo add-apt-repository -y ppa:mdeguzis/libregeek"
# can be ignored as this will not work on Linux Mint 19.x / Ubuntu 18.04 (or later)
#
# As a workaround:
#   https://linuxg.net/how-to-install-antimicro-on-ubuntu-18-10-and-ubuntu-18-04/
#
appDownloadLink="https://launchpad.net/~mdeguzis/+archive/ubuntu/libregeek/+files/antimicro_2.23~artful-1_amd64.deb"

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
fi

#get sudo prompt out of the way
sudo ls -acl >/dev/null;

# update apt's local cache
sudo apt-get update -yq 2>&1 >/dev/null

#install dependencies
sudo apt-get install --install-recommends -y gdebi;

# get deb file
downloadSuccessful="true";
tempDir=$(mktemp -d /tmp/antimicro-XXXX);
downloadPath="${tempDir}/$(basename "${appDownloadLink}")";

cd "${tempDir}";
wget --user-agent "${userAgent}" "${appDownloadLink}" --output-document="${downloadPath}" 2>/dev/null;
if [[ "0" != "$?" ]]; then
	downloadSuccessful="false";
elif [[ ! -e "${downloadPath}" ]]; then
	downloadSuccessful="false";
else
	downloadFileSizeInKb=$(du -k "${downloadPath}" | cut -f1)
	if [[ "0" == "${downloadFileSizeInKb}" ]]; then
		downloadSuccessful="false";
	fi
fi
if [[ "false" == "${downloadSuccessful}" ]]; then
	echo "ERROR: Download failed. Please confirm that the followng url is correct:";
	echo "  ${appDownloadLink}";
	echo "If there is an issue with the script or the url has changed, please submit as an issue.";
	echo "";
	echo "Aborting script";
	exit;
fi

installDependenciesFromDebFile "${downloadPath}";
sudo dpkg -i "${downloadPath}"
