#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

if [[ "" == "${USER_AGENT}" ]]; then
	USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36";
fi

# get the sudo prompt out of the way up front
sudo ls -acl 2>/dev/null >/dev/null;

# first install zulucrypt: it is fully compatible with veracrypt volumes and will work
# as a nice fail-safe if veracrypt runs into any build errors or other issues
#
#	https://mhogomchungu.github.io/zuluCrypt/
#
#	https://www.linuxquestions.org/questions/linux-newbie-8/veracrypt-vs-zulucypt-4175612942/
#	-> this covers difference between the two
#	-> basically zulucrypt is GPL and can read and create veracrypt and truecrypt volumes
#		(as well as several others) but it is LINUX ONLY. Whereas veracrypt has a license that
#		prevents it from being included in many distros (like Fedora and Debian), and
#		supports Windows/Linux/Mac + RaspPi Linux. Having both shouldn't hurt anything
#		and
#
sudo dnf install --nogpgcheck --quiet -y zulucrypt zulucrypt-console zulucrypt-libs zulucrypt-doc 2>/dev/null >/dev/null;


#
#	https://www.addictivetips.com/ubuntu-linux-tips/use-veracrypt-on-linux/
#
#	Fedora
#		sudo dnf copr enable scx/veracrypt
#		sudo dnf install veracrypt.x86_64 -y
#
#	OpenSUSE
#		Grab the latest version of VeraCrypt from the OBS. All curren
#		https://software.opensuse.org/package/veracrypt
#
#	Download binary releases:
#		https://www.veracrypt.fr/en/Downloads.html
#		https://veracrypt.codeplex.com/releases/view/631440
#		wget https://launchpad.net/veracrypt/trunk/1.24-update7/+download/veracrypt-1.24-Update7-setup.tar.bz2
#		or
#		wget https://launchpad.net/veracrypt/trunk/1.24-update7/+download/veracrypt-1.24-Update7-openSUSE-15-x86_64.rpm
#
#	As of May 6th, 2021 the current version for Linux is:
#		1.24-Update7 (Friday August 7, 2020)
#
#	Build from source:
#	https://github.com/veracrypt/VeraCrypt
#
# ------------------------------------------------------------------------
#	Requirements for Building VeraCrypt for Linux and Mac OS X:
#
#		GNU Make
#			-> package: make (fedora33; v: 1:4.3-2.fc33)
#		GNU C++ Compiler 4.0 or compatible
#			-> package: gcc (fedora33; v: 10.3.1-1.fc33)
#		Apple Xcode (Mac OS X only)
#			-> not applicable for linux builds
#		YASM 1.3.0 or newer (Linux only, x86/x64 architecture only)
#			-> package: yasm (fedora33; v: 1.3.0-12.fc33)
#		pkg-config
#			-> package: pkgconf-pkg-config (fedora33; v: 1.7.3-5.fc33)
#		wxWidgets 3.0 shared library and header files installed or wxWidgets 3.0 library source code (available at https://www.wxwidgets.org)
#			-> package: wxBase3 (fedora33; v: 3.0.5.1-2.fc33)
#		FUSE library and header files (available at https://github.com/libfuse/libfuse and https://osxfuse.github.io/)
#			-> based on https://osxfuse.github.io description the above should say "OR" instead of "libfuse and osxfuse"
#			-> as the name implies, osxfuse appears to be mac-only so shouldn't be needed for linux build
#			-> assuming we only need libfuse
#			best guess, we want these:
#				fuse3.x86_64 : File System in Userspace (FUSE) v3 utilities
#				fuse3-devel.i686 : File System in Userspace (FUSE) v3 devel files
#				fuse3-devel.x86_64 : File System in Userspace (FUSE) v3 devel files
#				fuse3-libs.x86_64 : File System in Userspace (FUSE) v3 libraries
#				fuse3-libs.i686 : File System in Userspace (FUSE) v3 libraries
#			-> fuse3 = 3.9.4-1.fc33
# ------------------------------------------------------------------------

echo "E: NOT IMPLEMENTED";
exit -3;


tempDir=$(mktemp -d '/tmp/XXXX');
cd "${tempDir}";

releasesPageSource=$(curl -L -A "${USER_AGENT}" https://www.veracrypt.fr/en/Downloads.html 2>/dev/null);
if [[ '0' != "$?" || '' == "${releasesPageSource}" ]]; then
	echo "E: Failed to fetch releases page source";
	exit -1;
fi

archiveLink=$(echo "${releasesPageSource}"|grep -P '<a href="([^"]+setup\.tar\.\w+)">'|grep -Pvi 'LEGACY|Source|freebsd'|sed 's/&#43;/+/g'|sed -E 's|^.*<a href="([^"]+setup\.tar\.\w+)".*$|\1|g'|sort -n|head -1);
if [[ "${#archiveLink}" == "${#releasesPageSource}" ]]; then
	echo "E: Failed to parse archiveLink from releases page source";
	exit -2;

elif [[ ! ${archiveLink} =~ ^https?://[-+/.A-Za-z0-9_]*veracrypt[-+/.A-Za-z0-9_]*setup\.tar\.[bgx]z2?$ ]]; then
	echo "E: Failed to parse valid archiveLink from releases page source. Found: '${archiveLink}'";
	exit -3;
fi

archiveFileName="$(basename "${archiveLink}")";
wget --user-agent="${USER_AGENT}" "${archiveLink}";
if [[ '0' != "$?" || ! -s "${archiveFileName}" ]]; then
	echo "E: Failed to download latest gradle archive";
	exit -1;
fi

openSuseLink=$(echo "${releasesPageSource}"|grep -P '<a href="([^"]+openSUSE[^"]+.rpm)">'|grep -v console|sed 's/&#43;/+/g'|sed -E 's|^.*<a href="([^"]+openSUSE[^"]+\.rpm)".*$|\1|g'|sort -n|head -1);
if [[ "${#openSuseLink}" == "${#releasesPageSource}" ]]; then
	echo "E: Failed to parse openSuseLink from releases page source";
	exit -2;

elif [[ ! ${openSuseLink} =~ ^https?://[-+/.A-Za-z0-9_]*openSUSE[-+/.A-Za-z0-9_]*\.rpm$ ]]; then
	echo "E: Failed to parse valid openSuseLink from releases page source. Found: '${openSuseLink}'";
	exit -3;
fi

rpmFileName="$(basename "${openSuseLink}")";
wget --user-agent="${USER_AGENT}" "${openSuseLink}";
if [[ '0' != "$?" || ! -s "${rpmFileName}" ]]; then
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
