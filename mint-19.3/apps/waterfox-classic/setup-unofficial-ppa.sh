#!/bin/bash

if [ -f ../functions.sh ]; then
    . ../functions.sh
else
	echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
	exit;
fi

# ========================================================================
# // Begin WIP safety section
# ========================================================================
echo "THIS IS CURRENTLY UNTESTED !!! Aborting script...";
echo "If you want to run it anyway comment out this section.";
exit;
# ========================================================================
# // End WIP safety section
# ========================================================================

# See https://www.blackrosetech.com/gessel/2019/06/19/update-waterfox-with-the-new-ppa-on-mint-19-1
#		https://forums.linuxmint.com/viewtopic.php?t=296666
#

# add unofficial hawkeye116477 source for waterfox
addCustomSource waterfox-unofficial 'deb http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/xUbuntu_18.04/ /';

# add key for hawkeye116477 repo
wget -qO - https://download.opensuse.org/repositories/home:hawkeye116477:waterfox/xUbuntu_18.04/Release.key | sudo apt-key add -;

# update local apt cache
sudo apt update 2>/dev/null >/dev/null;

# waterfox-classic => resolves to waterfox-classic-kpe
# normally this package prompts you with a package configuration
# screen that you have to type ENTER on.
#
# To avoid the prompt breaking automation, we are going to follow:
#	http://www.microhowto.info/howto/perform_an_unattended_installation_of_a_debian_package.html
#

# install waterfox
export DEBIAN_FRONTEND=noninteractive
sudo DEBIAN_FRONTEND=noninteractive apt-get install -q -y waterfox-locale-en waterfox-classic;

# setup additional link
isWaterfoxInstalled=$(which waterfox-classic|wc -l);
if [[ "1" == "${isWaterfoxInstalled}" ]]; then
	waterfoxPath=$(which waterfox-classic);
	if [[ "/usr/bin/waterfox" != "${waterfoxPath}" ]]; then
		sudo ln -sf "${waterfoxPath}" /usr/bin/waterfox;
	fi
fi

# Create separate shortcut for private browsing
# this makes it wasy to add a dedicated private browsing
# icon to the panel later

CHROME_WINDOWS_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";
WATERFOX_MENU_LINK="/usr/share/applications/waterfox-classic.desktop";
PRIVATE_MENU_LINK="/usr/share/applications/waterfox-private.desktop";
PRIVATE_ICON_NAME="private-browsing";
PRIVATE_ICON_PATH="/usr/share/icons/${PRIVATE_ICON_NAME}.png";

if [[ "1" == "${isWaterfoxInstalled}" ]]; then
	echo "Checking for successful install...";
	echo "   PRIVATE_ICON_PATH:    '${PRIVATE_ICON_PATH}'";
	echo "   WATERFOX_MENU_LINK:   '${WATERFOX_MENU_LINK}'";
	echo "   PRIVATE_MENU_LINK:    '${PRIVATE_MENU_LINK}'";

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
		fi
		sudo chown root:root "${PRIVATE_MENU_LINK}";
		sudo chmod a+rx "${PRIVATE_MENU_LINK}";
	fi
fi
