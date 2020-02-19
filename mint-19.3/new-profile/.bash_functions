#==========================================================================
# Start Section: General Utility Functions
#==========================================================================
function setGnomeTerminalTitle() {
    local NEW_TITLE="$1";
    PS1="[e]0;${NEW_TITLE}a]${debian_chroot:+($debian_chroot)}[033[01;32m]u@h[033[00m] [033[01;34m]w $[033[00m]";
}
function archiveDirWith7z () {
    local dirPath="$1";
    local zipPath="$2";

    if [[ "" == "${dirPath}" || ! -e "${dirPath}" ]]; then
        echo -e "tError: Missing or empty directory path '$dirPath' ";
        echo -e "ntarchiveDirWith7z /dir/to/archive [/path/of/archive/to/create.7z]";
        return;
    fi

    if [[ "" == "${zipPath}" || ".7z" != "${zipPath:(-3)}" ]]; then
        local datestr=$(date +"%Y-%m-%d");
        zipPath="${dirPath}_${datestr}.7z"
    fi

    7z a -t7z -m0=lzma2 -mx=9 -md=32m -ms=on "${zipPath}" "${dirPath}" | grep -v "Compressing"
}
function makeThenChangeDir() {
    local NEW_DIR="$1";
    mkdir -p "${NEW_DIR}";
    cd "${NEW_DIR}";
}
#==========================================================================
# End Section: General Utility Functions
#==========================================================================

#==========================================================================
# Start Section: Git
#==========================================================================
function gitArchiveLastCommit () {
    local currDir=$(pwd);
    if [[ ! -d "${currDir}/.git" ]]; then
        echo "   -> Error: Must be in top-level dir of a git repository.";
        return;
    fi
    local repoName="${currDir##*/}";
    local timeStamp=$(date +"%Y%m%d%H%M%S");
    local outFilePath="../${repoName}_${SUDO_USER:-$USER}_${timeStamp}_lastcommit.zip";
    echo "   -> outFilePath: '${outFilePath}'";
    git diff --diff-filter=CRAMX -z --name-only HEAD~1 HEAD | xargs -0 git archive HEAD -o "${outFilePath}" --;
}

