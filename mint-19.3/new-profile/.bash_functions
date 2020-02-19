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
function openGitExtensionsBrowse() {
    #launch background process
    (cd "$1"; /usr/bin/gitext >/dev/null 2>/dev/null;)&
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
