#!/bin/bash
TURN_ON_FIREWALL="false";

SCRIPT_DIR="$( cd "$( /usr/bin/dirname "${BASH_SOURCE[0]}" )" && /bin/pwd )";
echo "SCRIPT_DIR: ${SCRIPT_DIR}";

#get sudo prompt out of the way
sudo ls -acl >/dev/null;

#Define vars that will be used later
ENABLE_ON_DEMAND_ONLY_SERVICE="false";
USER_DESKTOP_DIR="${HOME}/Desktop";
SHORTCUT_FILENAME="com.teamviewer.TeamViewer.desktop";
DESKTOP_SHORTCUT="${USER_DESKTOP_DIR}/${SHORTCUT_FILENAME}";
START_MENU_SHORTCUT="/usr/share/applications/${SHORTCUT_FILENAME}";

# check for chroot environment
echo "Checking for chroot environment ...";
isChroot="false";
if [[ "root" == "${USER}" && "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]; then
	# if chroot, then change "Desktop" to mean
	# /etc/skel/Desktop rather than /root/Desktop
	USER_DESKTOP_DIR="/etc/skel/Desktop";

	# make sure desktop exists
	sudo mkdir -p "${USER_DESKTOP_DIR}" 2>&1 >/dev/null;
	sudo chown -R root:root "${USER_DESKTOP_DIR}";
	sudo chown 770 "${USER_DESKTOP_DIR}";

	isChroot="true";

	# update desktop shortcut path
	DESKTOP_SHORTCUT="${USER_DESKTOP_DIR}/${SHORTCUT_FILENAME}";
fi

#Remove any old versions of TeamViewer first (keep configs, if they exist)
echo "Removing old versions (if present) ...";
sudo apt-get remove -y teamviewer 2>/dev/null;
sudo rm "${START_MENU_SHORTCUT}" 2>/dev/null;
rm "${DESKTOP_SHORTCUT}" 2>/dev/null;
rm "${USER_DESKTOP_DIR}/TeamViewer.desktop" 2>/dev/null;
find "${USER_DESKTOP_DIR}" -type f -iname '*TeamViewer*.desktop' -delete 2>/dev/null;

# install initial dependencies
sudo apt-get update 2>/dev/null >/dev/null;
sudo apt-get install -y qml-module-qtquick-controls qml-module-qtquick-dialogs qml-module-qtquick-layouts qml-module-qtquick-privatewidgets 2>/dev/null >/dev/null;

#change to temp dir for downloading
cd /tmp

echo "";
echo "================================================================";
echo "Installing TeamViewer...";
echo "================================================================";

# TEAMVIEWER
# http://sourcedigit.com/17776-install-teamviewer-on-ubuntu-15-10-via-ppa-apt-get-command-line/
# https://www.linuxbabe.com/desktop-linux/install-teamviewer-ubuntu-16-04-xenial-xerus

echo "Downloading TeamViewer DEB file from official site ...";
TEAMVIEWER_DEB_LINK="https://download.teamviewer.com/download/linux/teamviewer_amd64.deb";
wget "${TEAMVIEWER_DEB_LINK}";

echo "Checking DEB dependencies ...";
DEPENDENCIES_LIST_RAW=$(dpkg -I teamviewer*.deb | grep Depends);
echo "   DEPENDENCIES_LIST_RAW: ${DEPENDENCIES_LIST_RAW}";
DEPENDENCIES_LIST_CLEANED=$(echo "${DEPENDENCIES_LIST_RAW:10}" | perl -pe 's/\([^\(\)]+\)|\||,//g' 2>/dev/null | perl -pe 's/[\S]*teamviewer[\S]*//g' 2>/dev/null | sed -E 's/\s+/ /g' >/dev/null);
echo "   DEPENDENCIES_LIST_CLEANED: ${DEPENDENCIES_LIST_CLEANED}";

echo "Determining major version ...";
MAJOR_VERSION="";
MAJOR_VERSION_RAW=$(dpkg-deb -I  teamviewer_amd64.deb  | grep Version | perl -pe "s/^.*Version:\D+([0-9]+).*$/\$1/g" 2>/dev/null);
if [[ $MAJOR_VERSION_RAW =~ ^[0-9][0-9]*$ ]]; then
	MAJOR_VERSION="${MAJOR_VERSION_RAW}";
fi

echo "Attempting to install TeamViewer ${MAJOR_VERSION} dependencies ...";
sudo apt-get install -y ${DEPENDENCIES_LIST_CLEANED};
TEAMVIEWER_DEPENDENCIES_OK="$?";
if [[ "0" == "${TEAMVIEWER_DEPENDENCIES_OK}" ]]; then
	echo "TeamViewer ${MAJOR_VERSION} dependencies installed successfully.";
else
	echo "TeamViewer ${MAJOR_VERSION} dependencies install encountered an error.";
fi

echo "Attempting to install TeamViewer ${MAJOR_VERSION} ...";
sudo dpkg -i teamviewer*.deb;
rm ./teamviewer*.deb;

if [[ ! -L "${START_MENU_SHORTCUT}" && ! -f "${START_MENU_SHORTCUT}"  ]]; then
	# if the predefined path does not exist, then check for one with a different name...
	startMenuShortcutExists=$(find /usr/share/applications \( -type f -o -type l \) -iname '*teamviewer*'|wc -l);
	if [[ "0" != "${startMenuShortcutExists}" ]]; then
		START_MENU_SHORTCUT=$(find /usr/share/applications \( -type f -o -type l \) -iname '*teamviewer*'|head -1);
	fi
fi

#create desktop shortcut if it doesn't exist
echo "Checking for desktop shortcut ...";
if [[ ! -f "${DESKTOP_SHORTCUT}" ]]; then
	if [[ -f "${START_MENU_SHORTCUT}" ]]; then
		# If the menu shortcut is just a symlink, make sure the real file has execute perms
		if [[ -L "${START_MENU_SHORTCUT}" ]]; then
			REAL_PATH=$(readlink -f "${START_MENU_SHORTCUT}");
			sudo chmod a+rx "${REAL_PATH}";
		fi

		#if start menu shortcut exists then just copy that
		cp -a "${START_MENU_SHORTCUT}" "${DESKTOP_SHORTCUT}";

	elif [[ -f "/opt/teamviewer/tv_bin/desktop/com.teamviewer.TeamViewer.desktop" ]]; then
		cp -a -t "${USER_DESKTOP_DIR}" "/opt/teamviewer/tv_bin/desktop/com.teamviewer.TeamViewer.desktop";

	elif [[ -f "/opt/teamviewer/tv_bin/script/teamviewer" ]]; then
		#otherwise, create desktop shortcut from template
		touch "${DESKTOP_SHORTCUT}";
		echo '#!/usr/bin/env xdg-open' >> "${DESKTOP_SHORTCUT}";
		echo '[Desktop Entry]' >> "${DESKTOP_SHORTCUT}";
		echo 'Version=1.0' >> "${DESKTOP_SHORTCUT}";
		echo 'Encoding=UTF-8' >> "${DESKTOP_SHORTCUT}";
		echo 'Type=Application' >> "${DESKTOP_SHORTCUT}";
		echo 'Categories=Network;' >> "${DESKTOP_SHORTCUT}";
		echo '' >> "${DESKTOP_SHORTCUT}";
		echo "Name=TeamViewer ${MAJOR_VERSION}" >> "${DESKTOP_SHORTCUT}";
		echo 'Comment=Remote control and meeting solution.' >> "${DESKTOP_SHORTCUT}";
		echo 'Exec=/opt/teamviewer/tv_bin/script/teamviewer' >> "${DESKTOP_SHORTCUT}";
		echo '' >> "${DESKTOP_SHORTCUT}";
		echo '# This icon might be overridden by other icon themes (e.g. breeze).' >> "${DESKTOP_SHORTCUT}";
		echo 'Icon=TeamViewer' >> "${DESKTOP_SHORTCUT}";
		echo '' >> "${DESKTOP_SHORTCUT}";
		echo '# This icon should always be the default TeamViewer icon.' >> "${DESKTOP_SHORTCUT}";
		echo '#Icon=TeamViewer' >> "${DESKTOP_SHORTCUT}";
		echo "Name[en_US]=TeamViewer ${MAJOR_VERSION}" >> "${DESKTOP_SHORTCUT}";
	fi
fi
sudo chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${DESKTOP_SHORTCUT}";
sudo chmod 755 "${DESKTOP_SHORTCUT}";

echo "Setting default config files ...";

if [[ "" != "${SCRIPT_DIR}" && "${SCRIPT_DIR}/usr/bin/launch-teamviewer" ]]; then
	sudo cp -a -t /usr/bin "${SCRIPT_DIR}/usr/bin/launch-teamviewer";
	sudo chown root:root /usr/bin/launch-teamviewer;
	sudo chmod 755 /usr/bin/launch-teamviewer;

	if [[ -f /usr/bin/launch-teamviewer ]]; then
		sudo find /usr/share/applications \( -type f -o -type l \) -iname '*teamviewer*' -exec sed -Ei "s|^(Exec)=.*|\1=/usr/bin/launch-teamviewer|gi" "{}" \;;
	fi
fi

# if the desktop file is a symlink, then make sure the source file has correct perms; otherwise, make sure desktop file has them
if [[ -f "${DESKTOP_SHORTCUT}" ]]; then
	if [[  -L "${DESKTOP_SHORTCUT}" ]]; then
		REAL_PATH=$(readlink -f "${DESKTOP_SHORTCUT}");
		sudo chmod a+rx "${REAL_PATH}";
	else
		sudo chmod a+rx "${DESKTOP_SHORTCUT}";
	fi

	NAME_HAS_VERSION=$(grep -P "^Name.*=TeamViewer ${MAJOR_VERSION}" "${DESKTOP_SHORTCUT}"|wc -l);
	if [[ "0" == "${NAME_HAS_VERSION}" ]]; then
		sudo sed -E -i "s/^(Name[^=]*)=(TeamViewer).*/\\1=\\2 ${MAJOR_VERSION}/g" "${DESKTOP_SHORTCUT}";
	fi

	if [[ -f /usr/bin/launch-teamviewer ]]; then
		sudo sed -Ei "s|^(Exec)=.*|\1=/usr/bin/launch-teamviewer|gi" "${DESKTOP_SHORTCUT}";
		sudo chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${DESKTOP_SHORTCUT}";
	fi
fi

#Update settings to attempt to auto-accept EULA popup
sudo mkdir /etc/teamviewer 2>/dev/null;
sudo chmod 0755 /etc/teamviewer;
HAS_SETTING=$(grep -P '^\[int32\] EulaAccepted' /etc/teamviewer/global.conf 2>/dev/null | wc -l);
if [[ "0" == "${HAS_SETTING}" ]]; then
	echo "[int32] EulaAccepted = 1" | sudo tee -a /etc/teamviewer/global.conf >/dev/null;
else
	sudo sed -i 's|\(\[int32\] EulaAccepted =\).*$|\1 1|g' /etc/teamviewer/global.conf;
fi

HAS_SETTING=$(grep -P '^\[int32\] LicenseType' /etc/teamviewer/global.conf 2>/dev/null | wc -l);
if [[ "0" == "${HAS_SETTING}" ]]; then
	echo "[int32] LicenseType = 10000" | sudo tee -a /etc/teamviewer/global.conf >/dev/null;
else
	sudo sed -i 's|\(\[int32\] LicenseType =\).*$|\1 10000|g' /etc/teamviewer/global.conf;
fi

USER_TEAMVIEWER_CONFIG_DIR="${HOME}/.config/teamviewer";
if [[ "true" == "${isChroot}" ]]; then
	USER_TEAMVIEWER_CONFIG_DIR="/etc/skel/.config/teamviewer";
fi
mkdir -p "${USER_TEAMVIEWER_CONFIG_DIR}" 2>/dev/null;
touch "${USER_TEAMVIEWER_CONFIG_DIR}/client.conf";

HAS_SETTING=$(grep -P '^\[int32\] MsgBoxDontShow' "${USER_TEAMVIEWER_CONFIG_DIR}/client.conf" 2>/dev/null | wc -l);
if [[ "0" == "${HAS_SETTING}" ]]; then
	echo '[int32] MsgBoxDontShow\QuitWithAutostart = 1' | tee -a "${USER_TEAMVIEWER_CONFIG_DIR}/client.conf";
else
	sudo sed -i 's|\(\[int32\] MsgBoxDontShow\\QuitWithAutostart =\).*$|\1 1|g' "${USER_TEAMVIEWER_CONFIG_DIR}/client.conf";
fi

HAS_SETTING=$(grep -P '^\[int32\] MsgBoxDontShow' "/etc/skel/.config/teamviewer/client.conf" 2>/dev/null | wc -l);
if [[ "0" == "${HAS_SETTING}" ]]; then
	mkdir -p "/etc/skel/.config/teamviewer" 2>/dev/null;
	echo '[int32] MsgBoxDontShow\QuitWithAutostart = 1' | sudo tee -a "/etc/skel/.config/teamviewer/client.conf";
else
	sudo sed -i 's|\(\[int32\] MsgBoxDontShow\\QuitWithAutostart =\).*$|\1 1|g' "/etc/skel/.config/teamviewer/client.conf";
fi

if [[ "true" == "${TURN_ON_FIREWALL}" ]]; then
	UFW_STATUS=$(sudo ufw status|head -1|sed -E 's/^Status: //g');
	if [[ "inactive" == "${UFW_STATUS}" ]]; then
		#turn on firewall
		echo "Turning on ufw firewall back on...";
		sudo ufw enable;
	fi
fi

#if [[ "true" == "${ENABLE_ON_DEMAND_ONLY_SERVICE}" ]]; then
	# /usr/share/applications/com.teamviewer.TeamViewer.desktop
	#
	#[Desktop Entry]
	#Version=1.0
	#Encoding=UTF-8
	#Type=Application
	#Categories=Network;
	#
	#Name=TeamViewer
	#Comment=Remote control and meeting solution.
	#Exec=/opt/teamviewer/tv_bin/script/teamviewer
	#
	#Icon=TeamViewer

	# pg teamview
	#1374 /opt/teamviewer/tv_bin/teamviewerd -d

	# fix-teamviewer.sh:
	#sudo systemctl restart teamviewerd.service;
#fi

