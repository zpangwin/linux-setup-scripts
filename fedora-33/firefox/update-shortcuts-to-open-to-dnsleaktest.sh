#!/bin/bash

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

APPLICATION_DISPLAY_NAME="Firefox";
DESKTOP_LINK="${HOME}/Desktop/firefox.desktop";
ETC_SKEL_DESKTOP_LINK="/etc/skel/Desktop/firefox.desktop";
APPLICATION_MENU_LINK="/usr/share/applications/firefox.desktop";
PRIVATE_DEFAULT_PAGE="https://www.dnsleaktest.com/";

APPLICATION_BIN_NAME="firefox";
IS_APPLICATION_BIN_ON_PATH=$(which "${APPLICATION_BIN_NAME}" 2>/dev/null|wc -l);
if [[ "0" == "${IS_APPLICATION_BIN_ON_PATH}" ]]; then
	echo "ERROR: ${APPLICATION_DISPLAY_NAME} does not appear to be installed or is not reachable on the \$PATH variable."
	echo "Aborting script";
	exit;
fi

# Debug
echo "Checking for successful install...";
echo "   APPLICATION_MENU_LINK:   '${APPLICATION_MENU_LINK}'";
echo "   ETC_SKEL_DESKTOP_LINK:   '${ETC_SKEL_DESKTOP_LINK}'";
echo "   DESKTOP_LINK:   '${DESKTOP_LINK}'";

# Make sure system menu shortcut exists
if [[ -f "${APPLICATION_MENU_LINK}" ]]; then
	# See below for why "-private-window" is also excluded (basically it doesn't work so no sense modifying it)
	missingLink=$(grep -P '^Exec=' "${APPLICATION_MENU_LINK}"|grep -Pv '[-]private[-]window|ProfileManager'|grep -v "${PRIVATE_DEFAULT_PAGE}"|wc -l);
	if [[ '' != "$missingLink" && $missingLink =~ ^[1-9][0-9]*$ && 0 != $missingLink ]]; then
		echo "Updating shared app menu shortcut ...";

		# Make backup
		sudo cp -a "${APPLICATION_MENU_LINK}" "${APPLICATION_MENU_LINK}.$(date +'%Y-%-m-%d-%H%M%S').bak"

		# change the normal/default command
		sudo sed -Ei "s|^(Exec=\\S*) [^-]*\$|\\1 -url ${PRIVATE_DEFAULT_PAGE}|g" "${APPLICATION_MENU_LINK}";

		# change the "Open in New Window" command
		sudo sed -Ei "s|^(Exec=\\S*.*[-]{2}new[-]window) .*\$|\\1 -url ${PRIVATE_DEFAULT_PAGE}|g" "${APPLICATION_MENU_LINK}";

		# https://developer.mozilla.org/en-US/docs/Mozilla/Command_Line_Options#-private-toggle_url
		#  "Does not work in Firefox 31 on linux mint 17 nor on Firefox 48 on Windows 7. URL opens in a non-private window."
		#  -> Still not fixed as of Firefox 85 on Fedora 33.
		#
		# SINCE using -private-window URL, -private-window -url URL, etc
		# all open as a tab in NON-private window, it is best to just not modify the
		# Exec command for -private-window

		sudo chown root:root "${APPLICATION_MENU_LINK}";
		sudo chmod a+rx "${APPLICATION_MENU_LINK}";
	fi
fi

# Make sure system menu shortcut exists
if [[ -f "${ETC_SKEL_DESKTOP_LINK}" ]]; then
	# See below for why "-private-window" is also excluded (basically it doesn't work so no sense modifying it)
	missingLink=$(grep -P '^Exec=' "${ETC_SKEL_DESKTOP_LINK}"|grep -Pv '[-]private[-]window|ProfileManager'|grep -v "${PRIVATE_DEFAULT_PAGE}"|wc -l);
	if [[ '' != "$missingLink" && $missingLink =~ ^[1-9][0-9]*$ && 0 != $missingLink ]]; then
		echo "Updating /etc/skel desktop shortcut ...";

		# Make backup
		sudo cp -a "${ETC_SKEL_DESKTOP_LINK}" "${ETC_SKEL_DESKTOP_LINK}.$(date +'%Y-%-m-%d-%H%M%S').bak"

		# change the normal/default command
		sudo sed -Ei "s|^(Exec=\\S*) [^-]*\$|\\1 -url ${PRIVATE_DEFAULT_PAGE}|g" "${ETC_SKEL_DESKTOP_LINK}";

		# change the "Open in New Window" command
		sudo sed -Ei "s|^(Exec=\\S*.*[-]{2}new[-]window) .*\$|\\1 -url ${PRIVATE_DEFAULT_PAGE}|g" "${ETC_SKEL_DESKTOP_LINK}";

		# https://developer.mozilla.org/en-US/docs/Mozilla/Command_Line_Options#-private-toggle_url
		#  "Does not work in Firefox 31 on linux mint 17 nor on Firefox 48 on Windows 7. URL opens in a non-private window."
		#  -> Still not fixed as of Firefox 85 on Fedora 33.
		#
		# SINCE using -private-window URL, -private-window -url URL, etc
		# all open as a tab in NON-private window, it is best to just not modify the
		# Exec command for -private-window

		sudo chown root:root "${ETC_SKEL_DESKTOP_LINK}";
		sudo chmod a+rx "${ETC_SKEL_DESKTOP_LINK}";
	fi
fi

# Make sure system menu shortcut exists
if [[ -f "${DESKTOP_LINK}" ]]; then
	# See below for why "-private-window" is also excluded (basically it doesn't work so no sense modifying it)
	missingLink=$(grep -P '^Exec=' "${DESKTOP_LINK}"|grep -Pv '[-]private[-]window|ProfileManager'|grep -v "${PRIVATE_DEFAULT_PAGE}"|wc -l);
	if [[ '' != "$missingLink" && $missingLink =~ ^[1-9][0-9]*$ && 0 != $missingLink ]]; then
		echo "Updating desktop shortcut ...";

		# Make backup
		cp -a "${DESKTOP_LINK}" "${DESKTOP_LINK}.$(date +'%Y-%-m-%d-%H%M%S').bak"

		# change the normal/default command
		sed -Ei "s|^(Exec=\\S*) [^-]*\$|\\1 -url ${PRIVATE_DEFAULT_PAGE}|g" "${DESKTOP_LINK}";

		# change the "Open in New Window" command
		sed -Ei "s|^(Exec=\\S*.*[-]{2}new[-]window) .*\$|\\1 -url ${PRIVATE_DEFAULT_PAGE}|g" "${DESKTOP_LINK}";

		# https://developer.mozilla.org/en-US/docs/Mozilla/Command_Line_Options#-private-toggle_url
		#  "Does not work in Firefox 31 on linux mint 17 nor on Firefox 48 on Windows 7. URL opens in a non-private window."
		#  -> Still not fixed as of Firefox 85 on Fedora 33.
		#
		# SINCE using -private-window URL, -private-window -url URL, etc
		# all open as a tab in NON-private window, it is best to just not modify the
		# Exec command for -private-window

		chown root:root "${DESKTOP_LINK}";
		chmod a+rx "${DESKTOP_LINK}";
	fi
fi