function gitArchiveLastCommitBackout () {
    local currDir=$(pwd);
    if [[ ! -d "${currDir}/.git" ]]; then
        echo "   -> Error: Must be in top-level dir of a git repository.";
        return;
    fi
    local repoName="${currDir##*/}";
    local timeStamp=$(date +"%Y%m%d%H%M%S");
    local outFilePath="../${repoName}_${SUDO_USER:-$USER}_${timeStamp}_lastcommit.zip";
    echo "   -> outFilePath: '${outFilePath}'";
    git diff --diff-filter=CRAMX -z --name-only HEAD~1 HEAD | xargs -0 git archive HEAD~1 -o "${outFilePath}" --;
}
function gitArchiveAllCommitsSince () {
    local currDir=$(pwd);
    if [[ ! -d "${currDir}/.git" ]]; then
        echo "   -> Error: Must be in top-level dir of a git repository.";
        return;
    fi

    local commitOrBranchName="$1";
    if [[ "" == "${commitOrBranchName}" ]]; then
        echo "   -> Error: Must provide the name or hash value for either a commit or a branch to use as a base.";
        return;
    fi

    local displayName="${commitOrBranchName##*/}";
    displayName="${displayName//[![:alnum:]]/-}";

    local repoName="${currDir##*/}";
    local timeStamp=$(date +"%Y%m%d%H%M%S");
    local outFilePath="../${repoName}_${SUDO_USER:-$USER}_${timeStamp}_since_${displayName}.zip";
    echo "   -> outFilePath: '${outFilePath}'";
    git diff --diff-filter=CRAMX -z --name-only HEAD~1 HEAD | xargs -0 git archive HEAD -o "${outFilePath}" --;
}
function gitGrepHistoricalFileContents () {
    if [[ "" == "$1" ]]; then
        echo "gitGrepHistoricalFileContents(): No passed args.";
        echo -e "tExpected gitGrepHistoricalFileContents filename regex";
        return;
    fi
    if [[ "" == "$2" ]]; then
        echo "gitGrepHistoricalFileContents(): No passed search pattern.";
        echo -e "tExpected gitGrepHistoricalFileContents filename regex";
        return;
    fi

    git rev-list --all "$1" | (
        while read revision; do
            git grep -F "$2" $revision "$1"
        done
    )
}
function gitUpdateAllReposUnderDir () {
    local parentDir="$1";
    local startingDir=$(pwd);
    if [[ "" == "${parentDir}" ]]; then
        parentDir="${startingDir}";
    fi

    # print header - this gets printed from all logic paths so doing it once as a header up top saves space per output line
    echo "gitUpdateAllReposUnderDir():";

    # git commands must be performed relative to repo base folder
    cd "${parentDir}";

    local repoName='';
    local remoteName='';
    local remoteUrl='';

    # check if we are somewhere under a working directory in a git repo
    local repoTopLevelDir=$(git rev-parse --show-toplevel 2>/dev/null);
    if [[ "" != "${repoTopLevelDir}" ]]; then
        remoteName=$(git remote);
        if [[ "" != "${remoteName}" ]]; then
            remoteUrl=$(git remote get-url --push "${remoteName}");
        fi
        if [[ "" == "${remoteUrl}" ]]; then
            echo "  No remote fetch url found.";
            echo "  Skipping git repo: '${repoTopLevelDir}'";
            return;
        fi

        # If so, then update this single repo and exit back to terminal
        echo "  Updating git repo: '${repoTopLevelDir}'";
        echo "";

        cd "${repoTopLevelDir}";
        git fetch --all --quiet --progress;
        git pull --all --quiet --progress;

        # then change back to starting dir and return (we're all done)
        cd "${startingDir}";
        return;
    fi

    # check for permission errors
    local permErrorCount=$(find "${parentDir}" -type d -name '.git' 2>&1|grep 'Permission denied'|wc -l);
    if [[ "0" != "${permErrorCount}" ]]; then
        echo "  WARNING: Permission issues were detected for ${permErrorCount} subdirs. These subdirs will be ignored.";
        echo "  To view a list of subdirs with permission issues run:";
        echo "    find "${parentDir}" -type d -name '.git' >/dev/null";
    fi

    # otherwise, check if subfolders contain repos. if not then exit
    local totalRepos=$(find "${parentDir}" -type d -name '.git' 2>/dev/null|wc -l);
    if [[ "0" == "" ]]; then
        echo "  No git repos found for '${parentDir}'";
        echo "";
        return;
    fi

    echo "  Found ${totalRepos} git repos under:";
    echo "    '${parentDir}'";
    echo "";

    # otherwise (if there are subfolders that contain repos) then update each of the subfolder repos
    local gitdir='';
    local subdir='';
    local displaysubdir='';
    local repoCounter=0;
    local padcount=0;
    find "${parentDir}" -type d -name '.git' 2>/dev/null | while IFS='' read gitdir; do
        subdir=$(dirname "$gitdir");
        cd "${subdir}";

        repoName=$(dirname "$subdir");
        displaysubdir="$subdir";
        if [[ "${subdir:0:${#HOME}}" == "${HOME}" ]]; then
            displaysubdir="~${subdir:${#HOME}}";
        fi

        #padcount is the total number of digits to display (so it must be at least one)
        padcount=$(( 1 + ${#totalRepos} - ${#repoCounter} ));

        repoCounter=$(( 1 + repoCounter ));

        # print formatted progress info
        printf "  ==============================================================================\n";
        remoteUrl='';
        remoteName=$(git remote);
        if [[ "" != "${remoteName}" ]]; then
            remoteUrl=$(git remote get-url --push "${remoteName}");
        fi
        #printf "  subdir=%s remoteName=%s remoteUrl=%s\n" "${subdir}" "${remoteName}" "${remoteUrl}";
        if [[ "" == "${remoteUrl}" ]]; then
            printf "  No remote fetch url found.\n";
            printf "  Skipping repo %0${padcount}d of %d: %s (no remote fetch url)\n" "${repoCounter}" "${totalRepos}" "${displaysubdir}";
            continue;
        fi
        printf "  Updating repo %0${padcount}d of %d: %s\n" "${repoCounter}" "${totalRepos}" "${displaysubdir}";
        echo "";

        # call git pull in the targeted subdir
        git fetch --all --quiet --progress;
        git pull --all --quiet --progress;
    done
}
#==========================================================================
# End Section: Git
#==========================================================================

#==========================================================================
# Start Section: Media files
#==========================================================================
function extractMp3AudioFromVideoFile () {
    local videofile="$1";
    local bitrate="$2";
    local defbitrate="160k";
    if [[ "" == "$2" || ! $bitrate =~ ^[1-9][0-9]{1,2}k$ ]]; then
        bitrate="$defbitrate";
    fi
    local filenameonly="${videofile%.*}"
    ffmpeg -i "${videofile}" -vn -acodec libmp3lame -ac 2 -ab $bitrate -ar 48000 "${filenameonly}.mp3"
}
function extractOggAudioFromVideoFile () {
    local videofile="$1";
    local filenameonly="${videofile%.*}"
    ffmpeg -i "${videofile}" -vn -acodec libvorbis "${filenameonly}.ogg"
}
function extractMp3AudioFromAllVideosInCurrentDir () {
    local bitrate="$1";
    local defbitrate="160k";
    if [[ "" == "$1" || ! $bitrate =~ ^[1-9][0-9]{1,2}k$ ]]; then
        bitrate="$defbitrate";
    fi

    for file in *.{3gp,arf,asf,avi,f4v,flv,h264,m1v,m2v,m4v,mkv,mov,mp4,mp4v,mpg,mpeg,ogm,ogv,ogx,qt,rm,rv,wmv} ; do
        if [[ "*" == "${file:0:1}" ]]; then
            continue;
        fi
        #no clobber; skip any that already exist
        file_without_ext="${file%.*}";
        if [[ ! -f "${file_without_ext}.mp3" ]]; then
            ffmpeg -i "$file" -vn -acodec libmp3lame -ac 2 -ab $bitrate -ar 48000 "${file_without_ext}.mp3"
        fi
    done
}
function extractMp3AudioFromAllMp4InCurrentDir () {
    local bitrate="$1";
    local defbitrate="160k";
    if [[ "" == "$1" || ! $bitrate =~ ^[1-9][0-9]{1,2}k$ ]]; then
        bitrate="$defbitrate";
    fi

    for vid in *.mp4; do
        echo "vid is: $vid"
        #skip any that already exist
        if [[ ! -f "${vid%.mp4}.mp3" ]]; then
            ffmpeg -i "$vid" -vn -acodec libmp3lame -ac 2 -ab $bitrate -ar 48000 "${vid%.mp4}.mp3"
        fi
    done
}
function extractMp3AudioFromAllFlvInCurrentDir () {
    local bitrate="$1";
    local defbitrate="160k";
    if [[ "" == "$1" || ! $bitrate =~ ^[1-9][0-9]{1,2}k$ ]]; then
        bitrate="$defbitrate";
    fi

    for vid in *.flv; do
        #skip any that already exist
        if [[ ! -f "${vid%.flv}.mp3" ]]; then
            ffmpeg -i "$vid" -vn -acodec libmp3lame -ac 2 -ab $bitrate -ar 48000 "${vid%.flv}.mp3"
        fi
    done
}
function extractOggAudioFromAllMp4InCurrentDir () {
    for vid in *.mp4; do
        #skip any that already exist
        if [[ ! -f "${vid%.mp4}.ogg" ]]; then
            ffmpeg -i "$vid" -vn -acodec libvorbis "${vid%.mp4}.ogg";
        fi
    done
}
function normalizeAllOggInCurrentDir () {
    for audio_file in *.ogg; do
        normalize-ogg "${audio_file}";
    done
}
function normalizeAllMp3InCurrentDir () {
    for audio_file in *.mp3; do
        normalize-mp3 "${audio_file}";
    done
}

#==========================================================================
# End Section: Media files
#==========================================================================

#==========================================================================
# Start Section: Wine
#==========================================================================
function createNewWine32Prefix () {
    if [[ "" == "$1" ]]; then
        echo -e "ERROR: Requires argument.nExpected usage:nn";
        echo -e "createNewWine32Prefix folder-to-be-createdn";
        echo -e "Note:  the new prefix folder must not exist yet.";
        return;
    elif [[ -e "$1" ]]; then
        echo -e "ERROR: Path already exists; wine will not create a new prefix at an existng location.nExpected usage:nn";
        echo -e "createNewWine32Prefix folder-to-be-createdn";
        echo -e "Note:  the new prefix folder must not exist yet.";
        return;
    fi
    env WINEPREFIX="$1" WINEARCH=win32 wine wineboot
}
function createNewWine64Prefix () {
    if [[ "" == "$1" ]]; then
        echo -e "ERROR: Requires argument.nExpected usage:nn";
        echo -e "createNewWine64Prefix folder-to-be-createdn";
        echo -e "Note:  the new prefix folder must not exist yet.";
        return;
    elif [[ -e "$1" ]]; then
        echo -e "ERROR: Path already exists; wine will not create a new prefix at an existng location.nExpected usage:nn";
        echo -e "createNewWine64Prefix folder-to-be-createdn";
        echo -e "Note:  the new prefix folder must not exist yet.";
        return;
    fi
    env WINEPREFIX="$1" WINEARCH=win64 wine wineboot
}
function winetricksHere() {
    local foundValidWinePrefix='false';
    local startingDir=$(pwd);
    local winePrefixDir="${startingDir}";
    if [[ -d  "${winePrefixDir}/drive_c" ]]; then
        foundValidWinePrefix='true';
    else
        while [[ "false" == "${foundValidWinePrefix}" ]]; do
            if [[ -d  "${winePrefixDir}/drive_c" ]]; then
                foundValidWinePrefix='true';
                break;
            fi
            winePrefixDir=$(dirname "${winePrefixDir}");
            if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
                break;
            fi
        done;
    fi
    if [[ "false" == "${foundValidWinePrefix}" ]]; then
        echo -e "ERROR: winetricksHere - Not under a valid WINEPREFIX folder.";
        return;
    fi
    env WINEPREFIX="${winePrefixDir}" winetricks $1 $2 $3 $4 $5 $6 $7 $8 $9
}
function runWineCommandHere() {
    local __wine_command__="$1";
    local __func_name__="runWineCommandHere";
    if [[ "" == "${__wine_command__}" ]]; then
        echo "ERROR: runWineCommandHere - no args";
        return;
    fi
    if [[ "" != "$2" ]]; then
        __func_name__="$2";
    fi

    local foundValidWinePrefix='false';
    local startingDir=$(pwd);
    local winePrefixDir="${startingDir}";
    if [[ -d  "${winePrefixDir}/drive_c" ]]; then
        foundValidWinePrefix='true';
    else
        while [[ "false" == "${foundValidWinePrefix}" ]]; do
            if [[ -d  "${winePrefixDir}/drive_c" ]]; then
                foundValidWinePrefix='true';
                break;
            fi
            winePrefixDir=$(dirname "${winePrefixDir}");
            if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
                break;
            fi
        done;
    fi
    if [[ "false" == "${foundValidWinePrefix}" ]]; then
        echo -e "ERROR: ${__func_name__} - Not under a valid WINEPREFIX folder.";
        return;
    fi
    env WINEPREFIX="${winePrefixDir}" wine ${__wine_command__};
}
function wineCmdHere() {
    runWineCommandHere 'cmd' 'wineCmdHere'
}
function wineConfigHere() {
    runWineCommandHere 'winecfg' 'wineConfigHere'
}
function wineRegeditHere() {
    runWineCommandHere 'regedit' 'wineRegeditHere'
}
function goToWinePrefix() {
    local foundValidWinePrefix='false';
    local startingDir=$(pwd);
    local winePrefixDir="${startingDir}";
    if [[ -d  "${winePrefixDir}/drive_c" ]]; then
        foundValidWinePrefix='true';
    else
        while [[ "false" == "${foundValidWinePrefix}" ]]; do
            if [[ -d  "${winePrefixDir}/drive_c" ]]; then
                foundValidWinePrefix='true';
                break;
            fi
            winePrefixDir=$(dirname "${winePrefixDir}");
            if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
                break;
            fi
        done;
    fi
    if [[ "false" == "${foundValidWinePrefix}" ]]; then
        echo -e "ERROR: goToWinePrefix - Not under a valid WINEPREFIX folder.";
        return;
    fi
    cd "${winePrefixDir}";
}
function printWinePrefix() {
    local foundValidWinePrefix='false';
    local startingDir=$(pwd);
    local winePrefixDir="${startingDir}";
    if [[ -d  "${winePrefixDir}/drive_c" ]]; then
        foundValidWinePrefix='true';
    else
        while [[ "false" == "${foundValidWinePrefix}" ]]; do
            if [[ -d  "${winePrefixDir}/drive_c" ]]; then
                foundValidWinePrefix='true';
                break;
            fi
            winePrefixDir=$(dirname "${winePrefixDir}");
            if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
                break;
            fi
        done;
    fi
    if [[ "false" == "${foundValidWinePrefix}" ]]; then
        echo -e "ERROR: printWinePrefix - Not under a valid WINEPREFIX folder.";
        return;
    fi
    echo "${winePrefixDir}";
}
#==========================================================================
# End Section: Wine
#==========================================================================

#==========================================================================
# Start Section: Administration
#==========================================================================

#==========================================================================
# End Section: Administration
#==========================================================================

#==========================================================================
# Start Section: Network
#==========================================================================
function isValidIpAddr() {
    # return code only version
    local ipaddr="$1";
    [[ ! $ipaddr =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ ]] && return 1;
    for quad in $(echo "${ipaddr//./ }"); do
        (( $quad >= 0 && $quad <= 255 )) && continue;
        return 1;
    done
}
function validateIpAddr() {
    # return code + output version
    local ipaddr="$1";
    local errmsg="ERROR: $1 is not a valid IP address";
    [[ ! $ipaddr =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ ]] && echo "$errmsg" && return 1;
    for quad in $(echo "${ipaddr//./ }"); do
        (( $quad >= 0 && $quad <= 255 )) && continue;
        echo "$errmsg";
        return 1;
    done
    echo "SUCCESS: $1 is a valid IP address";
}
function mountWindowsNetworkShare() {
    local networkPath="$1";
    local mountPoint="$2";
    local remoteLogin="$3";
    local remotePassword="$4";

    # validate input
    local showUsage="false";
    if [[ "-h" == "$1" || "--help" == "$1" ]]; then
        showUsage="true";

    elif [[ "" == "${networkPath}" ]]; then
        echo "ERROR: REMOTE_PATH is empty";
        showUsage="true";

    elif [[ "" == "${mountPoint}" ]]; then
        echo "ERROR: LOCAL_PATH is empty";
        showUsage="true";

    elif [[ ! $mountPoint =~ ^[~.]?/.*$ || $mountPoint =~ ^//.*$ ]]; then
        echo "ERROR: LOCAL_PATH must be a valid local path";
        showUsage="true";

    elif [[ "" == "${remoteLogin}" ]]; then
        echo "ERROR: REMOTE_USER is empty";
        showUsage="true";

    elif [[ "" == "${remotePassword}" ]]; then
        echo "ERROR: REMOTE_PWD is empty";
        showUsage="true";
    fi

    # secondary validations
    if [[ "false" == "${showUsage}" ]]; then
        # get sudo prompt out of the way
        sudo ls -acl 2>/dev/null >/dev/null;

        # canonicalize network path
        if [[ "//" != "${networkPath:0:2}" ]]; then
            networkPath="//${networkPath}";
        fi

        # Make sure network path is of the format:
        #   HOST/SHARE
        #
        # Where REMOTE_HOST is either a valid HOST or a valid IP_ADDR
        local remoteHost=$(printf "${networkPath}"|sed -E 's|^//([^/]+)/.*$|1|g');
        local shareName=$(printf "${networkPath}"|sed -E 's|^//[^/]+/(.*)$|1|g');

        if [[ "${#networkPath}" == "${#remoteHost}" || "0" == "${#remoteHost}" || "${#networkPath}" == "${#shareName}" || "0"  == "${#shareName}" ]]; then
            echo "ERROR: REMOTE_PATH is invalid. It should be in the form: //IPADDR/SHARE_NAME";
            showUsage="true";

        elif [[ $shareName =~ ^.*[^-A-Za-z0-9_.+= ~%@#()&].*$ ]]; then
            echo "ERROR: REMOTE_PATH is invalid. shareName '${shareName}' contains invalid characters.";
            showUsage="true";

        elif [[ $remoteHost =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ ]]; then
            # definitely *supposed* to be an ip address
            # check if it is a *valid* ip address (correct numerical ranges)

            # check that each ip quad is with the range 0 to 255
            isValidIpAddr "$remoteHost";
            if [[ "0" != "$?" ]]; then
                echo "ERROR: REMOTE_PATH is invalid. host '${remoteHost}' is not a valid ip address.";
                showUsage="true";
            fi

        elif [[ $remoteHost =~ ^[A-Za-z][-A-Za-z0-9_.]*$ ]]; then
            # host names are only allowed if the system supports
            # resolving hostnames...
            local supportsHostNameResolution="true";
            if [[ ! -f /etc/nsswitch.conf ]]; then
                echo "WARNING: Missing /etc/nsswitch.conf; will not be able to resolve Windows host names...";
                supportsHostNameResolution="false";
            else
                local winbindPkgCount=$(apt search winbind | grep -P "^is+(winbind|libnss-winbind)s+"|wc -l);
                if (( $winbindPkgCount < 2 )); then
                    echo "WARNING: Missing winbind / libnss-winbind packages; will not be able to resolve Windows host names...";
                    supportsHostNameResolution="false";
                fi
            fi

            if [[ "false" == "${supportsHostNameResolution}" ]]; then
                echo "ERROR: REMOTE_PATH is invalid; system doesn't support resolution of named host '${remoteHost}'.";
                echo "";
                echo "Use IP address instead or update system to support host name resolution.";
                echo "See:";
                echo "   https://www.techrepublic.com/article/how-to-enable-linux-machines-to-resolve-windows-hostnames/";
                echo "   https://askubuntu.com/a/516533/1003652";
                showUsage="true";

                echo "";
                echo "Attempting to resolve for next time ...";
                sudo apt-get install -y winbind libnss-winbind 2>/dev/null >/dev/null;
            else
                local unresolvedHostChk=$(ping -c 1 "$remoteHost" 2>&1 | grep 'Name or service not known'|wc -l);
                if [[ "0" == "${unresolvedHostChk}" ]]; then
                    echo "ERROR: REMOTE_PATH is invalid; system was unable to resolve named host '${remoteHost}'.";
                    echo "";
                    echo "Use IP address instead or update system to support host name resolution.";
                fi
            fi
        fi
    fi

    if [[ "true" == "${showUsage}" ]]; then
        echo "";
        echo "Expected usage:";
        echo "mountWindowsNetworkShare REMOTE_PATH LOCAL_PATH REMOTE_USER REMOTE_PWD";
        echo "";
        echo "Mounts the indicated path, if it is not already mounted.";
        echo "";
        echo "REMOTE_PATH must be in the form: //IPADDR/SHARE_NAME";
        echo "";
        echo "LOCAL_PATH  must be a valid local path.";
        echo "";
        echo "REMOTE_USER should be the user name on the remote machine. If it contains spaces, pass in quotes.";
        echo "";
        echo "REMOTE_PWD should be the user password on the remote machine. This should always be passed in quotes. Additionally, special characters should be preceded by a backslash (\) when using double-quotes. Especially:";
        echo " * dollar sign ($)";
        echo " * backslash (\)"
        echo " * backtick (`)";
        echo " * double-quote (")";
        echo " * exclaimation mark (!)";
        echo " * all special characters may be escaped but the above are required.";
        echo "";
        return;
    fi

    local isAlreadyMounted=$(mount|grep -P "${mountPoint}"|wc -l);
    if [[ "0" != "${isAlreadyMounted}" ]]; then
        echo "'${mountPoint}' is already mounted."
        return;
    fi

    if [[ ! -e "${mountPoint}" ]]; then
        sudo mkdir "${mountPoint}";
        sudo chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${mountPoint}";
    fi
    echo "Attempting to mount '${networkPath}' at '${mountPoint}' ...";
    sudo mount -t cifs "${networkPath}" "${mountPoint}" -o "user=${remoteLogin},username=${remoteLogin},password=${remotePassword},dir_mode=0777,file_mode=0777";
    if [[ "0" == "$?" ]]; then
        echo "-> SUCCESS";
    else
        echo "-> FAILURE";
    fi
}
function unmountWindowsNetworkShare() {
    local mountPoint="$1";

    # validate input
    if [[ "" == "${mountPoint}" ]]; then
        echo "ERROR: local mountPoint is empty";
        echo "Expected usage:";
        echo "unmountWindowsNetworkShare /local/path/to/mount/point";
        echo "";
        echo "   unmounts the indicated path, if it is mounted.";
        echo "";
        return;
    fi

    # check if mounted
    local isAlreadyMounted=$(mount|grep -P "${mountPoint}"|wc -l);
    if [[ "0" == "${isAlreadyMounted}" ]]; then
        echo "'${mountPoint}' is not currently mounted."
        return;
    fi
    echo "Attempting to unmount '${mountPoint}' ...";
    sudo umount --force "${mountPoint}";
    if [[ "0" == "$?" ]]; then
        echo "-> SUCCESS";
    else
        echo "-> FAILURE";
    fi
}
function displayGatewayIp() {
    ip r|grep default|sed -E 's/^.*b([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})b.*$/1/g';
}
function displayNetworkHostnames() {
    local gatewayIp=$(ip r|grep default|sed -E 's/^.*b([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})b.*$/1/g');

    echo -e "IP AddresstHostname";
    local ipAddr='';
    for ipAddr in $(arp -vn|grep -P '^d'|grep -Pv "\b(${gatewayIp})\b" |awk -F'\s+' '{print $1}'); do
        local hostName=$(nmblookup -A "${ipAddr}"|grep -Pvi '(Looking|No reply|<GROUP>|MAC Address)'|grep -i '<ACTIVE>'|head -1|sed -E 's/^s+(S+)s*.*$/1/');
        echo -e "${ipAddr}t${hostName}";
    done
}
#==========================================================================
# End Section: Network
#==========================================================================

#==========================================================================
# Start Section: Package Management
#==========================================================================
function addCustomSource() {
    # get sudo prompt out of way up-front so that it
    # doesn't appear in the middle of other output
    sudo ls -acl 2>/dev/null >/dev/null;

    local useLogFile="false";
    local logFile="/dev/null";
    if [[ "" != "${INSTALL_LOG}" ]]; then
        useLogFile="true";
        logFile="${INSTALL_LOG}";
    fi

    local errorMessage="";
    local showUsageInfo="false";
    local hasMissingOrInvalidInfo="false";

    if [[ "-h" == "$1" || "--help" == "$1" ]]; then
        showUsageInfo="true";
    fi

    local repoName="$1";
    local repoDetails="$2";
    if [[ "true" != "$showUsageInfo" ]]; then
        #if not just displaying help info, then check passed args
        if [[ "" == "${repoName}" ]]; then
            hasMissingOrInvalidInfo="true";
            errorMessage="no arguments";

        elif [[ "" == "${repoDetails}" ]]; then
            hasMissingOrInvalidInfo="true";
            errorMessage="missing arguments - must have REPO_NAME and REPO_DETAILS";

        elif [[ "official-package-repositories" == "$repoName" || "additional-repositories" == "$repoName" ]]; then
            hasMissingOrInvalidInfo="true";
            errorMessage="invalid REPO_NAME '${repoName}'; this name is reserved for system usage";

        elif [[ ! $repoName =~ ^[A-Za-z0-9][-A-Za-z0-9.]*[A-Za-z0-9]$ ]]; then
            hasMissingOrInvalidInfo="true";
            errorMessage="invalid REPO_NAME '${repoName}' - only alphanum/hyphen/period allowed, must start/end with alphanum";
        fi

        if [[ 'true' != "${hasMissingOrInvalidInfo}" ]]; then
            echo "Validating repo details";
            #check if more than 2 args
            arg3="$3";
            arg4="$4";
            arg5="$5";
            arg6="$6";
            if [[ 'deb' == "${repoDetails}" ]]; then
                echo "Found repoDetails as multiple arguments; attempting to combine ...";

                if [[ "" == "${arg3}" || "" == "${arg4}" ]]; then
                    hasMissingOrInvalidInfo="true";
                    errorMessage="missing/invalid repo details (only 'deb' but not server/path). Try quoting args after file name?";

                elif [[ ! $arg3 =~ ^https?://[A-Za-z0-9][-A-Za-z0-9.]*.*$ ]]; then
                    hasMissingOrInvalidInfo="true";
                    errorMessage="missing/invalid repo details (repo server) for '${arg3}'. Try quoting args after file name?";

                elif [[ "" != "${arg6}" ]]; then
                    repoDetails="deb $arg3 $arg4 $arg6";

                elif [[ "" != "${arg5}" ]]; then
                    repoDetails="deb $arg3 $arg4 $arg5";

                else
                    repoDetails="deb $arg3 $arg4";
                fi
            fi

            # Check known formats
            architecturelessRepoDetails=$(echo "$repoDetails"|sed 's/^([deb ]*)*[arch=[A-Za-z0-9][-A-Za-z0-9.]*] /1/');
            echo "architecturelessRepoDetails: '${architecturelessRepoDetails}'";
            if [[ $architecturelessRepoDetails =~ ^deb https?://[A-Za-z0-9][-A-Za-z0-9.]*[^ ]* [^ ]* ?[^ ]*$ ]]; then
                echo "OK: repo details appear to be valid.";
                repoDetails="$repoDetails";

            elif [[ $architecturelessRepoDetails =~ ^https?://[A-Za-z0-9][-A-Za-z0-9.*[^ ]* [^ ]* ?[^ ]*$ ]]; then
                echo "OK: repo details appear to be valid but does not start with 'deb'; prepending ...";
                repoDetails="deb $repoDetails";

            else
                hasMissingOrInvalidInfo="true";
                errorMessage="invalid/unsupported repo details format for '${repoDetails}'";
            fi
        fi
    fi

    if [[ "true" == "$showUsageInfo" || "true" == "$hasMissingOrInvalidInfo" ]]; then
        if [[ "true" == "$hasMissingOrInvalidInfo" ]]; then
            echo "ERROR: addCustomSource(): ${errorMessage}." | tee -a "${logFile}";
        fi
        echo "" | tee -a "${logFile}";
        echo "usage:" | tee -a "${logFile}";
        echo "   addCustomSource REPO_NAME REPO_DETAILS" | tee -a "${logFile}";
        echo "" | tee -a "${logFile}";
        echo "   Adds the specified source under /etc/apt/sources.list.d/" | tee -a "${logFile}";
        echo "   if it does not already exist. Both the repo name and the" | tee -a "${logFile}";
        echo "   details will be considered when checking for existing sources." | tee -a "${logFile}";
        echo "" | tee -a "${logFile}";
        echo "   REPO_NAME:    user-defined name; only used for the" | tee -a "${logFile}";
        echo "                 naming the apt source list file." | tee -a "${logFile}";
        echo "                 Names must start/end with alphanumeric characters." | tee -a "${logFile}";
        echo "                 Hyphens/periods are allowed for intervening characters." | tee -a "${logFile}";
        echo "" | tee -a "${logFile}";
        echo "   REPO_DETAILS: Info that goes in the apt source list file." | tee -a "${logFile}";
        echo "                 Generally is in the format of:" | tee -a "${logFile}";
        echo "                 deb REPO_BASE_URL REPO_RELATIVE_PATH" | tee -a "${logFile}";
        echo "" | tee -a "${logFile}";
        echo "examples:" | tee -a "${logFile}";
        echo "   addCustomSource sublimetext 'deb https://download.sublimetext.com/ apt/stable/' " | tee -a "${logFile}";
        echo "   addCustomSource sublimetext deb https://download.sublimetext.com/ apt/stable/ " | tee -a "${logFile}";
        echo "" | tee -a "${logFile}";
        return;
    fi

    #check if it already exists...
    echo "Checking if repo source file already exists..." | tee -a "${logFile}";
    if [[ -f "/etc/apt/sources.list.d/${repoName}.list" ]]; then
        echo "addCustomSource(): Source ${repoName} already defined; skipping..." | tee -a "${logFile}";
        return;
    else
        echo "  -> PASSED";
    fi

    #check if details already exist...
    echo "Checking if repo details not already defined in another file ..." | tee -a "${logFile}";
    local existingRepoDetsCount=$(sudo grep -Ri "${repoDetails}" /etc/apt/sources.list.d/*.list 2>/dev/null|wc -l);
    if [[ "0" != "${existingRepoDetsCount}" ]]; then
        echo "addCustomSource(): Repo details already defined for '${repoDetails}'; skipping..." | tee -a "${logFile}";
        echo "Existing matches:" | tee -a "${logFile}";
        echo "" | tee -a "${logFile}";
        sudo grep -RHni "${repoDetails}" /etc/apt/sources.list.d/*.list 2>/dev/null | tee -a "${logFile}";
        return;
    else
        echo "  -> PASSED";
    fi

    # add new source
    echo "Adding source as '${repoName}.list' ..." | tee -a "${logFile}";
    echo "${repoDetails}" | sudo tee "/etc/apt/sources.list.d/${repoName}.list" >/dev/null;

    # safety
    sudo chown root:root /etc/apt/sources.list.d/*.list;
    sudo chmod 644 /etc/apt/sources.list.d/*.list;

}
function listUninstalledPackageRecommends() {
    local packageList="$1";
    local hasRecommends=$(sudo apt install --assume-no "${packageList}" 2>/dev/null|grep 'Recommended packages:'|wc -l);
    if [[ "0" == "${hasRecommends}" ]]; then
        echo "";
        return;
    fi
    # note the first sed is to remove a pipe that was present in
    # actual output from apt install; see 'sudo apt install --assume-no ledgersmb'
    sudo apt install --assume-no "${packageList}" 2>/dev/null|sed -E 's/(s+)|s+/1/g'|sed '/^The following NEW packages will be installed:$/Q'|sed '0,/^Recommended packages:$/d'|sed -E 's/^s+|s+$//g'|tr ' ' 'n';
}
function listUninstalledPackageSuggests() {
    local packageList="$1";
    local hasSuggests=$(sudo apt install --assume-no "${packageList}" 2>/dev/null|grep 'Suggested packages:'|wc -l);
    if [[ "0" == "${hasSuggests}" ]]; then
        echo "";
        return;
    fi
    # note the first sed is to remove a pipe that was present in
    # actual output from apt install; see 'sudo apt install --assume-no ledgersmb'
    sudo apt install --assume-no "${packageList}" 2>/dev/null|sed -E 's/(s+)|s+/1/g'|sed '/^The following NEW packages will be installed:$/Q'|sed '/^Recommended packages:$/Q'|sed '0,/^Suggested packages:$/d'|sed -E 's/^s+|s+$//g'|tr ' ' 'n';
}
function previewUpgradablePackagesDownloadSize() {
   #get sudo prompt out of the way so it doesn't appear in the middle of output
    sudo ls -acl >/dev/null;

    echo "";
    echo "=============================================================";
    echo "Updating apt cache ...";
    echo "=============================================================";
    sudo apt update 2>&1|grep -Pv '^(Build|Fetch|Get|Hit|Ign|Read|WARNING|$)'|sed -E 's/^(.*) Run.*$/-> 1/g';
    echo "-> Getting list of upgradable packages ...";

    local upgradablePackageList=$(sudo apt list --upgradable 2>&1|grep -Pv '^(Listing|WARNING|$)'|sed -E 's/^([^/]+)/.*$/1/g'|tr 'n' ' '|sed -E 's/^s+|s+$//g');
    local upgradablePackageArray=($(echo "$upgradablePackageList"|tr ' ' 'n'));
    #echo "upgradablePackageArray size: ${#upgradablePackageArray[@]}"

    echo "";
    echo "=============================================================";
    echo "Calculating download sizes (note: there may be overlaps) ...";
    echo "=============================================================";

    echo "";
    newPackageCount=0;
    for packageName in "${upgradablePackageArray[@]}"; do
        #echo "packageName: '$packageName'"
        apt show "$packageName" 2>/dev/null|grep --color=never -P '(Package|Version|Installed-Size|Download-Size):';
        is_installed=$(apt install --simulate --assume-yes "$packageName" 2>/dev/null|grep --color=never 'already the newest');
        if [[ "" == "${is_installed}" ]]; then
            newPackageCount=$(( newPackageCount + 1 ));
            aptitude install --simulate --assume-yes --without-recommends "$packageName" 2>/dev/null|grep 'Need to get'|tail -1|sed -E 's/^Need to get ([0-9[[0-9.,]*) ([kmgKMG]i?[Bb]).*$/With dependencies only:           1 2/g'
            aptitude install --simulate --assume-yes --with-recommends    "$packageName" 2>/dev/null|grep 'Need to get'|tail -1|sed -E 's/^Need to get ([0-9[[0-9.,]*) ([kmgKMG]i?[Bb]).*$/With dependencies and recommends: 1 2/g'
        else
            echo "${is_installed}";
        fi
        echo "";
    done
    echo "";
    echo "=============================================================";
    echo "Total:";
    echo "=============================================================";
    #echo "test: ${upgradablePackageArray[@]}"
    aptitude install --simulate --assume-yes --without-recommends "${upgradablePackageArray[@]}" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9.,]*) ([kmgKMG]i?[Bb]).*$/With dependencies only:           1 2/g'
    aptitude install --simulate --assume-yes --with-recommends    "${upgradablePackageArray[@]}" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9.,]*) ([kmgKMG]i?[Bb]).*$/With dependencies and recommends: 1 2/g'
    echo "";
}
function previewPackageDownloadSize() {
    if [[ "0" == "${#@}" ]]; then
        echo "Expected usage:";
        echo "previewPackageDownloadSize PACKAGE_NAME";
        echo "previewPackageDownloadSize PACKAGE1 [PACKAGE2 [PACKAGE3 [...]]]] ";
        return;
    fi
   #get sudo prompt out of the way so it doesn't appear in the middle of output
    sudo ls -acl >/dev/null;

    echo "=============================================================";
    newPackageCount=0;
    for packageName in "$@"; do
        apt show "$packageName" 2>/dev/null|grep --color=never -P '(Package|Version|Installed-Size|Download-Size):';
        is_installed=$(apt install --simulate --assume-yes "$packageName" 2>/dev/null|grep --color=never 'already the newest');
        if [[ "" == "${is_installed}" ]]; then
            newPackageCount=$(( newPackageCount + 1 ));
            aptitude install --simulate --assume-yes --without-recommends "$packageName" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9.,]*) ([kmgKMG]i?[Bb]).*$/Without recommends: 1 2/g'
            aptitude install --simulate --assume-yes --with-recommends "$packageName" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9.,]*) ([kmgKMG]i?[Bb]).*$/With recommends:    1 2/g'
        else
            echo "${is_installed}";
        fi
        echo "=============================================================";
    done
    if [[ "0" != "${newPackageCount}" ]]; then
        echo "Total:"
        aptitude install --simulate --assume-yes --without-recommends "${@}" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9.,]*) ([kmgKMG]i?[Bb]).*$/Without recommends: 1 2/g'
        aptitude install --simulate --assume-yes --with-recommends "${@}" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9.,]*) ([kmgKMG]i?[Bb]).*$/With recommends:    1 2/g'
    fi
}
function installPackages() {
    local __INS_OPTS__="-y -qq -o=Dpkg::Use-Pty=0";
    local __PKG_LIST__="$1";
    local __INS_RECS__="$2";
    local __INS_SUGS__="$3";
    local __SHOW_PROG__="$4";

    if [[ "true" == "${__INS_RECS__}" ]]; then
        __INS_OPTS__="${__INS_OPTS__} --install-recommends";
    fi
    if [[ "true" == "${__INS_SUGS__}" ]]; then
        __INS_OPTS__="${__INS_OPTS__} --install-suggests";
    fi
    if [[ "true" == "${__SHOW_PROG__}" ]]; then
        __INS_OPTS__="${__INS_OPTS__} --show-progress";
    fi

    if [[ "" == "$INSTALL_LOG" ]]; then
        sudo apt install ${__INS_OPTS__} ${__PKG_LIST__} 2>&1 | grep -v 'apt does not have a stable CLI interface';
        return;
    fi
    echo -e "nRunning: sudo apt install ${__INS_OPTS__} ${__PKG_LIST__} | grep -v 'apt does not have a stable CLI interface'" | tee -a "${INSTALL_LOG}";
    sudo apt install ${__INS_OPTS__} ${__PKG_LIST__} 2>&1 | grep -v 'apt does not have a stable CLI interface' | tee -a "${INSTALL_LOG}";
}
function installPackagesWithRecommends() {
    installPackages "$1" "true" "false" "$2";
}
function installPackagesWithRecommendsAndSuggests() {
    installPackages "$1" "true" "true" "$2";
}
function list_installed_ppa_repos () {
    echo "===================================================";
    echo "Launchpad PPAs:";
    echo "===================================================";
    grep -PRh '^debs+https?://ppa.launchpad.net' /etc/apt/sources.list.d/*.list|awk -F' ' '{print $2}'|awk -F/ '{print "sudo apt-add-repository ppa:"$4"/"$5}'|sort -u;
    echo "";
    echo "===================================================";
    echo "Custom PPAs:";
    echo "===================================================";
    grep -PR '^debs+' /etc/apt/sources.list.d/*.list --exclude=official* --exclude=additional*|grep -v 'ppa.launchpad.net'|sort -u|sed -E "s/^(\/etc\/apt\/sources.list.d\/[^:]+.list):(.*)$/echo "2"|sudo tee "1"/";
}
#==========================================================================
# End Section: Package Management
#==========================================================================

#==========================================================================
# Start Section: Processes
#==========================================================================
function getProcessInfoByInteractiveMouseClick() {
    ps -o pid,comm,start,etime,pcpu,pmem,size,args -p $(echo $(PIDSTR=$(xprop _NET_WM_PID); echo "$PIDSTR" | sed "s/^.*[^0-9]([0-9][0-9]*)[^0-9]*$/1/g"))
}
function getProcessIdByWindowName() {
    local TARGET_NAME="$1";
    xdotool search --class "$TARGET_NAME" getwindowpid
}
function getProcessInfoByWindowName() {
    local TARGET_NAME="$1";
    ps -o pid,comm,start,etime,pcpu,pmem,size,args -p $(xdotool search --class "$TARGET_NAME" getwindowpid);
}
#==========================================================================
# End Section: Processes
#==========================================================================

#==========================================================================
# Start Section: Hardware
#==========================================================================
function printBatteryPercentages() {
    # this assumes that you only have 1 wireless device

    # 1. Get info from upower; this won't have everything (missing xbox 360 wireless)
    #       but it should have wireless kb/m and possibly some wireless controllers
    #
    #   1.1. get the dump from upower
    #   1.2. remove any info blocks for 'daemon'; they don't have any worthwhile info anyway
    #           perl -0 -pe 's/(?:^|nn)Daemon:.*?nn/n/gsm'
    #   1.3. remove any device attribute lines not related to either model or (battery) percentage
    #        while simultaneously reformatting
    #           perl -ne 'if ( /^$/ ) { print "n" } elsif ( /^.*model:[ t]+(.*)$/ ) { print "$1: " } elsif ( /^.*percentage:[ t]+(.*)$/ ) { print "$1" }'

    upower --dump | perl -0 -pe 's/(?:^|nn)Daemon:.*?nn/n/gsm' | perl -ne 'if ( /^$/ ) { print "n" } elsif ( /^.*model:[ t]+(.*)$/ ) { print "$1: " } elsif ( /^.*percentage:[ t]+(.*)$/ ) { print "$1" }' | sed '/^$/d';
}
function unmuteAllAlsaAudioControls() {
    local INITIAL_IFS="$IFS";
    IFS='';
    amixer scontrols | sed "s|[^']*('[^']*').*|1|g" |
    while read control_name
    do
        if [[ "'Auto-Mute Mode'" ==  "$control_name" || "'Input Source'" ==  "$control_name" ]]; then
            #Skip these ones -- not really valid sources
            continue;
        fi
        #echo "control name: $control_name";
        amixer -q set "$control_name" 100% unmute;
        if [[ "0" != "$?" ]]; then
            echo "Error unmuting control name: $control_name";
        fi
    done
    IFS="$INITIAL_IFS";
}
#==========================================================================
# End Section: Hardware
#==========================================================================

#==========================================================================
# Start Section: Services
#==========================================================================
function stopSystemdServices () {
    for passedarg in "$@"; do
        #echo "passedarg is $passedarg"
        sudo systemctl stop $passedarg
    done
}
function disableSystemdServices () {
    for passedarg in "$@"; do
        #echo "passedarg is $passedarg"
        sudo systemctl disable $passedarg
    done
}
function stopAndDisableSystemdServices () {
    for passedarg in "$@"; do
        #echo "passedarg is $passedarg"
        sudo systemctl stop $passedarg
        sudo systemctl disable $passedarg
    done
}
function enableSystemdServices () {
    for passedarg in "$@"; do
        #echo "passedarg is $passedarg"
        sudo systemctl enable $passedarg
    done
}
function restartSystemdServices () {
    for passedarg in "$@"; do
        #echo "passedarg is $passedarg"
        sudo systemctl restart $passedarg
    done
}
function enableAndRestartSystemdServices () {
    for passedarg in "$@"; do
        #echo "passedarg is $passedarg"
        sudo systemctl enable $passedarg
        sudo systemctl restart $passedarg
    done
}
#==========================================================================
# End Section: Services
#==========================================================================

#==========================================================================
# Start Section: Launchers
#==========================================================================
function openGitExtensionsBrowse() {
    #launch background process
    (cd "$1"; /usr/bin/gitext >/dev/null 2>/dev/null;)&
}
function openFileInTextEditor() {
    openFileInSublime "$1";
}
function openFileInSublime() {
    #launch background process
    (/usr/bin/sublime "$1" >/dev/null 2>/dev/null;)&
}
function openFileInXed() {
    #launch background process
    (/usr/bin/xed "$1" >/dev/null 2>/dev/null;)&
}
function mergeFilesInMeld() {
    #launch background process
    (/usr/bin/meld "$1" "$2" >/dev/null 2>/dev/null;)&
}
function openNemo() {
    #launch background process
    (/usr/bin/nemo "$1" >/dev/null 2>/dev/null)&
}
#==========================================================================
# End Section: Launchers
#==========================================================================

#==========================================================================
# Start Section: Reference
#==========================================================================
# colorize man pages. See: https://www.ryanschulze.net/archives/2113
function man () {
  LESS_TERMCAP_mb=$(tput setaf 4)  LESS_TERMCAP_md=$(tput setaf 4;tput bold)   LESS_TERMCAP_so=$(tput setaf 7;tput setab 4;tput bold)   LESS_TERMCAP_us=$(tput setaf 6)   LESS_TERMCAP_me=$(tput sgr0)   LESS_TERMCAP_se=$(tput sgr0)   LESS_TERMCAP_ue=$(tput sgr0)   command man "$@"
}
function referenceGroupCommands () {
    # -------------------------------------------------------------------------------------------------
    # References:
    # https://www.howtogeek.com/50787/add-a-user-to-a-group-or-second-group-on-linux/
    # man find
    # 2>&- usage:
    #   https://unix.stackexchange.com/a/19433, https://stackoverflow.com/a/20564208, https://unix.stackexchange.com/a/131833
    # -------------------------------------------------------------------------------------------------

    echo "Group Administration Commands:";
    echo "======================================================================================================";
    echo " sudo groupadd GROUP                     # create new group 'GROUP' ";
    echo " sudo groupadd -g 1337 GROUP             # create new group 'GROUP' with groupid (gid) as 1337 ";
    echo " sudo usermod -a -G GROUP USER           # addsexisting user 'USER' to existing group 'GROUP'";
    echo " sudo usermod -a -G GROUP1,GROUP2 USER   # add existing user 'USER' to groups 'GROUP1' and 'GROUP2'";
    echo " sudo usermod -g GROUP USER              # change the primary group of user 'USER' to group 'GROUP'";
    echo " sudo useradd -G GROUP USER              # create new user 'USER' and adds to existing group 'GROUP'";
    echo " sudo groupdel GROUP                     # delete group 'GROUP'";
    echo " sudo groupmod -n NEWGROUP OLDGROUP      # rename group 'OLDGROUP' to 'NEWGROUP'";
    echo "";
    echo " groups                                  # list the groups current user account is assigned to";
    echo " groups USER                             # list the groups user 'USER' is assigned to";
    echo " members GROUP                           # list the members of group 'GROUP'";
    echo " getent group                            # list all groups on system";
    echo " getent group GROUP                      # list details for group 'GROUP'";
    echo " getent group {1000..60000}              # list all groups on system with gids between 1000 and 60000";
    echo " cat /etc/group                          # manually query group file (don't modify as this could corrupt system)";
    echo " sudo chgrp [-R] GROUP FILE              # change group ownership to GROUP for file FILE";
    echo " find . ! -perm /g=w 2>/dev/null         # find files that the owner can't write to";
    echo " find . ! -perm /g=w 2>&-                # find files that the owner can't write to (alternate)";
    echo " find . ! -group GROUP 2>/dev/null              # find files not owned by group 'GROUP'";
    echo " find . ! -group GROUP 2>&-                     # find files not owned by group 'GROUP' (alternate)";
    echo " find . -group GROUP ! -perm /g=w 2>/dev/null   # find unwritable files owned by group 'GROUP'";
    echo " find . -group GROUP ! -perm /g=w 2>&-          # find unwritable files owned by group 'GROUP' (alternate)";
    echo "";
    echo "# Useful aliases:";
    echo "  groupsref | groupsdoc                  # this help text";
    echo "  lsgroups                               # display non-service groups and their members";
    echo "  lsallgroups                            # display all groups and their members (sorted by id)";
    echo "  lsallgroupsbyname                      # display all groups and their members (sorted by name)";
    echo "";
}
function referenceUserCommands () {
    # -------------------------------------------------------------------------------------------------
    # References:
    # https://www.howtogeek.com/50787/add-a-user-to-a-group-or-second-group-on-linux/
    # man useradd
    # man usermod
    # man find
    # 2>&- usage:
    #   https://unix.stackexchange.com/a/19433, https://stackoverflow.com/a/20564208, https://unix.stackexchange.com/a/131833
    # -------------------------------------------------------------------------------------------------

    echo "User Administration Commands:";
    echo "=========================================================================================================";
    echo "# Create new user 'USER' with LAN access but no local login (reqs running passwd before login):";
    echo "  sudo adduser --gecos "" --no-create-home --disabled-login --shell /bin/false USER";
    echo "";
    echo "# Create new user 'USER' (w home dir, login enabled, reqs running passwd before login):";
    echo "  sudo useradd -m [-g GROUP] [-s SHELL] USER";
    echo "  sudo useradd --create-home [-gid GROUP] [--shell SHELL] USER";
    echo "  sudo usermod [-g GROUP] [-s SHELL] USER";
    echo "";
    echo "# Create new user with default password (only use for initial pwd as this is viewable in .bash_history):";
    echo "  sudo useradd -m [-g GROUP] [-s SHELL] -p PASSWD_HASH USER";
    echo "  sudo useradd --create-home [-gid GROUP] [--shell SHELL] -password PASSWD_HASH USER";
    echo "  sudo usermod [-g GROUP] [-s SHELL] -p PASSWD_HASH USER";
    echo "    ex: sudo useradd -m -p $(echo 'abcd1234'|mkpasswd -m sha-512 -S saltsalt -s) USER";
    echo "";
    echo "# Create new user 'USER' (no home dir, login disabled, reqs running passwd before login):";
    echo "  sudo useradd [-g GROUP]  [-s SHELL] USER";
    echo "  sudo useradd -f 0 -M [-g GROUP]  [-s SHELL] USER";
    echo "  sudo useradd --no-create-home --inactive 0 [--gid GROUP] [--shell SHELL] USER";
    echo "  sudo usermod -L [-g GROUP] [-s SHELL] USER";
    echo "  sudo usermod --lock [--gid GROUP] [--shell SHELL] USER";
    echo "";
    echo "# Move home directory of user 'USER' to NEWHOME:";
    echo "  sudo usermod -m -d NEWHOME -m USER";
    echo "  sudo usermod --move-home --home NEWHOME -m USER";
    echo "";
    echo "# Rename user 'OLDUSER' to 'NEWUSER' (no change to homedir, no change to groupname/group ownership):";
    echo "  sudo usermod -l NEWUSER OLDUSER";
    echo "  sudo usermod --login NEWUSER OLDUSER";
    echo "";
    echo "# Rename user 'OLDUSER' to 'NEWUSER' AND move homedir to NEWHOME (no change to groupname/group ownership):";
    echo "  sudo usermod -m -d NEWHOME -l NEWUSER OLDUSER";
    echo "  sudo usermod --move-home --home NEWHOME --login NEWUSER OLDUSER";
    echo "";
    echo "# Delete user 'USER' (but leave their home dir):";
    echo "  sudo userdel USER";
    echo "";
    echo "# Delete user 'USER' (and remove their home dir):";
    echo "  sudo userdel -r USER";
    echo "";
    echo " id                                      # get id of current user";
    echo " id USER                                 # get id of user 'USER'";
    echo " whoami                                  # display name of current user";
    echo " who --all                               # display logged in users (includes ssh but not terminals spawned by current user)";
    echo " finger USER                             # display basic information about user 'USER'";
    echo " ssh USER@localhost                      # login to user 'USER' on local machine";
    echo " ssh USER@127.0.0.1                      # login to user 'USER' on local machine";
    echo " su - USER                               # switch to user 'USER' from terminal (reboot req'd for new users)";
    echo " exit                                    # return to initial terminal (after successfully using either of the previous 3 commands)";
    echo " su - USER -c COMMAND [args]             # run command as user 'USER'";
    echo " passwd                                  # change password for the current user";
    echo " sudo passwd USER                        # change password for user 'USER'";
    echo " sudo passwd --expire USER               # force user 'USER' to change their password next time they log in";
    echo " groups                                  # list the groups current user account is assigned to";
    echo " groups USER                             # list the groups user 'USER' is assigned to";
    echo " getent passwd                           # list all users on system (including service accounts)";
    echo " getent passwd USER                      # list details for user 'USER'";
    echo " getent passwd {1000..60000}             # list all users on system with uids between 1000 and 60000";
    echo " cat /etc/passwd                         # manually query user file (don't modify as this could corrupt system)";
    echo " sudo chown [-R] USER:GROUP FILE         # change ownership to USER:GROUP for file FILE";
    echo " sudo chown [-R] USER FILE               # change ownership to USER for file FILE";
    echo " find . ! -perm /u=w 2>/dev/null         # find files that the owner can't write to";
    echo " find . ! -perm /u=w 2>&-                # find files that the owner can't write to (alternate)";
    echo " find . ! -user USER 2>/dev/null              # find files not owned by user 'USER'";
    echo " find . ! -user USER 2>&-                     # find files not owned by user 'USER' (alternate)";
    echo " find . -user USER ! -perm /u=w 2>/dev/null   # find unwritable files owned by user 'USER'";
    echo " find . -user USER ! -perm /u=w 2>&-          # find unwritable files owned by user 'USER' (alternate)";
    echo " wall MESSAGE_TEXT                       # broadcast message to all remotely loggged in users (e.g. ssh users)";
    echo " wall -g GROUP MESSAGE_TEXT              # broadcast message to remotely loggged in users in group 'GROUP'";
    echo " sudo pgrep -a -u USER                   # list all processes run by user 'USER'";
    echo " sudo pkill -9 -u USER                   # kill all processes run by user 'USER' (also kicks user login)";
    echo " sudo killall -9 -u USER                 # kill all processes run by user 'USER' (alternate; also kicks user login)";
    echo " sudo chsh -s /bin/false USER            # disable future logins by user 'USER'"
    echo " sudo chsh -s /usr/sbin/nologin USER     # disable future logins by user 'USER' (alternate)"
    echo "";
    echo "# Useful aliases:";
    echo "  usersref | usersdoc                    # this help text";
    echo "  lsusers                                # display non-service account users, their home dirs, and their shells";
    echo "  lsallusers                             # display all users, their home dirs, and their shells (sorted by id)";
    echo "  lsallusersbyname                       # display all users, their home dirs, and their shells (sorted by name)";
    echo "";
}
function referencePermissions () {
    echo "Permission Administration Commands:";
    echo "=======================================";
    echo "# Ownership";
    echo " sudo chown [-R] USER:GROUP FILE         # change ownership to USER:GROUP for file FILE";
    echo " sudo chown [-R] USER FILE               # change ownership to USER for file FILE";
    echo " sudo chgrp [-R] GROUP FILE              # change group ownership to GROUP for file FILE";
    echo "";
    echo "# Access Controls";
    echo " sudo chown [-R] OCTAL_PERMS FILE        # change permissions for file FILE";
    echo " sudo chown [-R] PERM_ABBREV FILE        # change permissions for file FILE";
    echo "";
    echo "# Octal Permission Legend";
    echo "  Octal perms can be given as 3- or 4-digit numbers. When given as 4 digit numbers, ";
    echo "  focus on the 3 right-most positions for the typical access control permissions.";
    echo "";
    echo "  The values in each position are considered separately rather than as a whole.";
    echo "  So 777 is not seven hundred seventy seven but rather 7-7-7.";
    echo "  Each of those numbers represents the permissions for a set of users:"
    echo "    U-- => the 3rd digit from the right (U) = user permissions (for the user owning the file)";
    echo "    -G- => the 2nd digit from the right (G) = group permissions (for the group owning the file)";
    echo "    --O => the 1st digit from the right (O) = other user permissions";
    echo "";
    echo "  The individual values for any set of users can range from 0 (no perms) to 7 (full perms)";
    echo "  Just start with 0 and add the numerical values of whatever permissions you want. The values";
    echo "  of the various permissions are as follows:";
    echo "    0 == No Permissions";
    echo "    1 == Execute permission (needed by all folders; needed to run programs; not needed for regular files)";
    echo "    2 == Write permission (needed to write, delete, or modify a file)";
    echo "    4 == Read permission (needed to read, view, or access a file)";
    echo "  so:";
    echo "    Read (4) + Nothing (0)             == 4";
    echo "    Read (4) + Execute (1)             == 5";
    echo "    Read (4) + Write (2)               == 6";
    echo "    Read (4) + Write (2) + Execute (1) == 7";
    echo ""
    echo "  some examples with the full Octal code can be read as:";
    echo "    777 = User can Read+Write+Execute (7), Group can Read+Write+Execute (7), Others can Read+Write+Execute (7)";
    echo "    755 = User can Read+Write+Execute (7), Group can Read+Execute (5), Others can Read+Execute (5)";
    echo "    766 = User can Read+Write+Execute (7), Group can Read+Write (6), Others can Read+Write (6)";
    echo "    640 = User can Read+Write (0), Group can Read (4), Others have no perms (0)";
    echo "";
    echo "# Octal Permission Examples";
    echo "  chmod 000 FILE => ---------- FILE ";
    echo "  chmod 100 FILE => ---x------ FILE ";
    echo "  chmod 200 FILE => --w------- FILE ";
    echo "  chmod 300 FILE => --wx------ FILE ";
    echo "  chmod 400 FILE => -r-------- FILE ";
    echo "  chmod 500 FILE => -r-x------ FILE ";
    echo "  chmod 600 FILE => -rw------- FILE ";
    echo "  chmod 700 FILE => -rwx------ FILE ";
    echo "  chmod 770 FILE => -rwxrwx--- FILE ";
    echo "  chmod 777 FILE => -rwxrwxrwx FILE ";
    echo "";
    echo "";
    echo "# Permission Abbreviations Legend";
    echo "  Alternately, you can skip Octal and just use abbreviations such as u=r. When doing so,";
    echo "  you'll specify 2 sets of letters: the letters on the left indicate which set of users";
    echo "  the permission applies to and the letters on the right indicate the actual perms.";
    echo "  There are also some special flags that can be set this way that yu cannot set with Octal codes";
    echo "";
    echo "  target letters (left side) - these are case-sensitive:";
    echo "    u: user";
    echo "    g: group";
    echo "    o: other";
    echo "    a: all (same as user + group + owner)";
    echo "";
    echo "  access letters (right side) - these are case-sensitive:";
    echo "    r: read";
    echo "    w: write";
    echo "    x: execute";
    echo "    s: sticky bit with execute (setuid bit for user, setgid bit for group, no meaning for others)";
    echo "    S: sticky bit without execute (setuid bit for user, setgid bit for group, no meaning for others)";
    echo "       -> Don't use S/s without reading up on them."
    echo "  so:";
    echo "    Read (r) + Nothing (nothing        == r";
    echo "    Read (r) + Execute (x)             == rx";
    echo "    Read (r) + Write (w)               == rw";
    echo "    Read (r) + Write (w) + Execute (x) == rwx";
    echo ""
    echo "  You can use equals (=) to set, plus (+) to add, and minus (-) to remove permissions."
    echo "  Equals sets to the exact value specified, plus only adds what is specified, and"
    echo "  minus only removes what is specified. Any non-conflicting combination of these can be used."
    echo "  some examples with the full Octal code can be read as:";
    echo "    a=rwx         : Set Read+Write+Execute (rwx) for All Users (User+Group+Others)";
    echo "    a+rx,u+w,go-w : Add Read+Execute (rx) for All Users (User+Group+Others), Add Write for User (u+w), ";
    echo "                    and Remove Write for Group and Others (go-w)";
    echo "    u=rwx,go=rx   : Set Read+Write+Execute for User(u=rwx), Read+Execute for Group/Others (go=rx)";
    echo "    ug=rwx,o=r    : Set Read+Write+Execute for User/Group (ug=rwx), Read for Others (o=r)";
    echo "    u=rw,g=r,o=   : Set Read+Write for User (u=rw), Read for Group (g=r), no perms for Others (o=)";
    echo "    a-x,u+rw,g+r,g-w,o-rw   : Remove execute for all (a-x), add Read+Write for User (u+rw),";
    echo "                              add Read for Group (g+r), remove Write for Group (g-w),";
    echo "                              remove Read+Write for Others (o-rw)";
    echo "";
    echo " # Permission Abbreviation Examples";
    echo "  chmod a=      FILE => ---------- FILE ";
    echo "  chmod a=x     FILE => ---x--x--x FILE ";
    echo "  chmod a=r     FILE => -r--r--r-- FILE ";
    echo "  chmod a=w     FILE => --w--w--w- FILE ";
    echo "  chmod a=rw    FILE => -rw-rw-rw- FILE ";
    echo "  chmod a=rwx   FILE => -rwxrwxrwx FILE ";
    echo "  chmod u=x     FILE => ---x------ FILE ";
    echo "  chmod u=w     FILE => --w------- FILE ";
    echo "  chmod u=wx    FILE => --wx------ FILE ";
    echo "  chmod u=r     FILE => -r-------- FILE ";
    echo "  chmod u=rx    FILE => -r-x------ FILE ";
    echo "  chmod u=rw    FILE => -rw------- FILE ";
    echo "  chmod u=rwx   FILE => -rwx------ FILE ";
    echo "  chmod gu=wrx  FILE => -rwxrwx--- FILE ";
    echo "  chmod ugo=xrw FILE => -rwxrwxrwx FILE ";
    echo "";
}
function referenceOctalPermissions () {
    echo "Octal Permission Examples:";
    echo "====================================";
    echo "  chmod 000 FILE => ---------- FILE ";
    echo "  chmod 100 FILE => ---x------ FILE ";
    echo "  chmod 200 FILE => --w------- FILE ";
    echo "  chmod 300 FILE => --wx------ FILE ";
    echo "  chmod 400 FILE => -r-------- FILE ";
    echo "  chmod 500 FILE => -r-x------ FILE ";
    echo "  chmod 600 FILE => -rw------- FILE ";
    echo "  chmod 700 FILE => -rwx------ FILE ";
    echo "";
    echo "Common Octal Permissions:";
    echo "====================================";
    echo "  chmod 400 FILE => -r-------- FILE ";
    echo "  chmod 440 FILE => -r--r----- FILE ";
    echo "  chmod 444 FILE => -r--r--r-- FILE ";
    echo "";
    echo "  chmod 500 FILE => -r-x------ FILE ";
    echo "  chmod 540 FILE => -r-xr----- FILE ";
    echo "  chmod 544 FILE => -r-xr--r-- FILE ";
    echo "  chmod 550 FILE => -r-xr-x--- FILE ";
    echo "  chmod 554 FILE => -r-xr-xr-- FILE ";
    echo "  chmod 555 FILE => -r-xr-xr-x FILE ";
    echo "";
    echo "  chmod 600 FILE => -rw------- FILE ";
    echo "  chmod 640 FILE => -rw-r----- FILE ";
    echo "  chmod 644 FILE => -rw-r--r-- FILE ";
    echo "  chmod 660 FILE => -rw-rw---- FILE ";
    echo "  chmod 664 FILE => -rw-rw-r-- FILE ";
    echo "  chmod 666 FILE => -rw-rw-rw- FILE ";
    echo "";
    echo "  chmod 700 FILE => -rwx------ FILE ";
    echo "  chmod 740 FILE => -rwxr----- FILE ";
    echo "  chmod 744 FILE => -rwxr--r-- FILE ";
    echo "  chmod 750 FILE => -rwxr-x--- FILE ";
    echo "  chmod 755 FILE => -rwxr-xr-x FILE ";
    echo "  chmod 770 FILE => -rwxrwx--- FILE ";
    echo "  chmod 775 FILE => -rwxrwxr-x FILE ";
    echo "  chmod 777 FILE => -rwxrwxrwx FILE ";
    echo "";
}
#==========================================================================
# End Section: Reference
#==========================================================================
