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

noClobberSymlinks="false";
keepOptInstallSymlinks="false";
displayHelp="false";
omitSymlinks="false";
recreateSymlinks="false";

for passedarg in "$@"; do
    #echo "passedarg is $passedarg"
    if [[ "-h" == "${passedarg}" || "--help" == "${passedarg}" ]]; then
        displayHelp="true";

    elif [[ "-k" == "${passedarg}" || "--keep-opt-symlinks" == "${passedarg}" ]]; then
        keepOptInstallSymlinks="true";
    elif [[ "-n" == "${passedarg}" || "--no-clobber" == "${passedarg}" ]]; then
        noClobberSymlinks="true";
    elif [[ "-o" == "${passedarg}" || "--omit-symlinks" == "${passedarg}" ]]; then
        omitSymlinks="true";
    elif [[ "-r" == "${passedarg}" || "--recreate-symlinks" == "${passedarg}" ]]; then
        recreateSymlinks="true";
    fi
done

if [[ "true" == "${displayHelp}" ]]; then
    echo '';
    echo "Usage:  $(basename $0) [options]";
    echo '';
    echo 'Options:';
    echo '  -h, --help                 Displays this help text.';
    echo '';
    echo '  -n, --no-clobber           No symlinks will be overwritten.';
    echo '';
    echo '  -k, --keep-opt-symlinks    Symlinks pointing to /opt/waterfox-classic will not be overwritten.';
    echo '';
    echo '  -o, --omit-symlinks        Script will not add any new symlinks/overwrite any existing symlinks.';
    echo '                             This option is only considered during initial install.';
    echo '';
    echo '  -r, --recreate-symlinks    Script will recreate symlinks even if application is already installed.';
    echo '                             Other options such as -n and -k will still apply.';
    echo '                             This option is not considered during initial install.';
    echo '';
    exit;
fi

isWaterfoxKpeInstalled=$(apt search waterfox-classic|grep -P '^i\w*\s+waterfox-classic-kpe'|wc -l);
if [[ "0" != "${isWaterfoxKpeInstalled}" ]]; then
    if [[ "true" == "${recreateSymlinks}" && "false" == "${omitSymlinks}" ]]; then
        echo 'Recreating symlinks for Waterfox Classic KPE ...';
        echo '';
    else
        echo 'Waterfox Classic KPE is already installed.';
        echo '';
        echo 'To remove, run:';
        echo '  sudo apt-get remove waterfox-classic-kpe waterfox-locale-en';
        echo '';
        echo 'To recreate symlinks, use -r or --recreate-symlinks';
        echo 'For more details, see help with -h or --help';
        echo '';
        exit;
    fi
else
    # See https://www.blackrosetech.com/gessel/2019/06/19/update-waterfox-with-the-new-ppa-on-mint-19-1
    #		https://forums.linuxmint.com/viewtopic.php?t=296666
    #

    # add unofficial hawkeye116477 source for waterfox
    addCustomSource waterfox-hawkeye116477-unofficial 'deb http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/xUbuntu_20.04/ /';

    # add key for hawkeye116477 repo
    wget -qO - https://download.opensuse.org/repositories/home:hawkeye116477:waterfox/xUbuntu_20.04/Release.key | sudo apt-key add -;

    # update apt's cache
    sudo apt-get update 2>/dev/null >/dev/null;

    # waterfox-classic => resolves to waterfox-classic-kpe
    # normally this package prompts you with a package configuration
    # screen that you have to type ENTER on.
    #
    # To avoid the prompt breaking automation, we are going to follow:
    #	http://www.microhowto.info/howto/perform_an_unattended_installation_of_a_debian_package.html
    #

    # install waterfox
    export DEBIAN_FRONTEND=noninteractive
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -q -y waterfox-classic-kpe;

    # update install flag
    isWaterfoxKpeInstalled=$(which waterfox-classic|wc -l);
fi

# setup additional symlinks
if [[ "true" != "${omitSymlinks}" && "1" == "${isWaterfoxKpeInstalled}" ]]; then
    applicationBinPath=$(realpath /usr/bin/waterfox-classic);
    if [[ "/opt/waterfox-classic/" == "${applicationBinPath:0:22}" || "/opt/waterfox/" == "${applicationBinPath:0:14}" ]]; then
        applicationBinPath="";
        if [[ -f "/usr/lib/waterfox-classic/waterfox-classic-bin.sh" ]]; then
            applicationBinPath="/usr/lib/waterfox-classic/waterfox-classic-bin.sh";
        fi
    fi

    if [[ "" != "${applicationBinPath}" ]]; then
        symlinkList="waterfox waterfox-kde waterfox-kpe waterfox-classic-kde waterfox-classic-kpe waterfoxk wf wfc";
        for symlinkName in $(echo "${symlinkList}"); do
            # if symlink does not exist, simply create it and go to next iteration
            if [[ ! -L "/usr/bin/${symlinkName}" ]]; then
                sudo ln -s "${applicationBinPath}" "/usr/bin/${symlinkName}";
                continue;
            fi

            # otherwise, if the -n/--no-clobber flag is set, then also
            # skip to the next iteration without making any changes
            if [[ "true" == "${noClobberSymlinks}" ]]; then
                continue;
            fi

            # get the symlink target
            symlinkDest=$(realpath "/usr/bin/${symlinkName}");

            # if the -k/--keep-opt-symlinks flag is set
            # and the target is under either /opt/waterfox-classic/* or
            # /opt/waterfox/* then skip to next iteration without changes
            if [[ "true" == "${keepOptInstallSymlinks}" ]]; then
                if [[ "/opt/waterfox-classic/" == "${symlinkDest:0:22}" || "/opt/waterfox/" == "${symlinkDest:0:14}" ]]; then
                    continue;
                fi
            fi

            # finally, check that the existing symlink does not
            # already point to the correct location
            if [[ "${symlinkDest}" != "${applicationBinPath}" ]]; then
                sudo ln -sf "${applicationBinPath}" "/usr/bin/${symlinkName}";
            fi
        done
    fi
fi
