#!/bin/bash

#get sudo prompt out of the way...
echo 'Requesting sudo permissions in order to modify shared icons located under /usr/share/icons ...';
sudo ls -acl > /dev/null;

CHROME_WINDOWS_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";

echo ''
echo 'Downloading icons from Firefox source code repo and replacing local icons (this may take some time)...'

# Find working link...
BASE_URL="";
LINK_1="https://hg.mozilla.org/mozilla-central/file/tip/browser/branding/official";
# For DXR, start here:
#	https://dxr.mozilla.org/mozilla-central/source/browser/branding/official
LINK_2="https://dxr.mozilla.org/mozilla-central/source/browser/branding/official"

SOURCE_URLS="${LINK_1} ${LINK_2}";
for test_url in ${SOURCE_URLS} ; do
	if curl --user-agent "${CHROME_WINDOWS_UA}" --output /dev/null --silent --head --fail "$test_url"; then
		BASE_URL="${test_url}";
		if [[ "${test_url}" == "${LINK_2}" ]]; then
			BASE_URL="https://dxr.mozilla.org/mozilla-central/raw/browser/branding/official";
		fi
		break;
	fi
done

if [[ "" == "${BASE_URL}" ]]; then
	echo "ERROR: Unable to find working base URL.";
	echo "Mozilla may have changed the location of their source files";
	echo "and script may need updating";
	exit;
fi

# Replacing mint icons with actual Mozilla icons
mkdir -p /tmp/ff-icons
SIZES="16 22 24 32 48 64 128 256";
for size in ${SIZES} ; do
	DOWNLOAD_LINK="${BASE_URL}/default${size}.png";
	OUTPUT_FILE="/tmp/ff-icons/default${size}.png";
	wget -q --user-agent "${USER_AGENT}" "${DOWNLOAD_LINK}" --output-document="${OUTPUT_FILE}";

	#if download successful, then replace any firefox icons of the same size
	if [[ "0" == "$?" && -f "${OUTPUT_FILE}" ]]; then
		if [[ -f "/usr/share/icons/HighContrast/${size}x${size}/apps/firefox.png" ]]; then
			sudo cp "${OUTPUT_FILE}" "/usr/share/icons/HighContrast/${size}x${size}/apps/firefox.png";
		fi
		if [[ -f "/usr/share/icons/Mint-Y/apps/${size}@2x/firefox.png" ]]; then
			sudo cp "${OUTPUT_FILE}" "/usr/share/icons/Mint-Y/apps/${size}@2x/firefox.png";
		fi
		if [[ -f "/usr/share/icons/Mint-Y/apps/${size}/firefox.png" ]]; then
			sudo cp "${OUTPUT_FILE}" "/usr/share/icons/Mint-Y/apps/${size}/firefox.png";
		fi
		if [[ -f "/usr/share/icons/Mint-X/apps/${size}/firefox.png" ]]; then
			sudo cp "${OUTPUT_FILE}" "/usr/share/icons/Mint-X/apps/${size}/firefox.png";
		fi
	fi
done
rm -rf /tmp/ff-icons 2>/dev/null;

echo ''
echo 'Script complete; please log-off and back on for changes to take effect.'
