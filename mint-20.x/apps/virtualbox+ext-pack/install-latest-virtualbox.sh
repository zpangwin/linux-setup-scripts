#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

if [[ ! -f "${SCRIPT_DIR_PARENT}/functions.sh" ]]; then
    echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
    exit;
fi
. "${SCRIPT_DIR_PARENT}/functions.sh";

DOWNLOAD_DIR="$HOME/Downloads";
# check for chroot environment
if [[ "root" == "${USER}" && "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]; then
	DOWNLOAD_DIR=$(mktemp -d /tmp/virtualbox-XXXX);
fi

CHROME_WINDOWS_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";

# =========================================================
# See instructions for Debian-based Linux distributions:
# https://www.virtualbox.org/wiki/Linux_Downloads
# =========================================================

echo "Adding keys for virtualbox.org ...";

# add keys for virtualbox.org
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -;
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -;

echo "Adding official PPA for virtualbox.org (if not already present) ...";

# add repo source for virtualbox.org
addCustomSource virtualbox 'deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian bionic contrib';

echo "==========================================================="
echo "Updating apt's local package cache ...";

# update apt's local cache
sudo apt-get update 2>&1 >/dev/null;

echo "Determining newest version of virtualbox from cache ...";

# determine latest virtualbox version available
latestVersion="";
versionsList=($(apt search virtualbox|sed -E 's/^\w+\s+(\S+)\s+.*$/\1/g'|grep -P 'virtualbox\-[\d\.]+'|sed 's/^virtualbox\-//'));

for version in "${versionsList[@]}"; do
	# if version is empty, skip it
	if [[ "" == "${version}" ]]; then
		echo "Found empty version number; skipping ...";
		continue;
	fi
	# if latestVersion isn't set, then set it and skip to next version
	if [[ "" == "${latestVersion}" ]]; then
		latestVersion="${version}";
		continue;
	fi

	if $(dpkg --compare-versions "${version}" "gt" "${latestVersion}"); then
		# if version we're comparing is greater, it becomes the new latest version
		latestVersion="${version}";
	fi
	# either latestVersion has been updated or version <= latestVersion
	# skip to next comparison
	continue;
done

echo "";
commaSepVersions=$(echo "${versionsList[@]}"|sed 's/ /, /g');
echo "Script found that '${latestVersion}' is the newest version out of [${commaSepVersions}]";
if [[ "" == "${latestVersion}" ]]; then
	echo "ERROR: Found empty latestVersion number; aborting ...";
	exit;
fi

# install latest virtual box
echo "Installing virtualbox-${latestVersion} ...";

if [[ "6.1" == "${latestVersion:0:3}" ]]; then
	echo "Applying libvpx5 workaround for Virtualbox 6.1 on Focal ...";

	## Download archive
	##	apt-get download $PKG
	startingDir=$(pwd);
	tempDir=$(mktemp -d /tmp/virtualbox-deb-check-XXXX);
	cd "${tempDir}";

	# this command let you download the package and requirements into the current directory
	apt-get download virtualbox-${latestVersion};

	requiresLibvpx5=$(dpkg -I virtualbox*.deb | grep -i depends | grep -c libvpx5);
	if [[ "1" == "${requiresLibvpx5}" ]]; then
		wget http://archive.ubuntu.com/ubuntu/pool/main/libv/libvpx/libvpx5_1.7.0-3ubuntu0.18.04.1_amd64.deb;
		sudo apt-get install -y ./libvpx5_1.7.0-3ubuntu0.18.04.1_amd64.deb;
	fi
	sudo apt-get install -y ./*.deb

	cd "${startingDir}";
else
	sudo apt-get install --install-recommends -y virtualbox-${latestVersion};
fi

echo "Attempting to download extensions pack for virtualbox-${latestVersion} ...";

# then attempt to download the extensions pack ...
VBOX_DOWNLOADS_PAGE="https://www.virtualbox.org/wiki/Downloads";

echo ''
echo -e "\tFetching extensions pack link from Downloads page:\n\t\t${VBOX_DOWNLOADS_PAGE}";
RAW_HTML_SOURCE=$(/usr/bin/curl --location --user-agent "${CHROME_WINDOWS_UA}" "${VBOX_DOWNLOADS_PAGE}" 2>/dev/null);
if [[ "0" != "$?" ]]; then
	echo "ERROR: curl returned error code of $? while accessing download URL : ${VBOX_DOWNLOADS_PAGE}";
	echo "Aborting script";
	exit;
fi
if [[ "" == "${RAW_HTML_SOURCE}" ]]; then
	echo "ERROR: RAW_HTML_SOURCE was empty; please check download URL : ${VBOX_DOWNLOADS_PAGE}";
	echo "Aborting script";
	exit;
fi

echo '';
echo -e "\tCleaning page source to only showextensions pack links for the virtualbox-${latestVersion} ...";

RAW_PAGE_HTML_SIZE="${#RAW_HTML_SOURCE}";
CLEANED_PAGE_HTML_SOURCE=$(echo "${RAW_HTML_SOURCE}"|/usr/bin/perl -0pe "s/>\s*</>\n</g"|grep -Pi "<a.*${latestVersion}.*vbox-extpack");
CLEANED_PAGE_HTML_SIZE="${#CLEANED_PAGE_HTML_SOURCE}";

echo '';
echo -e '\tParsing download link ...'
EXT_PACK_DOWNLOAD_LINK=$(echo "${CLEANED_PAGE_HTML_SOURCE}"| grep -P "href\S*${latestVersion}\S*vbox-extpack" |/usr/bin/perl -pe 's/^.*href="([^"]+)".*$/$1/g' | /usr/bin/sort -u | /usr/bin/tail -n 1);
if [[ ${#EXT_PACK_DOWNLOAD_LINK} -lt 30 || ${#EXT_PACK_DOWNLOAD_LINK} -gt 300 || "http" != "${EXT_PACK_DOWNLOAD_LINK:0:4}" ]]; then
	# dump source to temp file for debugging...
	echo "${RAW_HTML_SOURCE}" > /tmp/vbox-sh-raw-source.txt
	echo "${CLEANED_PAGE_HTML_SOURCE}" > /tmp/vbox-sh-cleaned-source.txt

	# print error message
	echo "";
	echo "===========================================================================================";
	echo "ERROR: Invalid download link value. The web portion of the script may need to be updated.";
	echo "       Displaying debug info then aborting script";
	echo "===========================================================================================";
	echo "   ------------------------";
	echo "   Variables from script:";
	echo "   ------------------------";
	echo "   VBOX_DOWNLOADS_PAGE=\"${VBOX_DOWNLOADS_PAGE}\";";
	echo "   CHROME_WINDOWS_UA=\"${CHROME_WINDOWS_UA}\";";
	echo "   RAW_HTML_SOURCE=\$(/usr/bin/curl --location --user-agent \"\${CHROME_WINDOWS_UA}\" \"\${VBOX_DOWNLOADS_PAGE}\" 2>/dev/null);";
	echo "   echo \"raw page source size is: \${#RAW_HTML_SOURCE}\";";
	echo "   CLEANED_PAGE_HTML_SOURCE=\$(echo \"\${RAW_HTML_SOURCE}\"|/usr/bin/perl -0pe 's/>\s*</>\n</g'|grep -Pi '<a.*${latestVersion}.*vbox-extpack');";
	echo "   echo \"cleaned page source size is: \${#CLEANED_PAGE_HTML_SOURCE}\";";
	echo "   PAGE_SOURCE_SIZE=\$(/usr/bin/curl --location --user-agent \"\${CHROME_WINDOWS_UA}\" \"\${VBOX_DOWNLOADS_PAGE}\" 2>/dev/null);";
	echo "   EXT_PACK_DOWNLOAD_LINK=\$(echo \"\${CLEANED_PAGE_HTML_SOURCE}\"| grep -P \"href\\S*\${latestVersion}\\S*vbox-extpack\" |/usr/bin/perl -pe 's/^.*href=\"([^\"]+)\".*\$/\$1/g' | /usr/bin/sort -u | /usr/bin/tail -n 1);";
	echo "   echo \"download link size is: \${#EXT_PACK_DOWNLOAD_LINK}\";";
	echo "   echo \"\${RAW_HTML_SOURCE}\" > /tmp/vbox-cli-raw-source.txt";
	echo "   echo \"\${CLEANED_PAGE_HTML_SOURCE}\" > /tmp/vbox-cli-cleaned-source.txt";
	echo "";
	echo "   ------------------------";
	echo "   Values from script:";
	echo "   ------------------------";
	echo "   Raw Page Source Size:      ${RAW_PAGE_HTML_SIZE}"
	echo "   Cleaned Page Source Size:  ${CLEANED_PAGE_HTML_SIZE}"
	echo "   Download Link Size:        ${#EXT_PACK_DOWNLOAD_LINK}";
	echo "   Download Link Value:       '${EXT_PACK_DOWNLOAD_LINK}'";
	echo "";
	echo "   ------------------------";
	echo "   Source dump from script:";
	echo "   ------------------------";
	echo "   cat /tmp/vbox-sh-raw-source.txt";
	echo "   cat /tmp/vbox-sh-cleaned-source.txt";
	echo "";
	echo "   diff /tmp/vbox-sh-raw-source.txt /tmp/vbox-cli-raw-source.txt";
	echo "   diff /tmp/vbox-sh-cleaned-source.txt /tmp/vbox-cli-cleaned-source.txt";
	echo "";

	echo "Aborting extensions pack installation.";
	exit;
fi

#print url
OUTPUT_FILENAME="${EXT_PACK_DOWNLOAD_LINK##*/}";
OUTPUT_FILEPATH="${DOWNLOAD_DIR}/${OUTPUT_FILENAME}";

echo '';
echo -e "\tExtracted EXT_PACK_DOWNLOAD_LINK as: ${EXT_PACK_DOWNLOAD_LINK}";
echo -e "\tOUTPUT_FILENAME: ${OUTPUT_FILENAME}";
echo -e "\tOUTPUT_FILEPATH: ${OUTPUT_FILEPATH}";

if [[ "" == "${OUTPUT_FILENAME}" ]]; then
	echo "ERROR: OUTPUT_FILENAME not captured.";
	echo "Aborting extensions pack installation.";
	exit;
fi
if [[ "" == "${OUTPUT_FILEPATH}" ]]; then
	echo "ERROR: OUTPUT_FILEPATH not captured.";
	echo "Aborting extensions pack installation.";
	exit;
fi

#download the file from der InterWebs
sudo /usr/bin/wget --user-agent "${CHROME_WINDOWS_UA}" "${EXT_PACK_DOWNLOAD_LINK}" --output-document="${OUTPUT_FILEPATH}" 2>/dev/null;
if [[ ! -e "${OUTPUT_FILEPATH}" ]]; then
	echo "ERROR: Failed to download the file from 'EXT_PACK_DOWNLOAD_LINK'";
	echo "The web portion of the script may need to be updated.";
	echo "Aborting extensions pack installation.";
	exit;
fi
echo -e "\tFound downloaded archive at: ${OUTPUT_FILEPATH}";

FILE_SIZE_KB=$(du -k "${OUTPUT_FILEPATH}" | cut -f1)
if [[ "0" == "${FILE_SIZE_KB}" ]]; then
	echo "ERROR: Found 0 byte size for file ${OUTPUT_FILEPATH}";
	echo "The web portion of the script may need to be updated.";
	echo "Aborting extensions pack installation.";
	exit;
fi

has_vbox_manage=$(which VBoxManage|wc -l);
if [[ "1" != "${has_vbox_manage}" ]]; then
	echo "ERROR: VBoxManage is not installed.";
	echo "Please install the extensions pack manually (e.g. double-click it)";
	echo "It can be found at:";
	echo "   ${OUTPUT_FILEPATH}";
	exit;
fi

echo "";
echo "Installing extensions pack ...";

# See
# https://unix.stackexchange.com/questions/289685/how-to-install-virtualbox-extension-pack-to-virtualbox-latest-version-on-linux/289686

echo "y" | sudo VBoxManage extpack install --replace "${OUTPUT_FILEPATH}";

echo "";
echo "===============================================";
echo "Confirm installation ... ";
echo "===============================================";
VBoxManage list extpacks;
echo "===============================================";
is_success=$(VBoxManage list extpacks|grep "${latestVersion}"|wc -l);
if [[ "1" == "${is_success}" ]]; then
	echo "Extensions pack installed successfully!";
else
	echo "Extensions pack not installed; please reinstall manually!";
fi

