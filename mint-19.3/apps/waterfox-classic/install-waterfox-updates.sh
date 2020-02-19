#!/bin/bash

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

function printDebugInfo () {
	echo "   ------------------------";
	echo "   Variables from script:";
	echo "   ------------------------";
	echo "   WATERFOX_DOWNLOAD_PAGE=\"${WATERFOX_DOWNLOAD_PAGE}\";";
	echo "   CHROME_WINDOWS_UA=\"${CHROME_WINDOWS_UA}\";";
	echo "   RAW_HTML_SOURCE=\$(/usr/bin/curl --location --user-agent \"\${CHROME_WINDOWS_UA}\" \"\${WATERFOX_DOWNLOAD_PAGE}\" 2>/dev/null);";
	echo "   echo \"raw page source size is: \${#RAW_HTML_SOURCE}\";";
	echo "   CLEANED_PAGE_HTML_SOURCE=\$(echo \"\${RAW_HTML_SOURCE}\"|/usr/bin/perl -0pe \"s/>\\s*</>\\n</g\"|grep -Pi '<a.*classic.*linux');";
	echo "   echo \"cleaned page source size is: \${#CLEANED_PAGE_HTML_SOURCE}\";";
	echo "   PAGE_SOURCE_SIZE=\$(/usr/bin/curl --location --user-agent \"\${CHROME_WINDOWS_UA}\" \"\${WATERFOX_DOWNLOAD_PAGE}\" 2>/dev/null);";
	echo "   WATERFOX_TAR_DOWNLOAD_LINK=$(echo \"\${CLEANED_PAGE_HTML_SOURCE}\"| grep -P \"href\\S*en-US.linux\\S*.tar.bz2\" | grep -Pvi '(aurora|alpha|waterfox\\-[6-9]\\d|waterfox\\-[\\d\\.]+a[\\d\\.]*\\.en\\-US.linux\\-x86_64.tar.bz2)' | /usr/bin/perl -pe 's/^.*href=\"([^\"]+)\".*\$/\$1/g' | /usr/bin/sort -u | /usr/bin/tail -n 1);";
	echo "   echo \"download link size is: \${#WATERFOX_TAR_DOWNLOAD_LINK}\";";
	echo "   echo \"\${RAW_HTML_SOURCE}\" > /tmp/waterfox-cli-raw-source.txt";
	echo "   echo \"\${CLEANED_PAGE_HTML_SOURCE}\" > /tmp/waterfox-cli-cleaned-source.txt";
	echo "";
	echo "   ------------------------";
	echo "   Values from script:";
	echo "   ------------------------";
	echo "   Raw Page Source Size:      ${RAW_PAGE_HTML_SIZE}"
	echo "   Cleaned Page Source Size:  ${CLEANED_PAGE_HTML_SIZE}"
	echo "   Download Link Size:        ${#WATERFOX_TAR_DOWNLOAD_LINK}";
	echo "   Download Link Value:       '${WATERFOX_TAR_DOWNLOAD_LINK}'";
	echo "   Waterfox version:          '${WATERFOX_VERSION}'";
	echo "";
	echo "   ------------------------";
	echo "   Source dump from script:";
	echo "   ------------------------";
	echo "   cat /tmp/waterfox-sh-raw-source.txt";
	echo "   cat /tmp/waterfox-sh-cleaned-source.txt";
	echo "";
	echo "   diff /tmp/waterfox-sh-raw-source.txt /tmp/waterfox-cli-raw-source.txt";
	echo "   diff /tmp/waterfox-sh-cleaned-source.txt /tmp/waterfox-cli-cleaned-source.txt";
	echo "";
}

ARG1="$1";
ARG2="$2";
WATERFOX_DOWNLOAD_PAGE="https://www.waterfox.net/releases/";
CHROME_WINDOWS_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";
WATERFOX_MENU_LINK="/usr/share/applications/waterfox-classic.desktop";
PRIVATE_MENU_LINK="/usr/share/applications/waterfox-private.desktop";
PRIVATE_ICON_NAME="private-browsing";
PRIVATE_ICON_PATH="/usr/share/icons/${PRIVATE_ICON_NAME}.png";
WATERFOX_ICON_NAME="waterfox-classic";
WATERFOX_ICON_PATH="/usr/share/icons/${WATERFOX_ICON_NAME}.png";

