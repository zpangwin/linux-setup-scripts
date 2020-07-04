#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

if [[ ! -f "${SCRIPT_DIR_PARENT}/../functions.sh" ]]; then
    echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
    exit;
fi
. "${SCRIPT_DIR_PARENT}/../functions.sh";

applicationDisplayName="Waterfox Classic";
applicationPackageName="waterfox-classic-kpe";
applicationBinName="waterfox-classic";
applicationBinPath="";
isApplicationInstalled=$(apt search waterfox-classic-kpe|grep '^i\w*\s+'|wc -l);
if [[ "0" != "${isApplicationInstalled}" ]]; then
	echo "The package '${applicationPackageName}' does not appear to be installed.";
	response="";
	while [[ ! $response =~ ^[yYNn]$ ]]; do
		printf "Are you sure you want to continue? (Y or N): ";
		read response;
	done
	if [[ ! $response =~ ^[yY]$ ]]; then
		echo "Aborting script ...";
		exit;
	fi
	applicationBinPath="/usr/lib/waterfox-classic/waterfox-classic-bin.sh";
else
    applicationBinPath=$(which ${applicationBinName});
    if [[ -L "${applicationBinPath}" ]]; then
        applicationBinPath=$(realpath "${applicationBinPath}");
    fi
fi

# waterfox-classic => resolves to waterfox-classic-kpe
# normally this package prompts you with a package configuration
# screen that you have to type ENTER on.
#
# To avoid the prompt breaking automation, we are going to follow:
#	http://www.microhowto.info/howto/perform_an_unattended_installation_of_a_debian_package.html
#

# remove waterfox
export DEBIAN_FRONTEND=noninteractive
sudo DEBIAN_FRONTEND=noninteractive apt-get remove -q -y waterfox-classic waterfox-classic-kpe;

# See https://www.blackrosetech.com/gessel/2019/06/19/update-waterfox-with-the-new-ppa-on-mint-19-1
#		https://forums.linuxmint.com/viewtopic.php?t=296666
#

# remove unofficial hawkeye116477 source for waterfox
sudo rm /etc/apt/sources.list.d/waterfox-unofficial.list 2>/dev/null >/dev/null;
sudo rm /etc/apt/sources.list.d/waterfox-hawkeye116477-unofficial.list 2>/dev/null >/dev/null;

# remove hawkeye116477 signing key
KNOWN_KEY="E64C7A04DC653D07ACA3EA585E62D791625A271E";
if [[ "" != "${KNOWN_KEY}" ]]; then
    sudo apt-key del "${KNOWN_KEY}" 2>/dev/null; # correct as of 2020 FEb 19

    # but also future-proof by getting key dynamically... this prevent missed keys as long as the key is not changed more than once
    TEMP_KEYRING="/tmp/hawkeye116477-test";
    wget -qO - https://download.opensuse.org/repositories/home:hawkeye116477:waterfox/xUbuntu_20.04/Release.key | sudo apt-key --keyring ${TEMP_KEYRING} add -;
    TEMP_KEY=$(sudo apt-key --keyring ${TEMP_KEYRING} list 2>/dev/null|grep -Pv '^(\s*$|/tmp|[-]|pub|uid)'|head -1|sed -E 's/\s+//g');
    if [[ "" != "${TEMP_KEY}" && $TEMP_KEY =~ ^[A-F0-9]{8,}$ && """${KNOWN_KEY}" != "${TEMP_KEY}" ]]; then
        echo "Found a newer signing key for hawkeye116477; Attempting to make sure this is removed as well ...";
        sudo apt-key del "${TEMP_KEY}";
    fi
fi

# update apt's local cache
sudo apt-get update 2>/dev/null >/dev/null;

# cleanup symlinks and menu items (but don't touch use data -- this is remove not purge)
if [[ "" != "${applicationBinPath}" ]]; then
    # clean-up symlinks
    symlinkList="waterfox-kde waterfox-kpe waterfox-classic-kde waterfox-classic-kpe waterfoxk wf wfc";
    for symlinkName in $(echo "${symlinkList}"); do
        if [[ -L "/usr/bin/${symlinkName}" ]]; then
            symlinkDest=$(realpath "/usr/bin/${symlinkName}");
            if [[ "${symlinkDest}" == "${applicationBinPath}" ]]; then
                sudo rm "/usr/bin/${symlinkName}" 2>&1 >/dev/null;
            fi
        fi
    done

    find /usr/share/applications -maxdepth 1 -type f -name '*waterfox*.desktop' -print0 |
    while IFS= read -r -d '' linuxDesktopFile; do
	    callsAppBinary=$(grep -P "Exec=${applicationBinName}" "${linuxDesktopFile}" 2>/dev/null|wc -l);

	    # debug
	    #printf 'linuxDesktopFile: %s, callsAppBinary: %s\n' "$linuxDesktopFile" "$callsAppBinary";

	    # skip any non-link types
	    if [[ "0" == "${callsAppBinary}" ]]; then
		    continue;
	    fi
        sudo rm "${linuxDesktopFile}" 2>&1 >/dev/null;
    done
fi

