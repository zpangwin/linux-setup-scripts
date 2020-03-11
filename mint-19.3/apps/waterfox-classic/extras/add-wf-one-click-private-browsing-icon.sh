#!/bin/bash

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

CHROME_WINDOWS_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";
APPLICATION_DISPLAY_NAME="Waterfox";
APPLICATION_MENU_LINK="/usr/share/applications/waterfox-classic.desktop";

PRIVATE_DEFAULT_PAGE="https://www.dnsleaktest.com/";
PRIVATE_MENU_LINK="/usr/share/applications/waterfox-private.desktop";
PRIVATE_ICON_NAME="private-browsing";
PRIVATE_ICON_PATH="/usr/share/icons/${PRIVATE_ICON_NAME}.png";

APPLICATION_BIN_NAME="waterfox-classic";
IS_APPLICATION_BIN_ON_PATH=$(which waterfox-classic|wc -l);
if [[ "0" == "${IS_APPLICATION_BIN_ON_PATH}" ]]; then
    APPLICATION_BIN_NAME="waterfox";
    IS_APPLICATION_BIN_ON_PATH=$(which waterfox|wc -l);
    if [[ "0" == "${IS_APPLICATION_BIN_ON_PATH}" ]]; then
        echo "ERROR: ${APPLICATION_DISPLAY_NAME} does not appear to be installed or is not reachable on the \$PATH variable."
        echo "Aborting script";
        exit;
    fi
fi

# Debug
echo "Checking for successful install...";
echo "   PRIVATE_ICON_PATH:    '${PRIVATE_ICON_PATH}'";
echo "   APPLICATION_MENU_LINK:   '${APPLICATION_MENU_LINK}'";
echo "   PRIVATE_MENU_LINK:    '${PRIVATE_MENU_LINK}'";

# Make sure private browsing icon exists
if [[ ! -e "${PRIVATE_ICON_PATH}" ]]; then
	PBICON_LINK="https://hg.mozilla.org/mozilla-central/raw-file/tip/browser/branding/official/pbmode.ico";
	TMP_DIR="/tmp/private-browsing-icon";
	PB_TMP_FILE="${TMP_DIR}/pbmode.ico";
	mkdir "${TMP_DIR}" 2>/dev/null;
	/usr/bin/wget --user-agent "${CHROME_WINDOWS_UA}" "${PBICON_LINK}" --output-document="${PB_TMP_FILE}" 2>/dev/null;
	if [[ ! -e /usr/bin/convert ]]; then
        sudo apt-get update;
		sudo apt-get install -y imagemagick;
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
	#		-rw-rw---- 1 my_user my_user  930 Feb  2 15:10 pbmode-0.png
	#		-rw-rw---- 1 my_user my_user 1615 Feb  2 15:10 pbmode-1.png
	#		-rw-rw---- 1 my_user my_user 6518 Feb  2 14:50 pbmode.ico
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
    # If the non-private menu shortcut exists, just copy it and make a few small changes...
    if [[ -f "${APPLICATION_MENU_LINK}" ]]; then
	    # copy original
	    sudo cp -a "${APPLICATION_MENU_LINK}" "${PRIVATE_MENU_LINK}";

	    # remove internationalization (less false positives)
	    sudo sed -i -E '/^.*(Name|Keywords|Comment)\[\w+].*$/d' "${PRIVATE_MENU_LINK}";

	    # remove the regular new window action
	    sudo sed -i -E 's/^(Actions=.*)\bNewWindow;(.*)$/\1\2/g' "${PRIVATE_MENU_LINK}";
	    sudo sed -i -z -E 's/\n\[Desktop Action NewWindow\]\nName=[^\n]+\nExec=[^\n]+\n//g' "${PRIVATE_MENU_LINK}";

	    # change name
	    sudo sed -i -E 's/^(Name=\S*.*)/\1 (Private Browsing)/g' "${PRIVATE_MENU_LINK}";

	    # change icon
	    sudo sed -i -E "s/^(Icon=).*/\\1${PRIVATE_ICON_NAME}/g" "${PRIVATE_MENU_LINK}";

	    # change default exec arg
	    sudo sed -i -E "s|^(Exec=\\S*) %u\$|\1 -private-window ${PRIVATE_DEFAULT_PAGE}|g" "${PRIVATE_MENU_LINK}";
	else
		echo '#!/usr/bin/env xdg-open'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo '[Desktop Entry]'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Version=1.0'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo "Name=${APPLICATION_DISPLAY_NAME} (Private Browsing)"|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Keywords=Internet;WWW;Browser;Web;Explorer'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo "Exec=${APPLICATION_BIN_NAME} -private-window ${PRIVATE_DEFAULT_PAGE}"|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Terminal=false'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo 'X-MultipleArgs=false'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Type=Application'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo "Icon=${PRIVATE_ICON_NAME}"|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Categories=GNOME;GTK;Network;WebBrowser;'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo 'MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo 'StartupNotify=true'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Actions=new-private-window;'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;

		echo '[Desktop Action new-private-window]'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo 'Name=Open a New Private Window'|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo "Exec=${APPLICATION_BIN_NAME} -private-window"|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
		echo ''|sudo tee -a "${PRIVATE_MENU_LINK}" 2>&1 >/dev/null;
	fi
	sudo chown root:root "${PRIVATE_MENU_LINK}";
	sudo chmod a+rx "${PRIVATE_MENU_LINK}";
fi
