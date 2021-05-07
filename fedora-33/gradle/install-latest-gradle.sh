#!/bin/bash

# https://www.itzgeek.com/how-tos/linux/ubuntu-how-tos/how-to-install-gradle-on-ubuntu-18-04-16-04-linux-mint-19-debian-9.html
# https://gradle.org/install/

# get the sudo prompt out of the way up front
sudo ls -acl 2>/dev/null >/dev/null;

# if an older version of gradle is installed from the central repo, remove it first
sudo dnf remove --nogpgcheck --quiet -y gradle 2>/dev/null >/dev/null;

sudo dnf install --nogpgcheck --quiet -y unzip  2>/dev/null >/dev/null;

if [[ "" == "${USER_AGENT}" ]]; then
	USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36";
fi

if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" && '--system-install' != "$1" ]]; then
	source "$HOME/.sdkman/bin/sdkman-init.sh";
	sdk install gradle ${newestVersion};
else
	tempDir=$(mktemp -d '/tmp/XXXX');
	cd "${tempDir}";

	releasesPageSource=$(curl -L -A "${USER_AGENT}" https://gradle.org/releases/ 2>/dev/null);
	if [[ '0' != "$?" || '' == "${releasesPageSource}" ]]; then
		echo "E: Failed to fetch releases page source";
		exit -1;
	fi

	newestVersion=$(echo "${releasesPageSource}"|grep -P '<a name="([.\d]+)">'|sed -E 's|^.*<a name="([.0-9]+)".*$|\1|g'|sort -n|tail -1);
	if [[ "${#newestVersion}" == "${#releasesPageSource}" ]]; then
		echo "E: Failed to parse newest version from releases page source";
		exit -2;

	elif [[ ! ${newestVersion} =~ ^[1-9][\.0-9]*[0-9]$ ]]; then
		echo "E: Failed to parse valid version number from releases page source. Found: '${newestVersion}'";
		exit -3;
	fi

	wget --user-agent="${USER_AGENT}" "https://services.gradle.org/distributions/gradle-${newestVersion}-bin.zip";
	if [[ '0' != "$?" || ! -s "./gradle-${newestVersion}-bin.zip" ]]; then
		echo "E: Failed to download latest gradle archive";
		exit -1;
	fi

	sudo mkdir /opt/gradle 2>/dev/null;
	sudo chmod 755 /opt/gradle;
	if [[ -d  /opt/gradle/gradle-${newestVersion} ]]; then
		# if reinstalling, then remove previous copy
		sudo rm -r /opt/gradle/gradle-${newestVersion};
	fi

	sudo unzip -d /opt/gradle gradle-${newestVersion}-bin.zip;
	if [[ -f /opt/gradle/gradle-${newestVersion}/bin/gradle ]]; then
		sudo ln -sf /opt/gradle/gradle-${newestVersion}/bin/gradle /usr/bin/gradle;
	fi
fi
