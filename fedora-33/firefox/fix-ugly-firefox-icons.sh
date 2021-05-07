#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

repoTopLevelDir=$(git rev-parse --show-toplevel 2>/dev/null);
if [[ ! -z "${repoTopLevelDir}" && "${repoTopLevelDir}" == "${SCRIPT_DIR:0:${#repoTopLevelDir}}" ]];then
	if [[ -f "${repoTopLevelDir}/backup/firefox-85-logos/fix-ugly-firefox-icons.sh" ]]; then
		echo "Running offline script to use firefox v85 icons..."
		"${repoTopLevelDir}/backup/firefox-85-logos/fix-ugly-firefox-icons.sh";
		exit 0;
	fi
fi


#get sudo prompt out of the way...
echo 'Requesting sudo permissions in order to modify shared icons located under /usr/share/icons ...';
sudo ls -acl > /dev/null;

# Checking dependencies
echo ''
echo 'Checking dependencies ...'
has_pngcheck=$(which pngcheck 2>/dev/null|wc -l);
has_wget=$(which wget 2>/dev/null|wc -l);
missing_depends="${has_pngcheck}${has_wget}";
if [[ "11" != "${missing_depends}" ]]; then
	echo "WARNING: Missing dependencies; attempting to install wget and pngcheck from central repo...";
	sudo dnf install -y wget pngcheck 2>&1 >/dev/null;

	#recheck
	has_pngcheck=$(which pngcheck 2>/dev/null|wc -l);
	has_wget=$(which wget 2>/dev/null|wc -l);
	missing_depends="${has_pngcheck}${has_wget}";

	if [[ "11" != "${missing_depends}" ]]; then
		echo "ERROR: One or more dependencies are still unresolved. Please manually install wget and pngcheck and try again.";
		exit;
	fi
fi

CHROME_WINDOWS_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";

echo ''
echo 'Creating temp dir ...'
mkdir -p /tmp/ff-icons 2>/dev/null;
if [[ ! -d /tmp/ff-icons ]]; then
	echo "ERROR: Failed to create temp dir /tmp/ff-icons; aborting...";
	exit;
fi
cd /tmp/ff-icons;

echo ''
echo 'Checking Firefox source code repo urls ...'

# Find working link...
BASE_URL="";
LINK_1="https://hg.mozilla.org/mozilla-central/file/tip/browser/branding/official";
# For DXR, start here:
#	https://dxr.mozilla.org/mozilla-central/source/browser/branding/official
LINK_2="https://dxr.mozilla.org/mozilla-central/source/browser/branding/official"

SOURCE_URLS="${LINK_1} ${LINK_2}";
for test_url in ${SOURCE_URLS} ; do
	# echo "test_url: '${test_url}'";
	if curl --user-agent "${CHROME_WINDOWS_UA}" --output /dev/null --silent --head --fail "$test_url"; then
		echo "Checking repo at ${test_url} ... ";

		# account for DXR url change for RAW files
		if [[ "${test_url}" == "${LINK_1}" ]]; then
			test_url="https://hg.mozilla.org/mozilla-central/raw-file/tip/browser/branding/official";
		elif [[ "${test_url}" == "${LINK_2}" ]]; then
			test_url="https://dxr.mozilla.org/mozilla-central/raw/browser/branding/official";
		fi

		# do image test:
		TEST_SIZE="64";
		TEST_DOWNLOAD_LINK="${test_url}/default${TEST_SIZE}.png";
		TEST_OUTPUT_FILE="/tmp/ff-icons/test${size}.png";
		TEST_DOWNLOAD_SUCCESS="false";
		TEST_FILE_SIZE_KB="";
		TEST_IMAGE_IS_VALID="";

		wget -q --user-agent "${CHROME_WINDOWS_UA}" "${TEST_DOWNLOAD_LINK}" --output-document="${TEST_OUTPUT_FILE}";
		if [[ "0" == "$?" && -f "${TEST_OUTPUT_FILE}" ]]; then
			TEST_FILE_SIZE_KB=$(du -k "${TEST_OUTPUT_FILE}" | cut -f1);
			if [[ "0" != "${TEST_FILE_SIZE_KB}" ]]; then
				TEST_IMAGE_IS_VALID=$(pngcheck -q "${TEST_OUTPUT_FILE}" >/dev/null; echo $?);
				if [[ "0" == "${TEST_IMAGE_IS_VALID}" ]]; then
					TEST_DOWNLOAD_SUCCESS="true";
				fi
			fi
		fi
		echo "Test download filesize: ${TEST_FILE_SIZE_KB}";
		echo "Test image is valid: ${TEST_IMAGE_IS_VALID}";
		echo "Test successful?: ${TEST_DOWNLOAD_SUCCESS}";

		if [[ "true" == "${TEST_DOWNLOAD_SUCCESS}" ]]; then
			BASE_URL="${test_url}";
			echo "";
			echo "Repo test successful.";
			break;
		fi
		echo "Repo test failed; checking fallbacks ...";
	fi
