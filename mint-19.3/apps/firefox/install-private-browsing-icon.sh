#!/bin/bash

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

CHROME_WINDOWS_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";
PRIVATE_MENU_LINK="/usr/share/applications/firefox-private.desktop";
PRIVATE_ICON_NAME="private-browsing";
PRIVATE_ICON_PATH="/usr/share/icons/${PRIVATE_ICON_NAME}.png";

echo "   PRIVATE_ICON_PATH:    '${PRIVATE_ICON_PATH}'";
echo "   PRIVATE_MENU_LINK:    '${PRIVATE_MENU_LINK}'";

# Make sure private browsing icon exists
if [[ ! -e "${PRIVATE_ICON_PATH}" ]]; then
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

# Make sure system menu for private browsing exists
if [[ ! -f "${PRIVATE_MENU_LINK}" ]]; then
	echo '#!/usr/bin/env xdg-open'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo '[Desktop Entry]'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo 'Version=1.0'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo 'Name=Firefox (Private Browsing)'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo 'Keywords=Internet;WWW;Browser;Web;Explorer'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo 'Exec=firefox -private-window https://www.dnsleaktest.com/'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
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
	echo 'Exec=firefox -new-window -private-window'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo '[Desktop Action new-private-window]'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo 'Name=Open a New Private Window'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo 'Exec=firefox -private-window'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;

	sudo chown root:root "${PRIVATE_MENU_LINK}";
	sudo chmod a+rx "${PRIVATE_MENU_LINK}";
fi
