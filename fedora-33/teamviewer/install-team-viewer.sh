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
sudo dnf erase -y teamviewer 2>/dev/null;
sudo rm "${START_MENU_SHORTCUT}" 2>/dev/null;
rm "${DESKTOP_SHORTCUT}" 2>/dev/null;
rm "${USER_DESKTOP_DIR}/TeamViewer.desktop" 2>/dev/null;
find "${USER_DESKTOP_DIR}" -type f -iname '*TeamViewer*.desktop' -delete 2>/dev/null;

# install initial dependencies
sudo dnf install -q -y qt5-qtbase qt5-qtbase-gui qt5-qtdeclarative qt5-qtdeclarative qt5-qtquickcontrols qt5-qtquickcontrols qt5-qtwebkit qt5-qtx11extras;

#change to temp dir for downloading
tempDir=$(mktemp -d /tmp/XXXX);
cd "${tempDir}";

echo "";
echo "================================================================";
echo "Installing TeamViewer...";
echo "================================================================";

#	https://community.teamviewer.com/English/kb/articles/30708-how-to-install-teamviewer-on-red-hat-and-centos
echo "Downloading TeamViewer key file from official site ...";
wget https://download.teamviewer.com/download/linux/signature/TeamViewer2017.asc
sudo rpm --import TeamViewer2017.asc


echo "Downloading TeamViewer RPM file from official site ...";
TEAMVIEWER_RPM_LINK="https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm";
wget "${TEAMVIEWER_RPM_LINK}";

# https://stackoverflow.com/questions/19077538/check-rpm-dependencies
# https://stackoverflow.com/questions/13876875/how-to-make-rpm-auto-install-dependencies
# https://phoenixnap.com/kb/how-to-install-rpm-file-centos-linux
# https://medium.com/@mangeshdhulap26/dnf-commands-for-rpm-package-management-in-fedora-linux-c0c9ac373ca0
#	ended up just getting a list manually using dnf, however it automatically tries to add version numbers
#	whereas i prefer to just get whatever the default version in the repo is...
#

# There is an issue with DNF where when the following conditions are met:
#	1) configured with 3rd-party repo (ex: asbru-cm, wine, etc)
#	2) the repo maintainer has a weird GPG or did not setup things up well (e.g. asbru-cm)
#	3) DNF is run by a non-root user without sudo, such as for the search/list/deplist/etc commands
#
# then DNF can sometimes *PROMPT* the NON-ROOT user about importing GPG keys ... which breaks automation/scripting.
# In an attempt to avoid this, we are running 'dnf deplist' as root (sudo)
#
echo "Checking RPM dependencies ...";
DEPENDENCIES_LIST=$(sudo dnf deplist --nogpgcheck --cacheonly --assumeno --quiet teamviewer*.rpm 2>/dev/null|grep -Pv 'bash\-|glibc\-|dbus\-libs\-'|grep provider|sort -u|sed -E 's/^\s*provider:\s+|\s+$|\.fc33|\.x86_64|\.i686|\.alpha[0-9]*//g' | sed -E 's/\-[1-9]\..*$//g' | tr '\n' ' ');
echo "   DEPENDENCIES_LIST: ${DEPENDENCIES_LIST}";

echo "Determining major version ...";
MAJOR_VERSION="";
MAJOR_VERSION_RAW=$(sudo dnf deplist --nogpgcheck --cacheonly --assumeno --quiet teamviewer*.rpm 2>/dev/null|grep package|sed -E 's/^\s*package:\s+teamviewer[^1-9]*([1-9][0-9]*).*$/\1/g');
if [[ $MAJOR_VERSION_RAW =~ ^[0-9][0-9]*$ ]]; then
	MAJOR_VERSION="${MAJOR_VERSION_RAW}";
fi

echo "Attempting to install TeamViewer ${MAJOR_VERSION} dependencies ...";
sudo dnf install -y ${DEPENDENCIES_LIST};
TEAMVIEWER_DEPENDENCIES_OK="$?";
if [[ "0" == "${TEAMVIEWER_DEPENDENCIES_OK}" ]]; then
	echo "TeamViewer ${MAJOR_VERSION} dependencies installed successfully.";