if [[ "-h" == "${ARG1}" || "--help" == "${ARG1}" ]]; then
	echo '';
	echo -e "Usage: \t $0 [options]";
	echo -e "\nOptions:";
	echo -e " \t -f, --force \t\t Forces the install to continue, even if already installed or backups fail.";
	echo -e " \t -s, --skip-backup \t Skips creation of 7z backup of the existing installation dir.";
	echo '';
	exit;
fi

SKIP_BACKUP="false";
FORCE_INSTALL="false";
if [[ "" != "${ARG1}" ]]; then
	#Check arg1
	if [[ "-f" == "${ARG1}" || "--force" == "${ARG1}" ]]; then
		FORCE_INSTALL="true";
	elif [[ "-s" == "${ARG1}" || "--skip-backup" == "${ARG1}" ]]; then
		SKIP_BACKUP="true";
	else
		echo "ERROR: Unrecognized option '${ARG1}'; see ${0} --help for more details";
		echo "Aborting script";
		exit;
	fi

	#Check arg2
	if [[ "" != "${ARG2}" ]]; then
		if [[ "-f" == "${ARG2}" || "--force" == "${ARG2}" ]]; then
			FORCE_INSTALL="true";
		elif [[ "-s" == "${ARG2}" || "--skip-backup" == "${ARG2}" ]]; then
			SKIP_BACKUP="true";
		else
			echo "ERROR: Unrecognized option '${ARG2}'; see ${0} --help for more details";
			echo "Aborting script";
			exit;
		fi
	fi
fi

#Dir where the 'waterfox' folder will be extracted to...
PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO="/opt";

#Script dependencies
echo "Checking script dependencies...";
if [[ ! -e "/usr/bin/7z" ]]; then
	sudo apt install -y p7zip-full;
	if [[ ! -e "/usr/bin/7z" ]]; then
		echo "ERROR: 7z is not installed.";
		echo "Aborting script";
		exit;
	fi
fi
if [[ ! -e "/usr/bin/curl" ]]; then
	sudo apt install -y curl;
	if [[ ! -e "/usr/bin/curl" ]]; then
		echo "ERROR: curl is not installed.";
		echo "Aborting script";
		exit;
	fi
fi


#Verify stuff
if [[ "" == "${WATERFOX_DOWNLOAD_PAGE}" ]]; then
	echo "ERROR: WATERFOX_DOWNLOAD_PAGE not defined.";
	echo "Aborting script";
	exit;
elif [[ "" == "${CHROME_WINDOWS_UA}" ]]; then
	echo "ERROR: CHROME_WINDOWS_UA not defined.";
	echo "Aborting script";
	exit;
elif [[ "" == "${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}" ]]; then
	echo "ERROR: PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO not defined.";
	echo "Aborting script";
	exit;
fi

#Create the parent dir, if it doesn't already exist
if [[ ! -e "${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}" ]]; then
	mkdir -p "${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}" 2>/dev/null;
fi
if [[ ! -e "${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}" ]]; then
	echo "ERROR: Cannot find or create parent dir '${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}'";
	echo "Aborting script";
	exit;
fi

echo ''
echo -e "Fetching archive link from Downloads page:\n\t${WATERFOX_DOWNLOAD_PAGE}";
RAW_HTML_SOURCE=$(/usr/bin/curl --location --user-agent "${CHROME_WINDOWS_UA}" "${WATERFOX_DOWNLOAD_PAGE}" 2>/dev/null);
if [[ "0" != "$?" ]]; then
	echo "ERROR: curl returned error code of $? while accessing download URL : ${WATERFOX_DOWNLOAD_PAGE}";
	echo "Aborting script";
	exit;
