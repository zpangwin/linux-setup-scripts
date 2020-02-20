#!/bin/bash

if [ -f ../functions.sh ]; then
    . ../functions.sh
else
	echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
	exit;
fi

has_waterfox_kpe_insta;

# See https://www.blackrosetech.com/gessel/2019/06/19/update-waterfox-with-the-new-ppa-on-mint-19-1
#		https://forums.linuxmint.com/viewtopic.php?t=296666
#

# add unofficial hawkeye116477 source for waterfox
addCustomSource waterfox-hawkeye116477-unofficial 'deb http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/xUbuntu_18.04/ /';

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

# setup additional symlink
isWaterfoxInstalled=$(which waterfox-classic|wc -l);
if [[ "1" == "${isWaterfoxInstalled}" ]]; then
    waterfoxClassicPath=$(realpath waterfox-classic);

    # make sure we're not making any recursive symlinks
    if [[ "/usr/bin/waterfox" != "${waterfoxClassicPath}" ]]; then
        createOrReplaceLink="true";
        if [[ -L "/usr/bin/waterfox" ]]; then
            existingSymlinkPath=$(realpath "/usr/bin/waterfox");
            if [[ "${existingSymlinkPath}" == "${waterfoxClassicPath}" ]]; then
                createOrReplaceLink="false";

            # safety in case someone *does* actually want both the website and the hawkeye ppa versions simultaneously...
            elif [[ -f "${existingSymlinkPath}" && -r "${existingSymlinkPath}" && -x "${existingSymlinkPath}" ]]; then
                createOrReplaceLink="false";
            fi
        fi

        # if true, then create/replace the /usr/bin/waterfox link and repoint it to /usr/bin/waterfox-classic
        if [[ "true" == "${createOrReplaceLink}" ]]; then
            # this is the only link we should use the -f flag with
            # and we are only triggering there isn't an old install
    		sudo ln -sf "${waterfoxClassicPath}" /usr/bin/waterfox;
        fi
	fi

    sudo ln -s "${waterfoxClassicPath}" /usr/bin/waterfox-kde;
    sudo ln -s "${waterfoxClassicPath}" /usr/bin/waterfox-kpe;
    sudo ln -s "${waterfoxClassicPath}" /usr/bin/waterfox-classic-kde;
    sudo ln -s "${waterfoxClassicPath}" /usr/bin/waterfox-classic-kpe;
    sudo ln -s "${waterfoxClassicPath}" /usr/bin/waterfoxk;

    # if wf & wfc aren't in use by something else then reserve these too
    sudo ln -s "${waterfoxClassicPath}" /usr/bin/wf;
    sudo ln -s "${waterfoxClassicPath}" /usr/bin/wfc;
fi