else
	echo "TeamViewer ${MAJOR_VERSION} dependencies install encountered an error.";
fi

echo "Attempting to install TeamViewer ${MAJOR_VERSION} ...";
sudo rpm -i teamviewer*.rpm;
rm ./teamviewer*.rpm;

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


# Prevent issue where non-root users get prompted by dnf to download GPG key during query operations
# such as 'dnf search', 'dnf list', and 'dnf deplist' among others
# this can be resolved by fixing bad permissions under /var/cache/dnf
sudo find /var/cache/dnf -type d -iregex '.*teamviewer.*' -not \( -perm /o+r -perm /o+x -perm /g+r -perm /g+x \) -exec chmod 755 "{}" \;;
sudo find /var/cache/dnf -type f -iregex '.*teamviewer.*' -not \( -perm /o+r -perm /g+r \) -exec chmod 644 "{}" \;;

# around begining of of May 2021 (confirmed on May 4, possibly occurred several days prior)
# I started seeing the following error message when I would run dnf commands as non-root (e.g. dnf search xxx)
#
#	$ dnf search gradle
#	Invalid configuration value: failovermethod=priority in /etc/yum.repos.d/teamviewer.repo;
#	Configuration: OptionBinding with id "failovermethod" does not exist
#
# I tried deleting the file and reinstalling teamviewer but that did not resolve.
# After looking around online, I found a few pages noting that the 'failovermethod' option was no longer valid.
#
# according to https://bugzilla.redhat.com/show_bug.cgi?id=1653831
#		This was a thing brought in by yum compatibility. From the yum.conf man page:
#			failovermethod Either `roundrobin' or `priority'.
#
#			'roundrobin' randomly selects a URL out of the list of URLs to start with and proceeds through each of
#			them as it encounters a failure contacting the host.
#
#			'priority' starts from the first baseurl listed and reads through them sequentially.
#
#            failovermethod defaults to 'roundrobin' if not specified.
# ------------------
#	I did not get any hits for man dnf.conf|grep failovermethod
#	and I do not seem to have any manual entries for yum.conf under f33.
# ------------------
#
# according to https://bugzilla.redhat.com/show_bug.cgi?id=1653831
#	Fedora 34 upgrade gets this:
#		dnf system-upgrade download --refresh --releasever=34 --best --allowerasing
#		Invalid configuration value: failovermethod=roundrobin in /etc/yum.repos.d/livna.repo; Configuration: OptionBinding with id "failovermethod" does not exist
#		Invalid configuration value: failovermethod=roundrobin in /etc/yum.repos.d/livna.repo; Configuration: OptionBinding with id "failovermethod" does not exist
#		Invalid configuration value: failovermethod=roundrobin in /etc/yum.repos.d/livna.repo; Configuration: OptionBinding with id "failovermethod" does not exist
#
# according to https://bugzilla.redhat.com/show_bug.cgi?id=1671954
#	Can you please remove configuration option "failovermethod" from .repo files.
#	Because DNF no longer supports this option.
#
# according to https://ask.fedoraproject.org/t/issues-with-dnf-upgrade-on-fedora-30-failed-to-synchronize-cache-for-repo/1142
#	could you please do: dnf clean all
#
#	-> per man dnf:
#	Command: clean
#		Performs cleanup of temporary files kept for repositories. This includes
#		any such data left behind from disabled or removed repositories
#		as well as for different distribution release versions.
#
#	$ sudo dnf clean all
#	Invalid configuration value: failovermethod=priority in /etc/yum.repos.d/teamviewer.repo; Configuration: OptionBinding with id "failovermethod" does not exist
#	131 files removed
#
#	$ dnf search neofetch
#	Invalid configuration value: failovermethod=priority in /etc/yum.repos.d/teamviewer.repo; Configuration: OptionBinding with id "failovermethod" does not exist
#	Error: Cache-only enabled but no cache for 'fedora'
#
#
#	-> so it looks like 'roundrobin' and 'priority' are both out and I should probably just delete
#		the 'failovermethod' value altogether
#
if [[ -f /etc/yum.repos.d/teamviewer.repo ]]; then
	sudo sed -Ei '/^failovermethod=\w+$/d' /etc/yum.repos.d/teamviewer.repo;
fi