fi
if [[ "" == "${RAW_HTML_SOURCE}" ]]; then
	echo "ERROR: RAW_HTML_SOURCE was empty; please check download URL : ${WATERFOX_DOWNLOAD_PAGE}";
	echo "Aborting script";
	exit;
fi

echo '';
echo 'Cleaning page source to only show Waterfox Classic versions...';

# Remove all lines after and including the line with 'Waterfox Current'
RAW_PAGE_HTML_SIZE="${#RAW_HTML_SOURCE}";
CLEANED_PAGE_HTML_SOURCE=$(echo "${RAW_HTML_SOURCE}"|/usr/bin/perl -0pe "s/>\s*</>\n</g"|grep -Pi '<a.*classic.*linux');
CLEANED_PAGE_HTML_SIZE="${#CLEANED_PAGE_HTML_SOURCE}";

echo '';
echo 'Parsing download link...'
WATERFOX_TAR_DOWNLOAD_LINK=$(echo "${CLEANED_PAGE_HTML_SOURCE}"| grep -P "href\S*en-US.linux\S*.tar.bz2" | grep -Pvi '(aurora|alpha|waterfox\-[6-9]\d|waterfox\-[\d\.]+a[\d\.]*\.en\-US.linux\-x86_64.tar.bz2)' | /usr/bin/perl -pe 's/^.*href="([^"]+)".*$/$1/g' | /usr/bin/sort -u | /usr/bin/tail -n 1);
if [[ ${#WATERFOX_TAR_DOWNLOAD_LINK} -lt 30 || ${#WATERFOX_TAR_DOWNLOAD_LINK} -gt 300 || "http" != "${WATERFOX_TAR_DOWNLOAD_LINK:0:4}" ]]; then
	# dump source to temp file for debugging...
	echo "${RAW_HTML_SOURCE}" > /tmp/waterfox-sh-raw-source.txt
	echo "${CLEANED_PAGE_HTML_SOURCE}" > /tmp/waterfox-sh-cleaned-source.txt

	# print error message
	echo "";
	echo "===========================================================================================";
	echo "ERROR: Invalid download link value. The script may need to be updated.";
	echo "       Displaying debug info then aborting script";
	echo "===========================================================================================";
	printDebugInfo;
	exit;
fi

echo 'Parsing version...'
WATERFOX_VERSION=$(echo "${WATERFOX_TAR_DOWNLOAD_LINK}" | sed -E 's/^.*waterfox\-(classic\-)?([0-9][0-9\.]*)\.en.*$/\2/g');
if [[ "" == "${WATERFOX_VERSION}" || "${WATERFOX_TAR_DOWNLOAD_LINK}" == "${WATERFOX_VERSION}" ]]; then
	# dump source to temp file for debugging...
	echo "${RAW_HTML_SOURCE}" > /tmp/waterfox-sh-raw-source.txt
	echo "${CLEANED_PAGE_HTML_SOURCE}" > /tmp/waterfox-sh-cleaned-source.txt

	# print error message
	echo "";
	echo "===========================================================================================";
	echo "ERROR: Waterfox version could not be identified. The script may need to be updated.";
	echo "       Displaying debug info then aborting script";
	echo "===========================================================================================";
	printDebugInfo;
	exit;
fi

if [[ ! $WATERFOX_VERSION =~ ^20[1-9][0-9]\.[0-9][0-9]$ && ! $WATERFOX_VERSION =~ ^56.*$ ]]; then
	# dump source to temp file for debugging...
	echo "${RAW_HTML_SOURCE}" > /tmp/waterfox-sh-raw-source.txt
	echo "${CLEANED_PAGE_HTML_SOURCE}" > /tmp/waterfox-sh-cleaned-source.txt

	# print error message
	echo "";
	echo "===========================================================================================";
	echo "ERROR: Invalid Waterfox Classic version detected. The script may need to be updated.";
	echo "       Displaying debug info then aborting script";
	echo "===========================================================================================";
	echo ""
	echo "Waterfox Classic is recommended over Waterfox Current."
	echo "Some issues with Waterfox Current have been noticed under Mint 19.x / Ubuntu 18.04:"
	echo '  - It requires glibc v2.28, creating compatibility issues on Ubuntu 18.04/Mint 19.x'
	echo '  - Legacy firefox addons require heavy modification to work';
	echo ""
	printDebugInfo;
	exit;
fi

#print url
OUTPUT_FILENAME="${WATERFOX_TAR_DOWNLOAD_LINK##*/}";
OUTPUT_FILEPATH="${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}/${OUTPUT_FILENAME}";

echo '';
echo "Extracted WATERFOX_TAR_DOWNLOAD_LINK as: ${WATERFOX_TAR_DOWNLOAD_LINK}";
echo "OUTPUT_FILENAME: ${OUTPUT_FILENAME}";
echo "OUTPUT_FILEPATH: ${OUTPUT_FILEPATH}";

if [[ "" == "${OUTPUT_FILENAME}" ]]; then
	echo "ERROR: OUTPUT_FILENAME not captured.";
	echo "Aborting script";
	exit;
fi
if [[ "" == "${OUTPUT_FILEPATH}" ]]; then
	echo "ERROR: OUTPUT_FILEPATH not captured.";
	echo "Aborting script";
	exit;
fi

if [[ -e "${ARCHIVE_DIR}/${OUTPUT_FILENAME}" && "true" != "${FORCE_INSTALL}" ]]; then
	echo "ERROR: This update appears to have been previously downloaded.";
	echo "The archive '${ARCHIVE_DIR}/${OUTPUT_FILENAME}' already exists.";
	echo "Aborting script";
	echo "To reinstall, rerun the script with either -f or --force options.";
	exit;
fi

#Create a dir for storing installed archives, if it doesn't already exist
ARCHIVE_DIR="${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}/waterfox-archives";
if [[ ! -e "${ARCHIVE_DIR}" ]]; then
	sudo mkdir -p "${ARCHIVE_DIR}" 2>/dev/null;
fi
echo ''
echo "Backup archives will be stored in ARCHIVE_DIR: ${ARCHIVE_DIR}";

#Go to the install dir (usually under /opt)
cd "${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}";

#Make sure that waterfox is not running
sudo /usr/bin/killall -9 waterfox 2>/dev/null;

#Backup existing installation
WATERFOX_CLASSIC_INSTALL_DIR="${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}/waterfox-classic";

BACKUP_TS=$(date +'%Y%m%d%H%M');
WATERFOX_ARCHIVE_NAME="waterfox-classic-backup-${BACKUP_TS}.7z";
WATERFOX_INSTALL_BAK="${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}/${WATERFOX_ARCHIVE_NAME}";

if [[ "true" != "${SKIP_BACKUP}" && -e "${WATERFOX_CLASSIC_INSTALL_DIR}" ]]; then
	if [[ -e "${WATERFOX_INSTALL_BAK}" ]]; then
		sudo rm "${WATERFOX_INSTALL_BAK}" 2>/dev/null;
	fi

	echo '';
	echo "Creating backup of current install to: ${WATERFOX_INSTALL_BAK}  ... ";
	sudo /usr/bin/7z a -t7z -m0=lzma2 -mx=9 -md=32m -ms=on "${WATERFOX_INSTALL_BAK}" "${WATERFOX_CLASSIC_INSTALL_DIR}" >/dev/null 2>/dev/null;
	if [[ ! -e "${WATERFOX_INSTALL_BAK}" && "true" != "${FORCE_INSTALL}" ]]; then
		echo "ERROR: Failed to backup existing installation folder";
		echo "The script may need to be updated.";
		echo "Aborting script";
		exit;
	fi
fi

#download the tar file from der InterWebs
sudo /usr/bin/wget --user-agent "${CHROME_WINDOWS_UA}" "${WATERFOX_TAR_DOWNLOAD_LINK}" --output-document="${OUTPUT_FILEPATH}" 2>/dev/null;
if [[ ! -e "${OUTPUT_FILEPATH}" ]]; then
	echo "ERROR: Failed to download the file from 'WATERFOX_TAR_DOWNLOAD_LINK'";
	echo "The script may need to be updated.";
	echo "Aborting script";
	exit;
else
	echo "Found downloaded archive at: ${OUTPUT_FILEPATH}";
fi

FILE_SIZE_KB=$(du -k "${OUTPUT_FILEPATH}" | cut -f1)
if [[ "0" == "${FILE_SIZE_KB}" ]]; then
	echo "ERROR: Found 0 byte size for file ${OUTPUT_FILEPATH}";
	echo "The script may need to be updated.";
	echo "Aborting script";
	exit;
fi

#If successful and if not first install, then delete the old install
if [[ -e "${WATERFOX_CLASSIC_INSTALL_DIR}" ]]; then
	echo "Removing old install folder (see backup for archived copy)..."
	sudo rm -r "${WATERFOX_CLASSIC_INSTALL_DIR}";
fi

#Finally, extract the new file to the parent folder
echo ''
echo "Extracting 'waterfox-classic' folder to ${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO} ...";
sudo tar -xvjf "${OUTPUT_FILEPATH}" -C "${PARENT_DIR_WHERE_WE_WILL_EXTRACT_TO}" >/dev/null 2>/dev/null;

if [[ ! -e "${WATERFOX_CLASSIC_INSTALL_DIR}" ]]; then
	echo "ERROR: Failed to extract archive. Please resolve manually.";
else
	#Move the downloaded archive to the local archives folder
	sudo mv "${OUTPUT_FILEPATH}" "${ARCHIVE_DIR}/${OUTPUT_FILENAME}" 2>/dev/null;

	#If there are too many old archives in the ARCHIVE_DIR, then delete the oldest one...
	BACKUP_EXT="tar.bz2";
	MAX_TOTAL_BACKUPS="5";
	MAX_PLUS_ONE=$((MAX_TOTAL_BACKUPS+1));
	CURRENT_TOTAL_BACKUPS=$(ls -t $ARCHIVE_DIR/*.${BACKUP_EXT} | wc -l);
	if [[ $CURRENT_TOTAL_BACKUPS -gt $MAX_TOTAL_BACKUPS ]]; then
		ls -t -d -1 $ARCHIVE_DIR/*.${BACKUP_EXT} | tail -n +$MAX_PLUS_ONE | xargs -d '\n' sudo rm;
	fi
fi

# On successful install...
echo "Checking for successful install...";
echo "   WATERFOX_CLASSIC_INSTALL_DIR: '${WATERFOX_CLASSIC_INSTALL_DIR}'";
echo "   WATERFOX_ICON_PATH:   '${WATERFOX_ICON_PATH}'";
echo "   PRIVATE_ICON_PATH:    '${PRIVATE_ICON_PATH}'";
echo "   WATERFOX_MENU_LINK:   '${WATERFOX_MENU_LINK}'";
echo "   PRIVATE_MENU_LINK:    '${PRIVATE_MENU_LINK}'";

# hack to hopefully future-proof against the binary getting renamed...
if [[ ! -e "${WATERFOX_CLASSIC_INSTALL_DIR}/waterfox" ]]; then
    # check if it has been renamed...
    if [[ -e "${WATERFOX_CLASSIC_INSTALL_DIR}/waterfox-classic" ]]; then
        # if so, create a symlink to avoid breaking the script and shortcuts...
        sudo ln -sf "${WATERFOX_CLASSIC_INSTALL_DIR}/waterfox-classic" "${WATERFOX_CLASSIC_INSTALL_DIR}/waterfox";
    fi
fi

if [[ -e "${WATERFOX_CLASSIC_INSTALL_DIR}/waterfox" ]]; then
	# Make sure system link exists / that its pointing to the correct locaton
	sudo ln -sf "${WATERFOX_CLASSIC_INSTALL_DIR}/waterfox" /usr/bin/waterfox;
	sudo ln -sf "${WATERFOX_CLASSIC_INSTALL_DIR}/waterfox-classic" /usr/bin/waterfox;

    # Make sure regular icon exists
    if [[ ! -e "${WATERFOX_ICON_PATH}" ]]; then
        if [[ -e "${WATERFOX_CLASSIC_INSTALL_DIR}/browser/chrome/icons/default/default256.png" ]]; then
            sudo cp "${WATERFOX_CLASSIC_INSTALL_DIR}/browser/chrome/icons/default/default256.png" "${WATERFOX_ICON_PATH}";
    		sudo chown root:root "${WATERFOX_ICON_PATH}";
    		sudo chmod a+r "${WATERFOX_ICON_PATH}";
        fi
    fi

	# Make sure private browsing icon exists
	if [[ ! -e "${PRIVATE_ICON_PATH}" ]]; then
		# if the ../firefox/install-private-browsing-icon.sh install was successful, then just re-copy that image to save time/bandwidth
		if [[ -e /usr/share/icons/private-browsing.png ]]; then
			sudo cp -a /usr/share/icons/private-browsing.png "${PRIVATE_ICON_PATH}";
		else
			PBICON_LINK="https://hg.mozilla.org/mozilla-central/raw-file/tip/browser/branding/official/pbmode.ico";
			TMP_DIR="/tmp/private-browsing-icon";
			PB_TMP_FILE="${TMP_DIR}/pbmode.ico";
			mkdir "${TMP_DIR}" 2>/dev/null;
			/usr/bin/wget --user-agent "${CHROME_WINDOWS_UA}" "${PBICON_LINK}" --output-document="${PB_TMP_FILE}" 2>/dev/null;
			if [[ ! -e /usr/bin/convert ]]; then
		        sudo apt update;
				sudo apt install -y imagemagick;
			fi
			# ================================================================================================================
			# Workaround
			# ================================================================================================================
			# As of ImageMagick 6.9.7-4, convert was VERY buggy for me. It had two issues:
			#	* Would not work with absolute paths; would only work with working dir as parent of input file
			#	* Would generate multiple files appended with numeric indexes instead of the single specified file.
			#
			# With regards to the issue with absolute paths for input/output files.
			# something like the following:
			#		cd $HOME && convert /tmp/private-browsing-icon/pbmode.ico /tmp/private-browsing-icon/pbmode.png
			# would fail with the error:
			# 		convert-im6.q16: missing an image filename `pbmode.png' @ error/convert.c/ConvertImageCommand/3255
			#
			# while the command
			# 		cd /tmp/private-browsing-icon && convert pbmode.ico pbmode.png
			# would "succeed" without any conversion issues but would create
			#		$ ls -l
			#		total 16
			#		-rw-rw---- 1 zzz zzz  930 Feb  2 15:10 pbmode-0.png
			#		-rw-rw---- 1 zzz zzz 1615 Feb  2 15:10 pbmode-1.png
			#		-rw-rw---- 1 zzz zzz 6518 Feb  2 14:50 pbmode.ico
			#
			# instead of the specified "pbmode.png"
			# ================================================================================================================
			if [[ ! -e "${TMP_DIR}" ]]; then
				echo "ERROR: Unable to create temp dir at '${TMP_DIR}'";
			else
				STARTING_DIR=$(pwd);
				cd "${TMP_DIR}";
				convert "${PB_TMP_FILE}" "${PB_TMP_FILE%.*}.png";
				cd "${TMP_DIR}";

				if [[ -e "${PB_TMP_FILE%.*}.png" ]]; then
					sudo cp "${PB_TMP_FILE%.*}.png" "${PRIVATE_ICON_PATH}";
					sudo chown root:root "${PRIVATE_ICON_PATH}";
					sudo chmod a+r "${PRIVATE_ICON_PATH}";

				elif [[ -e "${PB_TMP_FILE%.*}-0.png" ]]; then
					sudo cp "${PB_TMP_FILE%.*}-0.png" "${PRIVATE_ICON_PATH}";
					sudo chown root:root "${PRIVATE_ICON_PATH}";
					sudo chmod a+r "${PRIVATE_ICON_PATH}";

				elif [[ -e "${PB_TMP_FILE%.*}-1.png" ]]; then
					sudo cp "${PB_TMP_FILE%.*}-1.png" "${PRIVATE_ICON_PATH}";
					sudo chown root:root "${PRIVATE_ICON_PATH}";
					sudo chmod a+r "${PRIVATE_ICON_PATH}";

				fi
			fi
		fi
	fi

	# Make sure system menu exists
	if [[ ! -f "${WATERFOX_MENU_LINK}" ]]; then
		sudo touch "${WATERFOX_MENU_LINK}";
		echo '#!/usr/bin/env xdg-open'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo '[Desktop Entry]'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Version=1.0'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Name=Waterfox'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Comment=Firefox fork that supports Legacy Add-ons includes Mozilla security patches.'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Keywords=Internet;WWW;Browser;Web;Explorer'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Exec=waterfox'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Terminal=false'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'X-MultipleArgs=false'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Type=Application'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Icon=waterfox'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Categories=GNOME;GTK;Network;WebBrowser;'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'StartupNotify=true'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Actions=new-window;new-private-window;'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo ''|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo '[Desktop Action new-window]'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Name=Open a New Window'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Exec=waterfox -new-window'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo ''|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo '[Desktop Action new-private-window]'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Name=Open a New Private Window'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Exec=waterfox -private-window'|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;
		echo ''|sudo tee -a "${WATERFOX_MENU_LINK}" 2>&1 >/dev/null;

		sudo chown root:root "${WATERFOX_MENU_LINK}";
		sudo chmod a+rx "${WATERFOX_MENU_LINK}";
	fi

	# Make sure system menu for private browsing exists
	if [[ ! -f "${PRIVATE_MENU_LINK}" ]]; then
		if [[ -f "${WATERFOX_MENU_LINK}" ]]; then
			# copy original
			sudo cp -a "${WATERFOX_MENU_LINK}" "${PRIVATE_MENU_LINK}";

			# remove internationalization (less false positives)
			sudo sed -i -E '/^.*(Name|Keywords|Comment)\[\w+].*$/d' "${PRIVATE_MENU_LINK}";

			# remove the regular new window action
			sudo sed -i -E 's/^(Actions=.*)\bNewWindow;(.*)$/\1\2/g' "${PRIVATE_MENU_LINK}";
			sudo sed -i -z -E 's/\n\[Desktop Action NewWindow\]\nName=[^\n]+\nExec=[^\n]+\n//g' "${PRIVATE_MENU_LINK}";

			# change name
			sudo sed -i -E 's/^(Name=Waterfox.*)/\1 (Private Browsing)/g' "${PRIVATE_MENU_LINK}";

			# change icon
			sudo sed -i -E "s/^(Icon=).*/\\1${PRIVATE_ICON_NAME}/g" "${PRIVATE_MENU_LINK}";

			# change default exec arg
			sudo sed -i -E 's|^(Exec=waterfox\S*) %u$|\1 -private-window https://www.dnsleaktest.com/|g' "${PRIVATE_MENU_LINK}";
		else
			echo '#!/usr/bin/env xdg-open'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo '[Desktop Entry]'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Version=1.0'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Name=Waterfox (Private Browsing)'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Comment=Firefox fork that supports Legacy Add-ons includes Mozilla security patches.'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Keywords=Internet;WWW;Browser;Web;Explorer'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Exec=waterfox -private-window https://www.dnsleaktest.com/'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Terminal=false'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'X-MultipleArgs=false'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Type=Application'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo "Icon=${PRIVATE_ICON_NAME}"|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Categories=GNOME;GTK;Network;WebBrowser;'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'StartupNotify=true'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Actions=new-window;new-private-window;'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Name[en_US]=Private (WF)'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo '[Desktop Action new-window]'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Name=Open a New Window'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Exec=waterfox -new-window -private-window'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo '[Desktop Action new-private-window]'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Name=Open a New Private Window'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo 'Exec=waterfox -private-window'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
			echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		fi
		sudo chown root:root "${PRIVATE_MENU_LINK}";
		sudo chmod a+rx "${PRIVATE_MENU_LINK}";
	fi
fi
