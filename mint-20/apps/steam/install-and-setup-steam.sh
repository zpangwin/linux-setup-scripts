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

userAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";

arg1="$1";
if [[ "-h" == "$1" || $arg1 =~ ^\-{1,}help$ ]]; then
	echo "expected usage:";
	echo "   $0 [OPTIONS]";
	echo "";
	echo "OPTIONS:";
	echo "   -h, --help               Display this help page.";
	echo "   -p, --use-ppa            Use PPA; default is to install steam from central repo instead.";
	echo "   -U, --update-only        Update only; just download and install the latest Glorious Eggroll (GE) build of Proton.";
	exit;
fi

usePPA="false";
updateOnly="false";

arg1="$1";
if [[ "-p" == "$1" || $arg1 =~ ^\-{1,}use\-?ppa$ ]]; then
	usePPA="true";
	shift 1;
fi

arg1="$1";
if [[ "-P" == "$1" || $arg1 =~ ^\-{1,}update\-?only$ ]]; then
	updateOnly="true";
	shift 1;
fi

if [[ "true" != "${updateOnly}" ]]; then
	# 32-bit support
	sudo dpkg --add-architecture i386;

	if [[ "true" != "${usePPA}" ]]; then
		# https://steamcommunity.com/app/221410/discussions/0/540744935113197089/
		#
		# add key for steam beta
		echo "Adding signing key ... ";
		sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B05498B7;

		# add repo source for winehq
		echo "Adding Steam PPA source ... ";
		addAptCustomSource steam 'deb http://repo.steampowered.com/steam/ bionic steam';
	fi

	# Add exceptions for in-home streaming
	sudo iptables -A INPUT -p tcp --dport 27036 -j ACCEPT;
	sudo iptables -A INPUT -p udp --dport 27036 -j ACCEPT;

	# install wine-staging
	echo "Installing steam ... ";
	sudo apt-get install --install-recommends -y steam;
fi

# Install Glorious Eggroll build
startDir=$(pwd);

# Note: I tried downloading into some of the steamapps/common dirs but it never was recognized;
#       pretty sure steam will only allo custom proton builds from this folder unless there is
#		official documentation somewhere that says otherwise.
steamCompatToolsDir="${HOME}/.steam/root/compatibilitytools.d";
if [[ ! -e "${steamCompatToolsDir}" ]]; then
	mkdir -p "${steamCompatToolsDir}" 2>/dev/null;
fi
cd "${steamCompatToolsDir}";

releasesPageUrl="https://github.com/GloriousEggroll/proton-ge-custom/releases";

echo ''
echo 'Fetching Downloads page source from:'
echo "  ${releasesPageUrl}";
rawDownloadPageSource=$(/usr/bin/curl --location --user-agent "${userAgent}" "${releasesPageUrl}" 2>/dev/null);
if [[ "0" != "$?" ]]; then
	echo "ERROR: curl returned error code of $? while accessing download URL : ${downloadPageUrl}";
	echo 'Aborting script';
	exit;
fi
rawPageSourceSize="${#rawDownloadPageSource}";
if [[ "0" == "${rawPageSourceSize}" ]]; then
	echo "ERROR: rawDownloadPageSource was empty; please check download URL : ${downloadPageUrl}";
	echo 'Aborting script';
	exit;
fi
if [[ "true" == "${enableDebug}" ]]; then
	echo '';
	echo "Found raw page source with length: ${rawPageSourceSize}";
fi

# set filter for finding link in page
downloadPageFilterRegex='<a.*href.*/proton-ge-custom/releases/download/.*\.tar\.gz';

# Clean up page source to only show relevant lines
echo '';
echo 'Filtering page source ...';
filteredDownloadPageSource=$(echo "${rawDownloadPageSource}"|/usr/bin/perl -0pe 's/>\s*</>\n</g'|grep -Pi "${downloadPageFilterRegex}");

filteredPageSourceSize="${#filteredDownloadPageSource}";
if [[ "true" == "${enableDebug}" ]]; then
	echo "Filtered to source to length: ${filteredPageSourceSize}";
	echo '';
	echo "Filtered page source: ${filteredDownloadPageSource}";
fi

# set filters
#excludedDownloadLinksRegex='(aurora|alpha|beta|current|waterfox\-[6-9]\d|waterfox\-[\d\.]+a[\d\.]*\.en\-US.linux\-x86_64.tar.bz2)'
downloadLinkFilterRegex='(classic)'

echo '';
echo 'Parsing filtered source for download link...'
#appDownloadLink=$(echo "${filteredDownloadPageSource}"| grep -Pvi "${excludedDownloadLinksRegex}" | /usr/bin/perl -pe 's/^.*href="([^"]+)".*$/$1/g' | /usr/bin/sort -u | /usr/bin/tail -n 1);
appDownloadLink=$(echo "${filteredDownloadPageSource}"|head -1|sed -E 's|^.*href="/(GloriousEggroll/[^"]+\.tar\.gz)".*$|https://github.com/\1|g'|sort -u);
if [[ ${#appDownloadLink} -lt 30 || ${#appDownloadLink} -gt 300 || "http" != "${appDownloadLink:0:4}" ]]; then
	if [[ "true" == "${enableDebug}" ]]; then
		# dump source to temp file for debugging...
		echo "${rawDownloadPageSource}" > /tmp/${appBinaryName}-sh-raw-source.txt
		echo "${filteredDownloadPageSource}" > /tmp/${appBinaryName}-sh-filtered-source.txt
	fi

	# print error message
	echo '';
	echo '===========================================================================================';
	echo 'ERROR: Invalid download link value. The script may need to be updated.';
	echo '       Displaying debug info then aborting script';
	echo '===========================================================================================';
	if [[ "true" == "${enableDebug}" ]]; then
		printDebugInfo;
	fi
	exit;
fi
echo '';
echo 'Found download link as:';
echo "  ${appDownloadLink}";

# TODO...  add automatic curl lookup + parsing of releases page to find latest version dynamically instead of hard-coding
#appDownloadLink="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/5.11-GE-3-MF/Proton-5.11-GE-3-MF.tar.gz";

downloadFileName=$(basename "${appDownloadLink}");

wget "${appDownloadLink}";
if [[ ! -f "${steamCompatToolsDir}/${downloadFileName}" ]];
	echo "Failed to downloaded ${downloadFileName}. Please manually download GE-Proton tar.gz file from:";
	echo "  ${releasesPageUrl}";
	echo "";
	echo "Then copy the file under '${HOME}/.steam/root/compatibilitytools.d' and run the following to extract: ";
	echo "   tar -xvf '${downloadFileName}'";
	exit;
fi

# extract
tar -xvf "${downloadFileName}";

# cleanup archive to save space
rm "${downloadFileName}";

# return to startDir
cd "${startDir}";
