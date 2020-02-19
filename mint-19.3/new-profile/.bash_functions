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

#==========================================================================
# End Section: Media files
#==========================================================================

#==========================================================================
# Start Section: Wine
#==========================================================================

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
# Start Section: Processes
#==========================================================================

#==========================================================================
# End Section: Processes
#==========================================================================

#==========================================================================
# Start Section: Hardware
#==========================================================================

#==========================================================================
# End Section: Hardware
#==========================================================================

#==========================================================================
# Start Section: Services
#==========================================================================

#==========================================================================
# End Section: Services
#==========================================================================

#==========================================================================
# Start Section: Launchers
#==========================================================================

#==========================================================================
# End Section: Launchers
#==========================================================================

#==========================================================================
# Start Section: Reference
#==========================================================================

#==========================================================================
# End Section: Reference
#==========================================================================