done

if [[ "" == "${BASE_URL}" ]]; then
	echo "ERROR: Unable to find working base URL.";
	echo "Mozilla may have changed the location of their source files";
	echo "and script may need updating";
	exit;
else
	echo "Found base url as: '${BASE_URL}'";
fi

echo ''
echo 'Downloading icons from Firefox source code repo and replacing local icons (this may take some time)...'

# Replacing mint icons with actual Mozilla icons
SIZES="16 22 24 32 48 64 128 256";

for size in ${SIZES} ; do
	echo "";

	DOWNLOAD_LINK="${BASE_URL}/default${size}.png";
	OUTPUT_FILE="/tmp/ff-icons/default${size}.png";
	FILE_NAME=$(basename "$OUTPUT_FILE");

	DOWNLOAD_SUCCESS="false";
	FILE_SIZE_KB="";
	IMAGE_IS_VALID="";

	echo "downloading file '${FILE_NAME}' ...";
	wget -q --user-agent "${CHROME_WINDOWS_UA}" "${DOWNLOAD_LINK}" --output-document="${OUTPUT_FILE}";
	if [[ "0" == "$?" && -f "${OUTPUT_FILE}" ]]; then
		FILE_SIZE_KB=$(du -k "${OUTPUT_FILE}" | cut -f1);
		if [[ "0" != "${FILE_SIZE_KB}" ]]; then
			IMAGE_IS_VALID=$(pngcheck -q "${TEST_OUTPUT_FILE}" >/dev/null; echo $?);
			if [[ "0" == "${IMAGE_IS_VALID}" ]]; then
				DOWNLOAD_SUCCESS="true";
			fi
		fi
		FILE_SIZE_KB=" (size: ${FILE_SIZE_KB})";
	fi

	#if download successful, then replace any firefox icons of the same size
	if [[ "true" == "${DOWNLOAD_SUCCESS}" ]]; then
		echo "   success: downloaded file '${FILE_NAME}'${FILE_SIZE_KB}; replacing corresponding Mint-X / Mint-Y icons ... ";

		copy_error="false";

		iconDirList="/usr/share/icons/HighContrast/${size}x${size}/apps /usr/share/icons/hicolor/${size}x${size}/apps /usr/share/icons/Mint-Y/apps/${size} /usr/share/icons/Mint-Y/apps/${size}@2x /usr/share/icons/Mint-X/apps/${size}";
		for iconDir in ${iconDirList} ; do
			if [[ "" == "${iconDir}" || ! -d "${iconDir}" ]]; then
				continue;
			fi

			while IFS= read -r -d '' filePath; do
				if [[ "" == "${filePath}" ]]; then
					continue;
				fi
				echo "Overwriting '${filePath}' ...";
				sudo cp "${OUTPUT_FILE}" "${filePath}";
				if [[ "0" != "$?" ]]; then
					copy_error="true";
				fi

			# Find 'firefox.png' exactly but ignore versioned images (e.g.  firefox-3.0.png) as they are symbolic links (excluded via -type f)
			# Using an exact name match will also avoid replacing icons for aurora/developer/nightly versions if those are installed.
			done < <(find "${iconDir}" -type f -iname 'firefox.png' -print0 2>/dev/null)
		done

		if [[ "true" == "${copy_error}" ]]; then
			echo "   warning: failed to copy file '${FILE_NAME}' to one or more locations; skipping ... ";
		fi
	elif [[ "0" != "${IMAGE_IS_VALID}" ]]; then
		echo "   warning: downloaded file '${FILE_NAME}'${FILE_SIZE_KB} is invalid; skipping ... ";
	else
		echo "   warning: failed to download file '${FILE_NAME}'${FILE_SIZE_KB}; skipping ... ";
	fi
done

echo ''
echo 'Script complete; please log-off and back on for changes to take effect.'
