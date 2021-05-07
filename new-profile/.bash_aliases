#====================================================
# custom bindings / functions
#====================================================
alias title="setGnomeTerminalTitle";
alias mkcd="makeThenChangeDir";

alias runas='runCommandAsUser'

#====================================================
# Sudo and admin related commands
#====================================================
alias sudol='sudo l'
alias s='sudo l'
alias sl='sudo l'
alias audol='sudo l'
alias audok='sudo l'
alias sudok='sudo l'
alias sudp='sudo'
alias sudi='sudo'
alias audo='sudo'
alias audp='sudo'
alias fucking='sudo'
#alias fuck='sudo $(history -p \!\!)'
alias su!='sudo -i'
alias root='sudo -i'

alias suhere="echo 'Login as: root';su - root -c \"cd '\$PWD'; bash\"";

alias fixsystemperms='sudo ls -acl 2>/dev/null >/dev/null; fixSystemPermissions --all';
alias fixsysperms='sudo ls -acl 2>/dev/null >/dev/null; fixSystemPermissions --all';

alias cp-o='cp -a --no-preserve=ownership'
alias cpa-o='cp -a --no-preserve=ownership'
alias cpo='cp -a --no-preserve=ownership'

alias chgroup='chgrp'

alias uptime='echo "displaying: /usr/bin/uptime --pretty"; /usr/bin/uptime --pretty'
alias upsince='/usr/bin/uptime --since'


# note: restart is reserved for restarting services rather than for system 'reboot'

# the following aliases split header and list output into 2 calls
# so that the list output can be piped to other commands
# without disturbing the header or separator lines
alias lsusers='printUserListHeaders;listUsers --noheader'
alias listusers='printUserListHeaders;listUsers --noheader'
alias lsallusers='printUserListHeaders;listUsers --noheader --all'
alias listallusers='printUserListHeaders;listUsers --noheader --all'

alias lsallusernames='printUserListHeaders --namefirst;listUsers --namefirst --noheader --all'
alias lsallusersbyname='printUserListHeaders --namefirst;listUsers --namefirst --noheader --all'
alias listallusernames='printUserListHeaders --namefirst;listUsers --namefirst --noheader --all'
alias listallusersbyname='printUserListHeaders --namefirst;listUsers --namefirst --noheader --all'

alias lsgroups='printGroupListHeaders;listGroups --noheader'
alias listgroups='printGroupListHeaders;listGroups --noheader'
alias lsallgroups='printGroupListHeaders;listGroups --noheader --all'
alias listallgroups='printGroupListHeaders;listGroups --noheader --all'

alias lsallgroupnames='printGroupListHeaders --namefirst;listGroups --namefirst --noheader --all'
alias lsallgroupsbyname='printGroupListHeaders --namefirst;listGroups --namefirst --noheader --all'
alias listallgroupnames='printGroupListHeaders --namefirst;listGroups --namefirst --noheader --all'
alias listallgroupsbyname='printGroupListHeaders --namefirst;listGroups --namefirst --noheader --all'

alias docuser='referenceUserCommands'
alias docusers='referenceUserCommands'
alias docgroup='referenceGroupCommands'
alias docgroups='referenceGroupCommands'

alias helpgroup='referenceGroupCommands'
alias helpgroups='referenceGroupCommands'
alias helpuser='referenceUserCommands'
alias helpusers='referenceUserCommands'

alias refuser='referenceUserCommands'
alias refusers='referenceUserCommands'
alias refgroup='referenceGroupCommands'
alias refgroups='referenceGroupCommands'

alias userdoc='referenceUserCommands'
alias usersdoc='referenceUserCommands'
alias groupdoc='referenceGroupCommands'
alias groupsdoc='referenceGroupCommands'

alias userhelp='referenceUserCommands'
alias usershelp='referenceUserCommands'
alias grouphelp='referenceGroupCommands'
alias groupshelp='referenceGroupCommands'

alias userref='referenceUserCommands'
alias usersref='referenceUserCommands'
alias groupref='referenceGroupCommands'
alias groupsref='referenceGroupCommands'

alias permref='referencePermissions'
alias permsref='referencePermissions'
alias refperm='referencePermissions'
alias refperms='referencePermissions'
alias octal='referenceOctalPermissions --abbrev'
alias octalref='referenceOctalPermissions'

alias selinxref='referenceSELinux'
alias selinuxref='referenceSELinux'
alias refselinux='referenceSELinux'
alias refselinx='referenceSELinux'

alias dockerref='referenceDocker'
alias refdocker='referenceDocker'

alias dfusb='displayNonFstabDiskMountpoints'
alias showusb='displayNonFstabDiskMountpoints'

alias isuefi='checkBIOSType'
alias isbios='checkBIOSType'
alias biostype='checkBIOSType'

# quick backups
alias bak='makeBackupWithDateOnly'
alias bakhh='makeBackupWithReadableTimestamp'
alias bakhm='makeBackupWithReadableTimestamp'
alias bakhms='makeBackupWithFullTimestamp'

# browser backups
alias bakff="backupBrowserProfile firefox"
alias ffbak="backupBrowserProfile firefox"

alias bakchr="backupBrowserProfile chromium"
alias bakchromium="backupBrowserProfile chromium"
alias chrbak="backupBrowserProfile chromium"
alias chromiumbak="backupBrowserProfile chromium"

alias bakgc="backupBrowserProfile google-chrome"
alias bakgooglechrome="backupBrowserProfile google-chrome"
alias gcbak="backupBrowserProfile google-chrome"
alias googlechromebak="backupBrowserProfile google-chrome"

alias bakvivaldi="backupBrowserProfile vivaldi"
alias vivaldibak="backupBrowserProfile vivaldi"

alias bravebak="backupBrowserProfile brave"
alias bakbrave="backupBrowserProfile brave"


alias hist='history'
alias histoff="setGnomeTerminalTitle 'Incognito Window' && set +o history"
alias histon="setGnomeTerminalTitle \"$USER@$HOSTNAME:\${PWD//\${HOME//\\//\\\\\\/}/\\~}\" && set -o history"
alias nohist="setGnomeTerminalTitle 'Incognito Window' && set +o history"
alias vihist='vi ~/.bash_history'

#grep history
alias greph="history|grep -Pv 'hgrep|greph|history'|grep -Pi"
alias hgrep="history|grep -Pv 'hgrep|greph|history'|grep -Pi"

# remount any unmounted fstab entries such as drives with noauto
alias mfstab='mountAllFstabEntries'
alias mstab='mountAllFstabEntries'
alias restoremounts='mountAllFstabEntries'
alias restoremnts='mountAllFstabEntries'

alias blkid='sudo blkid'
alias parted='sudo parted --list'
alias fdisk='sudo fdisk --list'

alias diskinfo='printDriveAndPartitionInfo';
alias disks='printDriveAndPartitionInfo';
alias driveinfo='printDriveAndPartitionInfo';
alias drives='printDriveAndPartitionInfo';
alias partitions='printDriveAndPartitionInfo';

alias lsdisk='printDriveAndPartitionInfo';
alias lsdisks='printDriveAndPartitionInfo';
alias lsdrive='printDriveAndPartitionInfo';
alias lsdrives='printDriveAndPartitionInfo';

alias chkwinnames='checkFileNamesValidForWindows';
alias fixwinnames='removeInvalidCharactersFromFileNames';

#====================================================
# Search related commands
#====================================================
#grep aliases
alias grepa='alias|grep -Pi'
alias agrep='alias|grep -Pi'

alias anamegrep="alias|cut -d= -f1|cut -d' ' -f2|grep -Pi"
alias angrep="alias|cut -d= -f1|cut -d' ' -f2|grep -Pi"

CUSTOM_BASH_USER_FUNCTIONS="$HOME/.bash_functions $HOME/.bash_private $HOME/GAME_VARS";

alias grepfn="for f in $CUSTOM_BASH_USER_FUNCTIONS; do grep -P '^\\s*function\\s' "\$f" 2>/dev/null|sed -E 's/^\\s*function\\s+(\\w+)\\W.*\$/\1/g'; done|sort|grep -Pi"
alias fngrep="for f in $CUSTOM_BASH_USER_FUNCTIONS; do grep -P '^\\s*function\\s' "\$f" 2>/dev/null|sed -E 's/^\\s*function\\s+(\\w+)\\W.*\$/\1/g'; done|sort|grep -Pi"
alias listfunctions="for f in $CUSTOM_BASH_USER_FUNCTIONS; do grep -P '^\\s*function\\s' "\$f" 2>/dev/null|sed -E 's/^\\s*function\\s+(\\w+)\\W.*\$/\1/g'; done|sort|grep -Pi"
alias listfunc="for f in $CUSTOM_BASH_USER_FUNCTIONS; do grep -P '^\\s*function\\s' "\$f" 2>/dev/null|sed -E 's/^\\s*function\\s+(\\w+)\\W.*\$/\1/g'; done|sort|grep -Pi"

unset CUSTOM_BASH_USER_FUNCTIONS

alias displayfunction='declare -f'
alias displayfn='declare -f'
alias functionsource='declare -f'
alias fnsource='declare -f'
alias fnsrc='declare -f'
alias showfunction='declare -f'
alias showfn='declare -f'

#grep dirs
alias grepd='LC_ALL=c ls -qAhclp1 --group-directories-first | grep -P -i -e '
alias dgrep='LC_ALL=c ls -qAhclp1 --group-directories-first | grep -P -i -e '

alias f='find . -not -iwholename "*.git/*" '

#The -L follows symlinks
alias ff='findLinkedFilesIgnoringStdErr'
alias fd='findLinkedDirsIgnoringStdErr'
alias ff.='findUnlinkedFilesIgnoringStdErr'
alias fd.='findUnlinkedDirsIgnoringStdErr'

# empty stuff
alias fe='find . -type d -empty'

# find by file type
alias fmp4="find . -type f -iname '*.mp4' ";
alias fmkv="find . -type f -iname '*.mkv' ";
alias ftxt="find . -type f -iname '*.txt' ";
alias fnfo="find . -type f -iname '*.nfo' ";
alias fexe="find . -type f -iname '*.exe' ";
alias fvid="find . -type f \( -iname '*.avi' -o  -iname '*.flv' -o  -iname '*.m[4kpo][4gv]' -o -iname '*.mpeg' -o -iname '*.ogm' -o -iname '*.wmv' \) ";
alias faud="find . -type f \( -iname '*.flac' -o  -iname '*.m[4p][3ab]' -o -iname '*.ogg' -o -iname '*.wav' -o -iname '*.wma' \) ";

#The -L follows symlinks
alias findf='findLinkedFilesIgnoringStdErr'
alias findd='findLinkedDirsIgnoringStdErr'

alias findfile='findLinkedFilesIgnoringStdErr'
alias finddir='findLinkedDirsIgnoringStdErr'

alias findf.='findUnlinkedFilesIgnoringStdErr'
alias findd.='findUnlinkedDirsIgnoringStdErr'

alias findfilenolink='findUnlinkedFilesIgnoringStdErr'
alias finddirnolink='findUnlinkedDirsIgnoringStdErr'

alias dupesinfile='findDuplicateLinesInFile'

# find and remove
alias rmemp="find . -type d -empty -delete";
alias rmempty="find . -type d -empty -delete";
alias rmtxt="find . -type f -iname '*.txt' -delete";
alias rmnfo="find . -type f -iname '*.nfo' -delete";
alias rmexe="find . -type f -iname '*.exe' -delete";

# add placeholders to empty folders
alias fillemp='find . -type d -empty -exec touch "{}/.placeholder" \;';
alias fillemp-md='find . -type d -empty -exec touch "{}/README.md" \;';
alias fillemp-pl='find . -type d -empty -exec touch "{}/.placeholder" \;';
alias fillemp-txt='find . -type d -empty -exec touch "{}/notes.txt" \;';

#====================================================
# Config related commands
#====================================================
alias cgrep='gsettings list-recursively | grep -i ';
alias fconf='gsettings list-recursively | grep -i ';
alias grepc='gsettings list-recursively | grep -i ';
alias grepconf='gsettings list-recursively | grep -i ';
alias fsetting='gsettings list-recursively | grep -i ';
alias fsettings='gsettings list-recursively | grep -i ';
alias lsconf='gsettings list-recursively';
alias lssettings='gsettings list-recursively';
alias printdconf='dconf dump /';
alias printgsettings='gsettings list-recursively';
alias printsettings='gsettings list-recursively';

alias before='gsettings list-recursively | tee /tmp/gsettings-snapshot-before.txt'
alias after='gsettings list-recursively | tee /tmp/gsettings-snapshot-after.txt'
alias snapshot='APPEND_TIMESTAMP=$(/bin/date +"%Y.%m.%d_%H.%M.%S");gsettings list-recursively | tee "/tmp/gsettings-snapshot-${APPEND_TIMESTAMP}".txt'
alias diffsettings='diff /tmp/gsettings-snapshot-before.txt /tmp/gsettings-snapshot-after.txt'

#====================================================
# System Info related commands
#====================================================

# hardware specs only
alias pcspecs='inxi -F;';
alias specs='inxi -F;';

# os info + sys specs
__pc_info_sep__="==========================================";

alias pcinfo="checkOSVersionInfo -r '$DISTRO_NAME';printf '\n%s\nDetailed System Info:\n%s\n%s\n' \"\${__pc_info_sep__}\" \"\${__pc_info_sep__}\" \"\$(inxi -F)\";";

alias sysinfo="checkOSVersionInfo -r '$DISTRO_NAME';printf '\n%s\nDetailed System Info:\n%s\n%s\n' \"\${__pc_info_sep__}\" \"\${__pc_info_sep__}\" \"\$(inxi -F)\";";

if [[ 'fedora' == "${BASE_DISTRO}" ]]; then
	alias fedorainfo='checkOSVersionInfo fedora';
	alias fedoraversion='checkOSVersionInfo fedora';
	alias whichfedora='checkOSVersionInfo fedora';

elif [[ 'debian' == "${BASE_DISTRO}" ]]; then
	#os info only
	alias osinfo="checkOSVersionInfo -r '$DISTRO_NAME'";
	alias osversion="checkOSVersionInfo -r '$DISTRO_NAME'";
	alias version="checkOSVersionInfo -r '$DISTRO_NAME'";

	alias mintinfo='checkOSVersionInfo mint';
	alias mintversion='checkOSVersionInfo mint';
	alias whichmint='checkOSVersionInfo mint';

	if [[ 'ubuntu' == "$DISTRO_NAME" || 'mint' == "$DISTRO_NAME" ]]; then
		alias ubuntuinfo='checkOSVersionInfo ubuntu';
		alias ubuntuversion='checkOSVersionInfo ubuntu';
		alias whichubuntu='checkOSVersionInfo ubuntu';
	fi

	alias debianinfo='checkOSVersionInfo debian';
	alias debianversion='checkOSVersionInfo debian';
	alias whichdebian='checkOSVersionInfo debian';
fi

alias batt='printBatteryPercentages'
alias battery='printBatteryPercentages'

#====================================================
# Permission/ACL related commands
#====================================================
alias gimme="makeDirMineRecursively"
alias mine="makeDirMineRecursively"
alias mkmine="makeDirMineRecursively"
alias mineonly="makeDirOnlyMineRecursively"
alias onlymine="makeDirOnlyMineRecursively"

alias 400="sudo chmod -R 400"
alias 440="sudo chmod -R 440"
alias 500="sudo chmod -R 500"
alias 550="sudo chmod -R 550"
alias 600="sudo chmod -R 600"
alias 660="sudo chmod -R 660"
alias 700="sudo chmod -R 700"
alias 750="sudo chmod -R 750"
alias 760="sudo chmod -R 760"
alias 770="sudo chmod -R 770"
alias 777="sudo chmod -R 777"

alias u+r="sudo chmod -R u+r"
alias u+w="sudo chmod -R u+w"
alias u+x="sudo chmod -R u+x"
alias u+rw="sudo chmod -R u+rw"
alias u+rx="sudo chmod -R u+rx"
alias u+wr="sudo chmod -R u+wr"
alias u+wx="sudo chmod -R u+wx"
alias u+xr="sudo chmod -R u+xr"
alias u+xw="sudo chmod -R u+xw"

alias g+r="sudo chmod -R g+r"
alias g+w="sudo chmod -R g+w"
alias g+x="sudo chmod -R g+x"
alias g+rw="sudo chmod -R g+rw"
alias g+rx="sudo chmod -R g+rx"
alias g+wr="sudo chmod -R g+wr"
alias g+wx="sudo chmod -R g+wx"
alias g+xr="sudo chmod -R g+xr"
alias g+xw="sudo chmod -R g+xw"

#====================================================
# Hex/Binary/Octal commands
#====================================================
alias blobstring="getStringBlobFromBinary"
alias stringblob="getStringBlobFromBinary"
alias hexstr="getHexBlobWithSingleByteSpacing"
alias hexstring="getHexBlobWithSingleByteSpacing"
alias rawhex="getHexBlobWithNoSpacing"
alias hexblob="getHexBlobWithNoSpacing"
alias lshex='echo "cli: hexdump od xxd; gui: bless"'

alias md5='md5sum'
alias sha1='sha1sum'
alias s256='sha256sum'
alias sha256='sha256sum'
alias s512='sha512sum'
alias sha512='sha512sum'


#====================================================
# Package related commands
#====================================================
alias refpkg='referencePackageManagement'
alias refpkgs='referencePackageManagement'
alias pkgref='referencePackageManagement'
alias pkgsref='referencePackageManagement'

if [[ 'fedora' == "${BASE_DISTRO}" ]]; then
	alias dnfref='referencePackageManagement'
	alias refdnf='referencePackageManagement'

	# https://dnf.readthedocs.io/en/latest/command_ref.html
	#
	alias dnfgrep='dnf search --nogpgcheck --cacheonly --assumeno --quiet'
	alias dsearch='dnf search --nogpgcheck --cacheonly --assumeno --quiet'
	alias dnf-search='dnf search --cacheonly --assumeno --quiet'
	alias dnfs='dnf search --nogpgcheck --cacheonly --assumeno --quiet'
	alias dnfrs='dnf raw-search --nogpgcheck --quiet'
	alias dnfsearch='dnf search --nogpgcheck --cacheonly --assumeno --quiet'
	alias pkggrep='dnf search --nogpgcheck --cacheonly --assumeno --quiet'
	alias dnfl='dnf list --nogpgcheck --cacheonly --assumeno --quiet'
	alias dnfls='dnf list --nogpgcheck --cacheonly --assumeno --quiet'
	alias dnfla='dnf list available --nogpgcheck --cacheonly --assumeno --quiet'
	alias dnfli='dnf list installed --nogpgcheck --cacheonly --assumeno --quiet'
	alias dnfdep='dnf repoquery --deplist --nogpgcheck --cacheonly --assumeno --quiet'
	alias dnfdepcheck='dnf repoquery --deplist --nogpgcheck --cacheonly --assumeno --quiet'
	alias dnfdeplist='dnf repoquery --deplist --nogpgcheck --cacheonly --assumeno --quiet'
	alias dnfprovides='dnf provides --nogpgcheck --assumeno --quiet'

	alias pkgs='dnf search --nogpgcheck --cacheonly --assumeno --quiet'
	alias pkggrep='dnf search --nogpgcheck --cacheonly --assumeno --quiet'

	alias provides='dnf provides --nogpgcheck --assumeno --quiet'

	alias fixdnf='sudo ls -acl 2>/dev/null >/dev/null; fixSystemPermissions --dnf';

	#Unfortunately, bash complains about alias names starting with hyphens so no using '--' as an alias ...
	alias ++='sudo dnf install'
	alias +++='sudo dnf install -y'
	alias ++y='sudo dnf install -y'

	alias apt='aptToDnfWrapper'
	alias apt-get='aptToDnfWrapper'

elif [[ 'debian' == "${BASE_DISTRO}" ]]; then
	alias aptref='referencePackageManagement'
	alias dpkgref='referencePackageManagement'
	alias refapt='referencePackageManagement'
	alias refdpkg='referencePackageManagement'

	alias asearch='apt search'
	alias aptgrep='apt search'
	alias apts='apt search'
	alias apt-search='apt search'
	alias aptsearch='apt search'
	alias pkgs='apt search'
	alias pkggrep='apt search'

	#Unfortunately, bash complains about alias names starting with hyphens so no using '--' as an alias ...
	alias ++='sudo apt install'
	alias +++='sudo apt install -y'
	alias ++y='sudo apt install -y'

	alias viewoptpkgs='apt-cache depends --no-pre-depends --no-depends --no-conflicts --no-breaks --no-replaces --no-enhances'
	alias viewrecommends='apt-cache depends --no-pre-depends --no-depends --no-conflicts --no-breaks --no-replaces --no-enhances --no-suggests'
	alias viewsuggests='apt-cache depends --no-pre-depends --no-depends --no-conflicts --no-breaks --no-replaces --no-enhances --no-recommends'

	#alias isinstalled='dpkg -l'
	alias isinstall='apt list package'
	alias isappinstalled='apt list package'

	#alias ispackageinstalled='dpkg -l'
	alias ispackageinstalled='apt list package'
	#alias doihave='dpkg -l'
	alias doihave='apt list package'

	alias dnf='dnfToAptWrapper'
fi

alias appsize="previewPackageDownloadSize"
alias pkgsize="previewPackageDownloadSize"

alias upgradepreview="previewUpgradablePackagesDownloadSize";
alias previewupgrade="previewUpgradablePackagesDownloadSize";
alias upgradesize="previewUpgradablePackagesDownloadSize";

alias aptchk='isPackageInstalled'
alias chkapt='isPackageInstalled'
alias chkpkg='isPackageInstalled'
alias pkgchk='isPackageInstalled'

# find what package a binary is from (e.g. /usr/bin/7z => p7zip-full)
alias whichpkg='whichPackage'

# bc i cant type for shite...
alias whickpkg='whichPackage'

# find out what version of a package is installed or is available
alias pkgversion='whichPackageVersion'
alias whichpkgversion='whichPackageVersion'
alias whichversion='whichPackageVersion'

# bc i cant type for shite...
alias whickversion='whichPackageVersion'

# similar to $(realpath $(which NAME)) but with better error handling
alias realbin='whichRealBinary'
alias whichbin='whichRealBinary'
alias whichreal='whichRealBinary'

# find out which binaries are in a package (e.g. p7zip-full => /usr/bin/7z)
alias listbin='whichBinariesInPackage'
alias listbins='whichBinariesInPackage'
alias listcmds='whichBinariesInPackage'
alias listutils='whichBinariesInPackage'

alias pkglistbin='whichBinariesInPackage'
alias pkglsbin='whichBinariesInPackage'
alias pkgbin='whichBinariesInPackage'

# list all files in a package
alias listall='whichFilesInPackage'
alias listfiles='whichFilesInPackage'
alias listinpkg='whichFilesInPackage'
alias listpkgfiles='whichFilesInPackage'

alias pkgfiles='whichFilesInPackage'
alias pkglist='whichFilesInPackage'
alias pkgls='whichFilesInPackage'

# display the glibc version
alias glibc="ldd --version|grep -Pi 'G.*LIBC'"

#====================================================
# Process and Service related commands
#====================================================
alias plist='echo "use ps aux" or "pgrep" or alias "pg"'
alias tasklist='echo "use ps aux or ps -ef or pgrep" or alias "pg"'
alias taskkill='echo "use kill -9 processname*" or "pkill -9 processname" or alias "pk"'
alias taskill='echo "use kill -9 processname*" or "pkill -9 processname" or alias "pk"'

alias killspot='killall -9 spotify';

alias pskill='pkill --signal 9 --full --ignore-case'
alias pslist='pgrep --list-full --full --ignore-case'
alias psgrep='pgrep --list-full --full --ignore-case'

alias pk='pkill --signal 9 --full --ignore-case'
alias p9='pkill --signal 9 --full --ignore-case'
alias pg='pgrep --list-full --full --ignore-case'

#override pgrep to automatically list all without having to specify args
alias pgrep='pgrep --list-full'

alias stop='stopSystemdServices'
alias stopsvc='stopSystemdServices'
alias stopservice='stopSystemdServices'

alias disable='stopAndDisableSystemdServices'
alias disablesvc='stopAndDisableSystemdServices'
alias disableservice='stopAndDisableSystemdServices'

alias enable='enableSystemdServices'
alias enablesvc='enableSystemdServices'
alias enableservic='enableSystemdServices'

alias restart='restartSystemdServices'
alias restartd='restartSystemdServices'
alias restartsvc='restartSystemdServices'
alias restartservice='restartSystemdServices'

alias restore='enableAndRestartSystemdServices'
alias restoresvc='enableAndRestartSystemdServices'
alias restoreservice='enableAndRestartSystemdServices'

# note: this overrides default atq and uses the function instead (use full path of /usr/bin/atq for non-function call)
alias atq='printAtQueue'
alias lsat='printAtQueue'
alias atmv='rescheduleAtJob'
alias atadd='addMinutesToAtJob'

alias timer='echo "Starting timer. Press Ctrl+C to exit.";date1=$(date +%s); while true; do printf "%s\r" "$(date -u --date @$(($(date +%s) - $date1)) +%H:%M:%S)"; sleep 1; done'
alias count='echo "Starting timer. Press Ctrl+C to exit.";date1=$(date +%s); while true; do printf "%s\r" "$(date -u --date @$(($(date +%s) - $date1)) +%H:%M:%S)"; sleep 1; done'
alias stopwatch='echo "Starting timer. Press Ctrl+C to exit.";date1=$(date +%s); while true; do printf "%s\r" "$(date -u --date @$(($(date +%s) - $date1)) +%H:%M:%S)"; sleep 1; done'

#====================================================
# X-Window related commands
#====================================================
#interactive (changes cursor and waits for user to click)
alias ifind='ps -o pid,comm,start,etime,pcpu,pmem,size,args -p $(echo $(PIDSTR=$(xprop _NET_WM_PID); echo "$PIDSTR" | sed "s/^.*[^0-9]\([0-9][0-9]*\)[^0-9]*$/\1/g"))'
alias ikill='xkill'
alias findx='ps -o pid,comm,start,etime,pcpu,pmem,size,args -p $(echo $(PIDSTR=$(xprop _NET_WM_PID); echo "$PIDSTR" | sed "s/^.*[^0-9]\([0-9][0-9]*\)[^0-9]*$/\1/g"))'
alias killx='xkill'
alias pofwindow='ps -o pid,comm,start,etime,pcpu,pmem,size,args -p $(echo $(PIDSTR=$(xprop _NET_WM_PID); echo "$PIDSTR" | sed "s/^.*[^0-9]\([0-9][0-9]*\)[^0-9]*$/\1/g"))'
alias pofx='ps -o pid,comm,start,etime,pcpu,pmem,size,args -p $(echo $(PIDSTR=$(xprop _NET_WM_PID); echo "$PIDSTR" | sed "s/^.*[^0-9]\([0-9][0-9]*\)[^0-9]*$/\1/g"))'
alias xfind='ps -o pid,comm,start,etime,pcpu,pmem,size,args -p $(echo $(PIDSTR=$(xprop _NET_WM_PID); echo "$PIDSTR" | sed "s/^.*[^0-9]\([0-9][0-9]*\)[^0-9]*$/\1/g"))'

#other options/tools for getting x windows info:
#	xwininfo
#	xprop
#	xdotool selectwindow getwindowpid
#	xdotool getactivewindow
#	xdotool getwindowpid <the-window-id>

#by name
alias getwindowpid='getProcessIdByWindowName'
alias getwindowproc='getProcessInfoByWindowName'
alias pofw='getProcessInfoByWindowName'
alias pofwinname='getProcessInfoByWindowName'
#also see /bin/pidof
alias pidofwinname='getProcessIdByWindowName'

# bring a window from some other workspace to current workspace
alias movewindowhere='moveWindowToCurrentWorkspace'
alias mvwindowhere='moveWindowToCurrentWorkspace'
alias xmovehere='moveWindowToCurrentWorkspace'
alias xmvhere='moveWindowToCurrentWorkspace'

# bring a window from one workspace to another workspace
alias movewindowtoworkspace='moveWindowToWorkspace'
alias movetoworkspace='moveWindowToWorkspace'
alias mvwindowtoworkspace='moveWindowToWorkspace'
alias mvtoworkspace='moveWindowToWorkspace'
alias xmovetoworkspace='moveWindowToWorkspace'
alias xmvtoworkspace='moveWindowToWorkspace'

alias getkeycode='xev -event keyboard 2>&1 | grep -i -P "keycode [a-f0-9]+ \([^\)]+\)" -B 2 -A 3'
alias keycode='xev -event keyboard 2>&1 | grep -i -P "keycode [a-f0-9]+ \([^\)]+\)" -B 2 -A 3'

# xrandr
alias xleft='xrandr --orientation left'
alias xright='xrandr --orientation right'
alias xnormal='xrandr --orientation normal'
alias xreset='xrandr --orientation normal'
alias xtop='xrandr --orientation normal'
alias xbottom='xrandr --orientation inverted'
alias xinvert='xrandr --orientation inverted'
alias xupsidedown='xrandr --orientation inverted'

#====================================================
# Audio/Sound related commands
#====================================================
alias aslamixer='echo -e "\nCorrecting to ALSAmixer...\n";alsamixer'
alias pavcontrol='echo -e "\nCorrecting to pavUcontrol...\n";pavucontrol'

alias am='alsamixer'
alias pav='pavucontrol'

alias fixsound='unmuteAllAlsaAudioControls';
alias fixvol='unmuteAllAlsaAudioControls';
alias fixvolume='unmuteAllAlsaAudioControls';

#====================================================
# Wine related commands
#====================================================
alias mkwine32='createNewWine32Prefix'
alias mkwine32pfx='createNewWine32Prefix'
alias mkwinepfx32='createNewWine32Prefix'
alias mkwine64='createNewWine64Prefix'
alias mkwine64pfx='createNewWine64Prefix'
alias mkwinepfx64='createNewWine64Prefix'

alias winebase='goToWinePrefix'
alias winetop='goToWinePrefix'
alias winepfx='goToWinePrefix'
alias pfx='goToWinePrefix'
alias cdpfx='goToWinePrefix'
alias uppfx='goToWinePrefix'
alias pfxbase='goToWinePrefix'
alias pfxtop='goToWinePrefix'

alias wineconf='wineConfigHere'
alias wineconfig='wineConfigHere'
alias winecmd='wineCmdHere'
alias winereg='wineRegeditHere'

# aliases for removing wine prefix symlinks to real linux user's home folder/sub-folders
alias fixwineuser='wineSandboxUserDir'
alias fixwineusers='wineSandboxUserDir'
alias winefixuser='wineSandboxUserDir'
alias winefixusers='wineSandboxUserDir'
alias wineusersandbox='wineSandboxUserDir'
alias winesandboxuser='wineSandboxUserDir'
alias wineunlinkuser='wineSandboxUserDir'
alias wineunlinkusers='wineSandboxUserDir'

alias winesandbox='wineSandboxUserDir;wineRemoveRootDriveSymlink;'
alias sandboxwine='wineSandboxUserDir;wineRemoveRootDriveSymlink;'

alias cmd='wineCmdHere'
alias wcmd='wineCmdHere'
alias reg='wineRegeditHere'
alias wreg='wineRegeditHere'
alias wconf='wineConfigHere'

alias wt='winetricksHere'

alias printpfx='printWinePrefix'
alias whichpfx='printWinePrefix'
alias lspfx='printWinePrefix'
alias pwdpfx='printWinePrefix'
alias pfxpwd='printWinePrefix'
alias ppfx='printWinePrefix'

alias listprotongames="protontricks -s '*'|grep -P '[()]'"
alias protongames="protontricks -s '*'|grep -P '[()]'"

# extract ico file from exe
# note: wrestool is provided by the icoutils package on fedora
#
# this is useful for creating GNOME/freedesktop accessible icons
# from  windows exes when steam fucks up and creates shortcuts with generic icons
# afterward getting the ico file, use imagemagick 'convert' to convert from
# ico to png (if multiple pngs, pick whichever resolution you want and delete the rest)
# then copy the final png to appropriate resolution folder under local hicolor theme
# e.g.:
#	extractIcon Portia.exe
#	prename 's/\.exe.*(\.ico|png)/$1/g' *.ico
#	-> creates 'Portia.exe_14_103.ico' which I renamed as 'Portia.ico'
#
#	convert Portia.ico portia.png
#	-> creates 9 different png files of various resolutions. going by filesize and
#	-> resolution displayed on status bar when I open in eye of Mate (eom)
#	-> I keep the 256x256 image and delete the others. then rename final image to portia.png
#
#	mkdir -p ~/.local/share/icons/hicolor/256x256/apps
#	cp -a -t ~/.local/share/icons/hicolor/256x256/apps portia.png
#
alias extractIco="wrestool --extract --output=. --type=14"
alias extractIcon="wrestool --extract --output=. --type=14"

#====================================================
# Display related commands
#====================================================
alias resetgamma='xgamma -gamma 1.0';
alias gam0='xgamma -gamma 1.0';
alias fixgam='xgamma -gamma 1.0';
alias gam++="xgamma -gamma \$(xgamma 2>& 1 | perl -pe 's/^\\D*(\\d+\\.\\d+)\\D.*\$/\"\" . (\$1 + 0.1)/ge')";
alias gam--="xgamma -gamma \$(xgamma 2>& 1 | perl -pe 's/^\\D*(\\d+\\.\\d+)\\D.*\$/\"\" . (\$1 - 0.1)/ge')";
alias lighten="xgamma -gamma \$(xgamma 2>& 1 | perl -pe 's/^\\D*(\\d+\\.\\d+)\\D.*\$/\"\" . (\$1 + 0.1)/ge')";
alias lighter="xgamma -gamma \$(xgamma 2>& 1 | perl -pe 's/^\\D*(\\d+\\.\\d+)\\D.*\$/\"\" . (\$1 + 0.1)/ge')";
alias darken="xgamma -gamma \$(xgamma 2>& 1 | perl -pe 's/^\\D*(\\d+\\.\\d+)\\D.*\$/\"\" . (\$1 - 0.1)/ge')";
alias darker="xgamma -gamma \$(xgamma 2>& 1 | perl -pe 's/^\\D*(\\d+\\.\\d+)\\D.*\$/\"\" . (\$1 - 0.1)/ge')";
alias toodark='xgamma -gamma 1.2';
alias toodark2='xgamma -gamma 1.4';
alias toolight='xgamma -gamma 0.8';
alias toolight2='xgamma -gamma 0.6';
alias gam09='xgamma -gamma 0.9';
alias gam08='xgamma -gamma 0.8';
alias gam07='xgamma -gamma 0.7';
alias gam06='xgamma -gamma 0.6';
alias gam05='xgamma -gamma 0.5';
alias gam04='xgamma -gamma 0.4';
alias gam03='xgamma -gamma 0.3';
alias gam02='xgamma -gamma 0.2';
alias gam01='xgamma -gamma 0.1';
alias gam10='xgamma -gamma 1.0';
alias gam11='xgamma -gamma 1.1';
alias gam12='xgamma -gamma 1.2';
alias gam13='xgamma -gamma 1.3';
alias gam14='xgamma -gamma 1.4';
alias gam15='xgamma -gamma 1.5';
alias gam16='xgamma -gamma 1.6';
alias gam17='xgamma -gamma 1.7';
alias gam18='xgamma -gamma 1.8';
alias gam19='xgamma -gamma 1.9';
alias gam20='xgamma -gamma 2.0';
alias gam21='xgamma -gamma 2.1';
alias gam22='xgamma -gamma 2.2';
alias gam23='xgamma -gamma 2.3';
alias gam24='xgamma -gamma 2.4';
alias gam25='xgamma -gamma 2.5';
alias gam26='xgamma -gamma 2.6';
alias gam27='xgamma -gamma 2.7';
alias gam28='xgamma -gamma 2.8';
alias gam29='xgamma -gamma 2.9';

#====================================================
# Archive related commands
#====================================================
alias 7zdir="create7zArchive";
alias zipdir="createTarXzArchive";
alias xzdir="createTarXzArchive";
alias xdzir="createTarXzArchive";
alias gzdir="createTarGzArchive";
alias tardir='echo "dirname=\"foo\";";echo "tar -czf \"\${dirname}.tar.gz\" \"\${dirname}\";";'
alias untar='extractTarArchive';

#====================================================
# Network related commands
#====================================================
alias ipaddr="ip -4 -o -br addr|grep -P '^[we]\\w+\\s+UP\\b'|gawk '{print \$3}'|cut -d/ -f1"
alias showip="ip -4 -o -br addr|grep -P '^[we]\\w+\\s+UP\\b'|gawk '{print \$3}'|cut -d/ -f1"
alias myip="ip -4 -o -br addr|grep -P '^[we]\\w+\\s+UP\\b'|gawk '{print \$3}'|cut -d/ -f1"

alias iname="ip -4 -o -br addr|grep -P '^[we]\\w+\\s+UP\\b'|gawk '{print \$1}'"
alias interface="ip -4 -o -br addr|grep -P '^[we]\\w+\\s+UP\\b'|gawk '{print \$1}'"
alias interfacename="ip -4 -o -br addr|grep -P '^[we]\\w+\\s+UP\\b'|gawk '{print \$1}'"

alias routerip="ip route show | grep -i 'default via'| awk '{print \$3 }'"
alias rtrip="ip route show | grep -i 'default via'| awk '{print \$3 }'"
alias defaultgateway="ip route show | grep -i 'default via'| awk '{print \$3 }'"
alias defgateway="ip route show | grep -i 'default via'| awk '{print \$3 }'"
alias gateway="ip route show | grep -i 'default via'| awk '{print \$3 }'"
alias gatewayip="ip route show | grep -i 'default via'| awk '{print \$3 }'"

alias wanip='curl https://ipinfo.io/ip'
alias whatsmyip='curl https://ipinfo.io/ip'
alias publicip='curl https://ipinfo.io/ip'
alias pubip='curl https://ipinfo.io/ip'

alias mac="ip -o -br link|grep -P '^[we]\w+\s+UP\b'|gawk '{print \$3}'|cut -d/ -f1"
alias macaddr="ip -o -br link|grep -P '^[we]\w+\s+UP\b'|gawk '{print \$3}'|cut -d/ -f1"
alias showmac="ip -o -br link|grep -P '^[we]\w+\s+UP\b'|gawk '{print \$3}'|cut -d/ -f1"
alias mymac="ip -o -br link|grep -P '^[we]\w+\s+UP\b'|gawk '{print \$3}'|cut -d/ -f1"

alias ifconfig="echo 'ifconfig is deprecated. try ip addr (ip addr), ip link (mac addr), ip route (gateway addr), ip -4 -o -br addr (active interfaces), or ip neighbour (lan addrs).';echo '-----------------';/usr/sbin/ifconfig"

alias netscan='scanAllOnLocalNetworks'
alias lanscan='scanAllOnLocalNetwork'
alias netscan='scanAllOnLocalNetwork'
alias scanlan='scanAllOnLocalNetwork'
alias scannet='scanAllOnLocalNetwork'

alias smbscan='scanPortOnLocalNetwork 137-139,445'
alias scansmb='scanPortOnLocalNetwork 137-139,445'

alias netview='displayNetworkHostnames'

alias nettype='printNetworkType'
alias connection='printNetworkType'
alias onvpn='printNetworkType'
alias vpn='printNetworkType'
alias isvpn='printNetworkType'

if [[ 'fedora' == "${BASE_DISTRO}" ]]; then
	# in fedora, the service names are 'smb' and 'nmb' instead of 'smbd' and 'nmbd' used in debian-based distros
	alias stopsmb='sudo systemctl stop smb; sudo systemctl stop nmb;'
	alias startsmb='sudo systemctl start smb; sudo systemctl start nmb;'
	alias restartsmb='sudo systemctl restart smb; sudo systemctl restart nmb;'

	alias stopsamba='sudo systemctl stop smb; sudo systemctl stop nmb;'
	alias startsamba='sudo systemctl start smb; sudo systemctl start nmb;'
	alias restartsamba='sudo systemctl restart smb; sudo systemctl restart nmb;'

	alias fwoff='sudo systemctl stop firewalld;'
	alias fwon='sudo systemctl start firewalld;'
	alias fwstat="sudo firewall-cmd --list-all"

elif [[ 'debian' == "${BASE_DISTRO}" ]]; then
	alias stopsmb='sudo systemctl stop smbd; sudo systemctl stop nmbd;'
	alias startsmb='sudo systemctl start smbd; sudo systemctl start nmbd;'
	alias restartsmb='sudo systemctl restart smbd; sudo systemctl restart nmbd;'

	alias stopsamba='sudo systemctl stop smbd; sudo systemctl stop nmbd;'
	alias startsamba='sudo systemctl start smbd; sudo systemctl start nmbd;'
	alias restartsamba='sudo systemctl restart smbd; sudo systemctl restart nmbd;'

	alias fwoff='sudo ufw disable'
	alias fwon='sudo ufw enable'
	alias fwstat='sudo ufw status numbered'

	alias ufwoff='sudo ufw disable'
	alias ufwon='sudo ufw enable'
	alias ufwstat='sudo ufw status numbered'
fi


#====================================================
# Shell and terminal related commands
#====================================================
alias edit="openFileInTextEditor";
alias nemo="openNemo";

# edit aliases
alias via="vi ~/.bash_aliases"
alias vial="vi ~/.bash_aliases"
alias vialias="vi ~/.bash_aliases"
alias vialiases="vi ~/.bash_aliases"
alias editalias="openFileInTextEditor ${HOME}/.bash_aliases"

# reload aliases
alias aliasrefresh="source ~/.bash_aliases"
alias aliasreload="source ~/.bash_aliases"
alias aliasreset="source ~/.bash_aliases"

alias arefresh="source ~/.bash_aliases"
alias areload="source ~/.bash_aliases"
alias areset="source ~/.bash_aliases"

alias refreshalias="source ~/.bash_aliases"
alias refreshaliases="source ~/.bash_aliases"
alias reloadalias="source ~/.bash_aliases"
alias reloadaliases="source ~/.bash_aliases"
alias resetalias="source ~/.bash_aliases"
alias resetaliases="source ~/.bash_aliases"
alias rlal="source ~/.bash_aliases"
alias rlaliases="source ~/.bash_aliases"

# edit functions
alias vif="vi ${HOME}/.bash_functions"
alias fvi="vi ${HOME}/.bash_functions"
alias vifunc="vi ${HOME}/.bash_functions"
alias editfunc="openFileInTextEditor ${HOME}/.bash_functions"

# reload functions
alias functionrefresh="source ~/.bash_functions"
alias functionreload="source ~/.bash_functions"
alias functionreset="source ~/.bash_functions"

alias frefresh="source ~/.bash_functions"
alias freload="source ~/.bash_functions"
alias freset="source ~/.bash_functions"

alias refreshfunc="source ~/.bash_functions"
alias refreshfunction="source ~/.bash_functions"
alias refreshfunctions="source ~/.bash_functions"
alias reloadfunc="source ~/.bash_functions"
alias reloadfunction="source ~/.bash_functions"
alias reloadfunctions="source ~/.bash_functions"
alias resetfunc="source ~/.bash_functions"
alias resetfunction="source ~/.bash_functions"
alias resetfunctions="source ~/.bash_functions"
alias rlfn="source ~/.bash_functions"
alias rlfunc="source ~/.bash_functions"
alias rlfunctions="source ~/.bash_functions"

# edit run commands (rc) file
alias vir="vi ${HOME}/.bashrc"
alias virc="vi ${HOME}/.bashrc"
alias vibashrc="vi ${HOME}/.bashrc"
alias editrc="openFileInTextEditor ${HOME}/.bashrc"

# reload run commands (rc) file
alias bashrefresh="source ~/.bashrc"
alias bashreload="source ~/.bashrc"
alias bashreset="source ~/.bashrc"

alias rcrefresh="source ~/.bashrc"
alias rcreload="source ~/.bashrc"
alias rcreset="source ~/.bashrc"

alias refreshbash="source ~/.bashrc"
alias refreshrc="source ~/.bashrc"
alias reloadbash="source ~/.bashrc"
alias reloadrc="source ~/.bashrc"
alias resetbash="source ~/.bashrc"
alias resetrc="source ~/.bashrc"
alias rlrc="source ~/.bashrc"

# referenence commands
alias viref='referenceVim'
alias vimref='referenceVim'
alias vihelp='referenceVim'
alias vimhelp='referenceVim'
alias vimrcref='referenceVimRc'
alias vimrchelp='referenceVimRc'

#====================================================
# Multimedia related commands
#====================================================
alias getmkvsubs="getMkvSubtitleTrackInfo";
alias mkvsubs="getMkvSubtitleTrackInfo";
alias rmmkvsubs="removeMkvSubtitleTracksById";

alias logmkvsubs="batchLogMkvSubtitleTrackInfo";
alias logallmkvsubs="batchLogMkvSubtitleTrackInfo";
alias lsmkvsubs="batchLogMkvSubtitleTrackInfo";
alias rmdirmkvsubs="batchRemoveMkvSubtitleTracksById";
alias rmallmkvsubs="batchRemoveMkvSubtitleTracksById";

alias setdirmkvdefaultsubs="batchSetMkvDefaultTrackId";
alias setmkvdefaultsubs="setMkvDefaultTrackId";

alias extractmkvsubs="extractMkvSubtitleTextById";
alias extractdirmkvsubs="batchExtractMkvSubtitleTextById";
alias extractallmkvsubs="batchExtractMkvSubtitleTextById";

alias popmkvsubs="extractMkvSubtitleTextById";
alias popdirmkvsubs="batchExtractMkvSubtitleTextById";
alias popallmkvsubs="batchExtractMkvSubtitleTextById";

alias addmkvsubs="addMkvSubtitleText";
alias adddirmkvsubs="batchAddMkvSubtitleText";
alias addallmkvsubs="batchAddMkvSubtitleText";

alias pushmkvsubs="addMkvSubtitleText";
alias pushdirmkvsubs="batchAddMkvSubtitleText";
alias pushallmkvsubs="batchAddMkvSubtitleText";

alias getmkvaudio="getMkvAudioTrackInfo";
alias mkvaudio="getMkvAudioTrackInfo";

alias 2mp3='extractMp3AudioFromVideoFile'
alias tomp3='extractMp3AudioFromVideoFile'
alias flv2mp3='extractMp3AudioFromVideoFile'
alias flvtomp3='extractMp3AudioFromVideoFile'
alias mp42mp3='extractMp3AudioFromVideoFile'
alias mp4tomp3='extractMp3AudioFromVideoFile'
alias vid2mp3='extractMp3AudioFromVideoFile'
alias vidtomp3='extractMp3AudioFromVideoFile'
alias extractaudio='extractMp3AudioFromVideoFile'
alias extractmp3='extractMp3AudioFromVideoFile'

alias allflvtomp3='extractMp3AudioFromAllFlvInCurrentDir'
alias allmp4tomp3='extractMp3AudioFromAllMp4InCurrentDir'
alias allvidstomp3='extractMp3AudioFromAllVideosInCurrentDir'

alias 2ogg='extractOggAudioFromVideoFile'
alias toogg='extractOggAudioFromVideoFile'
alias mp42ogg='extractOggAudioFromVideoFile'
alias mp4toogg='extractOggAudioFromVideoFile'
alias allmp4toogg='extractOggAudioFromAllMp4InCurrentDir'

alias levelmp3='normalizeAllMp3InCurrentDir'
alias normalmp3='normalizeAllMp3InCurrentDir'
alias normalizemp3='normalizeAllMp3InCurrentDir'

alias levelogg='normalizeAllOggInCurrentDir'
alias normalogg='normalizeAllOggInCurrentDir'
alias normalizeogg='normalizeAllOggInCurrentDir'

alias datauri='imageToBase64DataUri'

alias compdf='compressPdf'
alias p2t='convertPdfToText'
alias p2md='convertPdfToMarkdown'

alias ytdl="youtube-dl -f 'bestvideo[ext=mkv][height <=? 480]+bestaudio/bestvideo[ext=mp4][height <=? 480]+bestaudio/bestvideo+bestaudio/best' -o '%(uploader)s_-_%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats --sub-lang en --embed-subs --add-metadata --xattrs --no-overwrites --postprocessor-args '-metadata copyright=%(url)s' --merge-output-format mkv "
alias ytv="youtube-dl -f 'bestvideo[ext=mkv][height <=? 480]+bestaudio/bestvideo[ext=mp4][height <=? 480]+bestaudio/bestvideo+bestaudio/best' -o '%(uploader)s_-_%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats --sub-lang en --embed-subs --add-metadata --xattrs --no-overwrites --postprocessor-args '-metadata copyright=%(url)s' --merge-output-format mkv "
alias yt="youtube-dl -f 'bestvideo[ext=mkv][height <=? 480]+bestaudio/bestvideo[ext=mp4][height <=? 480]+bestaudio/bestvideo+bestaudio/best' -o '%(uploader)s_-_%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats --sub-lang en --embed-subs --add-metadata --xattrs --no-overwrites --postprocessor-args '-metadata copyright=%(url)s' --merge-output-format mkv "

# download audio track only
alias yta="youtube-dl -f 'bestaudio[ext=mp3]/bestaudio[ext=m4a]/bestaudio[ext=ogg]/bestaudio' -o '%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats --add-metadata --xattrs --no-overwrites --postprocessor-args '-metadata copyright=%(url)s' "
alias ytmp3="youtube-dl -f 'bestaudio[ext=mp3]' -o '%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats --add-metadata --xattrs --no-overwrites --postprocessor-args '-metadata copyright=%(url)s' "

# very low quality (really this is just SD quality so small filesize) video -- great for music videos
alias yvtl="youtube-dl -f 'worst/bestvideo[ext=mkv][height <=? 480]+bestaudio/bestvideo[ext=mp4][height <=? 480]+bestaudio/bestvideo+bestaudio/best' -o '%(uploader)s_-_%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats --sub-lang en --embed-subs --add-metadata --xattrs --no-overwrites --postprocessor-args '-metadata copyright=%(url)s' --merge-output-format mkv "
alias ytvl="youtube-dl -f 'worst/bestvideo[ext=mkv][height <=? 480]+bestaudio/bestvideo[ext=mp4][height <=? 480]+bestaudio/bestvideo+bestaudio/best' -o '%(uploader)s_-_%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats --sub-lang en --embed-subs --add-metadata --xattrs --no-overwrites --postprocessor-args '-metadata copyright=%(url)s' --merge-output-format mkv "
alias ytlv="youtube-dl -f 'worst/bestvideo[ext=mkv][height <=? 480]+bestaudio/bestvideo[ext=mp4][height <=? 480]+bestaudio/bestvideo+bestaudio/best' -o '%(uploader)s_-_%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats --sub-lang en --embed-subs --add-metadata --xattrs --no-overwrites --postprocessor-args '-metadata copyright=%(url)s' --merge-output-format mkv "

# updating youtube-dl
alias ytu="sudo youtube-dl -U";
alias ytupdate="sudo youtube-dl -U";

if [[ 'fedora' == "${BASE_DISTRO}" ]]; then
	# as of dec 2020 / fedora 33, scrot is not available in either fedora default repo or
	# in the rpmfusion free/nonfree repos so maim is recommended to be used as an alternative

	# Note having an 'ss' is too short to be very userful and blocks
	# the network-/socket-related command '/bin/ss'
	alias ss2='maim --delay=2.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss3='maim --delay=3.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss4='maim --delay=4.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss5='maim --delay=5.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss6='maim --delay=6.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss7='maim --delay=7.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss8='maim --delay=8.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss9='maim --delay=9.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss10='maim --delay=10.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss15='maim --delay=15.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss20='maim --delay=20.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss25='maim --delay=25.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss30='maim --delay=30.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss35='maim --delay=35.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss40='maim --delay=40.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss45='maim --delay=45.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss50='maim --delay=50.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss55='maim --delay=55.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss60='maim --delay=60.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';

	alias scrot2='maim --delay=2.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot3='maim --delay=3.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot4='maim --delay=4.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot5='maim --delay=5.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot6='maim --delay=6.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot7='maim --delay=7.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot8='maim --delay=8.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot9='maim --delay=9.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot10='maim --delay=10.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot15='maim --delay=15.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot20='maim --delay=20.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot25='maim --delay=25.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot30='maim --delay=30.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot35='maim --delay=35.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot40='maim --delay=40.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot45='maim --delay=45.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot50='maim --delay=50.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot55='maim --delay=55.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot60='maim --delay=60.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';

	alias maim2='maim --delay=2.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim3='maim --delay=3.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim4='maim --delay=4.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim5='maim --delay=5.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim6='maim --delay=6.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim7='maim --delay=7.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim8='maim --delay=8.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim9='maim --delay=9.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim10='maim --delay=10.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim15='maim --delay=15.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim20='maim --delay=20.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim25='maim --delay=25.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim30='maim --delay=30.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim35='maim --delay=35.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim40='maim --delay=40.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim45='maim --delay=45.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim50='maim --delay=50.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim55='maim --delay=55.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias maim60='maim --delay=60.0 --quality 4 ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';

elif [[ 'debian' == "${BASE_DISTRO}" ]]; then
	# Note having an 'ss' is too short to be very userful and blocks
	# the network-/socket-related command '/bin/ss'
	alias ss2='scrot --delay 2 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss3='scrot --delay 3 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss4='scrot --delay 4 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss5='scrot --delay 5 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss6='scrot --delay 6 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss7='scrot --delay 7 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss8='scrot --delay 8 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss9='scrot --delay 9 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss10='scrot --delay 10 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss15='scrot --delay 15 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss20='scrot --delay 20 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss25='scrot --delay 25 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss30='scrot --delay 30 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss35='scrot --delay 35 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss40='scrot --delay 40 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss45='scrot --delay 45 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss50='scrot --delay 50 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss55='scrot --delay 55 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias ss60='scrot --delay 60 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';

	alias scrot2='scrot --delay 2 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot3='scrot --delay 3 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot4='scrot --delay 4 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot5='scrot --delay 5 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot6='scrot --delay 6 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot7='scrot --delay 7 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot8='scrot --delay 8 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot9='scrot --delay 9 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot10='scrot --delay 10 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot15='scrot --delay 15 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot20='scrot --delay 20 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot25='scrot --delay 25 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot30='scrot --delay 30 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot35='scrot --delay 35 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot40='scrot --delay 40 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot45='scrot --delay 45 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot50='scrot --delay 50 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot55='scrot --delay 55 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
	alias scrot60='scrot --delay 60 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
fi

#====================================================
# Misc commands
#====================================================
# note: 'cl' blocks something from the package 'cl-launch'. From apt search: "uniform frontend to running Common Lisp code from the shell"
alias cl='reset'
alias cls="reset;echo 'Note: You can use Ctrl+L to clear the terminal screen quickly.';";
alias nocaps="SYM_GROUP_NAME='none';setxkbmap -layout us -option;setxkbmap -layout us -option caps:\${SYM_GROUP_NAME};gsettings set org.gnome.desktop.input-sources xkb-options \"['caps:\${SYM_GROUP_NAME}']\";"

alias scriptcheck='echo "Note: Actual command is shellcheck"; shellcheck'
alias checkscript='echo "Note: Actual command is shellcheck"; shellcheck'

alias c='clear'
alias l='LC_ALL=c ls -qAhclp1 --group-directories-first'

# ls with selinux contexts
alias lz='LC_ALL=c ls -qAhclp1 -Z --group-directories-first'

# list newest/oldest files
alias newest='ls -lArt|tail -1'
alias oldest='ls -lAt|tail -1'

# make dir
alias mkdir='/usr/bin/mkdir -p'

#list directory
alias lsd='LC_ALL=c ls -qAhclp1 --group-directories-first';

# recreate windows dir /b (bare) command:
alias dir="LC_ALL=c ls -1qNAp --group-directories-first|grep -Pv '^\.{1,2}/?$'"

#list directory with headers
alias lsh="LC_ALL=c ls -qAhclp1 | sed '2iPerms         Ownr    Grp     Size Mod_Time     Name'";

#list verbose
alias lsv="LC_ALL=c ls -qAhclp1 --author --time-style=+'%Y-%m-%d %H:%M:%S' | sed '2iPerms         Auth    Ownr    Grp     Size Mod_Date   Mod_Time Name'";

#show drive space
alias drivespace='printAndSortByMountPoint'
alias space='printAndSortByMountPoint'
alias mostspace='printAndSortByAvailableDriveSpace'
alias spaceleft='printAndSortByAvailableDriveSpace'
alias spaceremaining='printAndSortByAvailableDriveSpace'
alias remainingspace='printAndSortByAvailableDriveSpace'

#python
alias py2='python2';
alias py3='python3';

alias fixpip='sudo ls -acl 2>/dev/null >/dev/null; fixSystemPermissions --pip';
alias pip='pip-pss';
alias pip3='pip-pss';

alias restartcinnamon="echo -e \"Option 1. Press 'Ctrl+Alt+Esc\\nOption 2. Alt+F2, followed by R\\nOption 3. Try alias 'rcinn'\""
alias rcinn="cinnamon --replace --clutter-display=:0 2> /dev/null &"

alias subdirstolower="find . -mindepth 1 -depth -type d -not -iwholename '*.git/*' -regex '^.*/[^/]*[A-Z][^/]*\$' -exec rename 's/(.*)\\/([^\\/]*)/\$1\\/\\L\$2/' {} \\;"
alias tolower="find . -mindepth 1 -depth -type d -not -iwholename '*.git/*' -regex '^.*/[^/]*[A-Z][^/]*\$' -exec rename 's/(.*)\\/([^\\/]*)/\$1\\/\\L\$2/' {} \\;"
alias checksubdircase="find . -mindepth 1 -depth -type d -not -iwholename '*.git/*' -regex '^.*/[^/]*[A-Z][^/]*\$'"
alias subdircase="find . -mindepth 1 -depth -type d -not -iwholename '*.git/*' -regex '^.*/[^/]*[A-Z][^/]*\$'"
alias checkemptyfiles="find . -mindepth 1 -type f -not -iwholename '*.git/*' -size 0"
alias hasemptyfiles="find . -mindepth 1 -type f -not -iwholename '*.git/*' -size 0"
alias emptyfiles="find . -mindepth 1 -type f -not -iwholename '*.git/*' -size 0"

alias mnt='mount'
alias umnt='umount'
alias unmount='umount'

#====================================================
# GIT
#====================================================
export gl_sep='-----------------------------------------------------------------------'

#git CLI commands without 'git' prefix
alias add='git add'
alias amend='git commit --amend -m'
alias branch="git branch --format='%(objectname:short) %(refname:strip=2)'"
alias branches="git branch -a --format='%(objectname:short) %(refname:strip=2)'"
alias btanch="git branch --format='%(objectname:short) %(refname:strip=2)'"
alias checkout='git checkout';
alias clone='git clone'
alias clonef='gitCloneWithFormattedDir'
alias cloneflist='gitCloneWithFormattedDir'
alias clonefd='gitCloneWithFormattedDir "%o_%n"'
alias clonefdlist='gitCloneListWithFormattedDir "%o_%n"'
alias clonefdef='gitCloneWithFormattedDir "%o_%n"'
alias clonefork='gitCloneWithFormattedDir "%o_%n_FORK"'
alias commit='git commit -m'
alias commita='git add -A; git commit -a -m'
alias commitall='git add -A; git commit -a -m'
#this would block /usr/bin/diff which is used for comparing files
#alias diff='git diff'
alias log="echo '${gl_sep}';GIT_PAGER=cat git log --format='%h  %cn  %cd  %s%n${gl_sep}' --date=format:'%Y-%m-%d %H:%M:%S'";
alias prune='git remote prune origin'
alias pull='git pull --no-edit --all'
alias push='git push --all'
alias \[ush='git push --all'
alias pullpush='git pull --no-edit --all && git push --all'
alias pupu='git pull --no-edit --all && git push --all'
alias pullsh='git pull --no-edit --all && git push --all'
alias pushall='git remote | xargs -L1 git push --all'
alias origin='git config --get remote.origin.url'
alias reflog='git reflog'
alias remote='git config --get remote.origin.url'
alias remotes='git remote -v'
#Note using alias 'stat' will block /usr/bin/stat which is used for determining filesizes
#alias stat='git status'
alias tag="git tag --format='%(objectname:short) %(refname:strip=2)'";
alias unstage='git reset HEAD'
#Note using alias 'reset' will block /usr/bin/reset which is used for resetting terminal output

# e.g. revert filename OR git checkout -- filename
alias revert='git checkout HEAD -- '
alias revertSingleFile='git checkout HEAD -- '
alias resetSingleFile='git checkout HEAD -- '

# list files in last x commits
alias lslast='git diff --name-status HEAD~1..HEAD'
alias lslast2='git diff --name-status HEAD~2..HEAD~1'
alias lslast3='git diff --name-status HEAD~3..HEAD~2'
alias lslast4='git diff --name-status HEAD~4..HEAD~3'
alias lslast5='git diff --name-status HEAD~5..HEAD~4'
alias lslast6='git diff --name-status HEAD~6..HEAD~5'
alias lslast7='git diff --name-status HEAD~7..HEAD~6'
alias lslast8='git diff --name-status HEAD~8..HEAD~7'
alias lslast9='git diff --name-status HEAD~9..HEAD~8'

# list remotes for all repos under dir
alias lsremotes='gitListRemotesForAllReposUnderDir'

# diff files in last x commits
alias difflast='git diff HEAD~1..HEAD'
alias difflast2='git diff HEAD~2..HEAD~1'
alias difflast3='git diff HEAD~3..HEAD~2'
alias difflast4='git diff HEAD~4..HEAD~3'
alias difflast5='git diff HEAD~5..HEAD~4'
alias difflast6='git diff HEAD~6..HEAD~5'
alias difflast7='git diff HEAD~7..HEAD~6'
alias difflast8='git diff HEAD~8..HEAD~7'
alias difflast9='git diff HEAD~9..HEAD~8'

#git CLI abbreviated commands
alias ga='git add'
alias gaa='git add .'
alias gaaa='git add --all'
alias gadd='git add'
alias gau='git add --update'
alias gb="git branch --format='%(objectname:short) %(refname:strip=2)'"
alias gbranch="git branch --format='%(objectname:short) %(refname:strip=2)'"
alias gc='git commit'
alias gcm='git commit --message'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gd='git diff'
alias gdiff='git diff'
alias gi='git init'

# H = full hash, h = abbreviated hash, cn = committer name, cd = commit date, s = string (commit message)
alias gl="echo '${gl_sep}';GIT_PAGER=cat git log --format='%C(cyan)%D%Creset  %Cred%h%Creset  %Cgreen%cn%Creset  %C(#ff8c00)%cd%Creset  %s%n${gl_sep}' --date=format:'%Y-%m-%d %H:%M:%S'";
alias glg="GIT_PAGER=cat git log --graph --oneline --decorate --all"
alias gld="GIT_PAGER=cat git log --pretty=format:'%h %ad %s' --date=short --all"

# --reflog will also print commits on other branches/tags
alias glog="echo '${gl_sep}';GIT_PAGER=cat git log --reflog --format='%C(cyan)%D%Creset  %Cred%h%Creset  %Cgreen%cn%Creset  %C(#ff8c00)%cd%Creset  %s%n${gl_sep}' --date=format:'%Y-%m-%d %H:%M:%S'";
alias gp='git pull --no-edit --all'
alias gprune='git remote prune origin'
alias gpull='git pull --no-edit --all'
alias greset='git reset --hard'
alias gss='git status --short'
alias gst='git status'
alias gstat='git status'
alias gt="git tag --format='%(objectname:short) %(refname:strip=2)'";
alias gtag="git tag --format='%(objectname:short) %(refname:strip=2)'";

#git CLI commands without space
alias gitadd='git add'
alias gitbranch="git branch --format='%(objectname:short) %(refname:strip=2)'"
alias gitclone='git clone'
alias gitcommit='git commit -m'
alias gitcommitall='git add -A; git commit -a -m'
alias gitdiff='git diff'
alias gitlog="echo '${gl_sep}';GIT_PAGER=cat git log --format='%C(cyan)%D%Creset  %Cred%h%Creset  %Cgreen%cn%Creset  %C(#ff8c00)%cd%Creset  %s%n${gl_sep}' --date=format:'%Y-%m-%d %H:%M:%S'";
alias gitprune='git remote prune origin'
alias gitpull='git pull --no-edit --all'
alias gitrename='git commit --amend'
alias gitreset='git reset --hard'
alias gitstat='git status'
alias gittag="git tag --format='%(objectname:short) %(refname:strip=2)'";

#gitext (GUI) commands
alias browse='gitext';
alias ge='gitext';
alias gebrowse='gitext';
alias gecheckout='gitext checkoutbranch';
alias geclone='gitext clone';
alias gecommit='gitext commit';
alias gepull='gitext pull --no-edit --all';
alias gestash='gitext stash';

#custom git commands
alias gstgdel="__num__git__deletions__=\$(git ls-files --deleted -- .|wc -l);if [[ \$__num__git__deletions__ -gt 0 ]]; then \$(git ls-files --deleted -- .|sed -E 's/^(.*)$/\"\\1\"/'|xargs git add); else echo 'no deletions found'; fi"
alias stgdel="__num__git__deletions__=\$(git ls-files --deleted -- .|wc -l);if [[ \$__num__git__deletions__ -gt 0 ]]; then \$(git ls-files --deleted -- .|sed -E 's/^(.*)$/\"\\1\"/'|xargs git add); else echo 'no deletions found'; fi"
alias stagedel="__num__git__deletions__=\$(git ls-files --deleted -- .|wc -l);if [[ \$__num__git__deletions__ -gt 0 ]]; then \$(git ls-files --deleted -- .|sed -E 's/^(.*)$/\"\\1\"/'|xargs git add); else echo 'no deletions found'; fi"
alias stagedeletions="__num__git__deletions__=\$(git ls-files --deleted -- .|wc -l);if [[ \$__num__git__deletions__ -gt 0 ]]; then \$(git ls-files --deleted -- .|sed -E 's/^(.*)$/\"\\1\"/'|xargs git add); else echo 'no deletions found'; fi"
alias pullall='gitUpdateAllReposUnderDir'

#====================================================
# navigation
#====================================================

# keep track of multiple previous dirs, not just the last one
alias back='changeDir -'
alias prev='changeDir -'
alias back1='changeDir -'
alias prev1='changeDir -'
alias opwd="changeDir \"\$OLDPWD\""

alias back2="changeDir \"\$OLDPWD0\""
alias prev2="changeDir \"\$OLDPWD0\""
alias opwd0="changeDir \"\$OLDPWD0\""

alias back3="changeDir \"\$OLDPWD1\""
alias prev3="changeDir \"\$OLDPWD1\""
alias opwd1="changeDir \"\$OLDPWD1\""

alias back4="changeDir \"\$OLDPWD2\""
alias prev4="changeDir \"\$OLDPWD2\""
alias opwd2="changeDir \"\$OLDPWD2\""

alias back5="changeDir \"\$OLDPWD3\""
alias prev5="changeDir \"\$OLDPWD3\""
alias opwd3="changeDir \"\$OLDPWD3\""

alias back6="changeDir \"\$OLDPWD4\""
alias prev6="changeDir \"\$OLDPWD4\""
alias opwd4="changeDir \"\$OLDPWD4\""

alias back7="changeDir \"\$OLDPWD5\""
alias prev7="changeDir \"\$OLDPWD5\""
alias opwd5="changeDir \"\$OLDPWD5\""

alias back8="changeDir \"\$OLDPWD6\""
alias prev8="changeDir \"\$OLDPWD6\""
alias opwd6="changeDir \"\$OLDPWD6\""

alias back9="changeDir \"\$OLDPWD7\""
alias prev9="changeDir \"\$OLDPWD7\""
alias opwd7="changeDir \"\$OLDPWD7\""

alias back10="changeDir \"\$OLDPWD8\""
alias prev10="changeDir \"\$OLDPWD8\""
alias opwd8="changeDir \"\$OLDPWD8\""

alias back11="changeDir \"\$OLDPWD9\""
alias prev11="changeDir \"\$OLDPWD9\""
alias opwd9="changeDir \"\$OLDPWD9\""

alias printo="printf '\\n\\tOLDPWD:  %s\\n\\tOLDPWD0: %s\\n\\tOLDPWD1: %s\\n\\tOLDPWD2: %s\\n\\tOLDPWD3: %s\\n\\tOLDPWD4: %s\\n\\tOLDPWD5: %s\\n\\tOLDPWD6: %s\\n\\tOLDPWD7: %s\\n\\tOLDPWD8: %s\\n\\tOLDPWD9: %s\\n\\n' \"\$OLDPWD\" \"\$OLDPWD0\" \"\$OLDPWD1\" \"\$OLDPWD2\" \"\$OLDPWD3\" \"\$OLDPWD4\" \"\$OLDPWD5\" \"\$OLDPWD6\" \"\$OLDPWD7\" \"\$OLDPWD8\" \"\$OLDPWD9\";"
alias printopwds="printf '\\n\\tOLDPWD:  %s\\n\\tOLDPWD0: %s\\n\\tOLDPWD1: %s\\n\\tOLDPWD2: %s\\n\\tOLDPWD3: %s\\n\\tOLDPWD4: %s\\n\\tOLDPWD5: %s\\n\\tOLDPWD6: %s\\n\\tOLDPWD7: %s\\n\\tOLDPWD8: %s\\n\\tOLDPWD9: %s\\n\\n' \"\$OLDPWD\" \"\$OLDPWD0\" \"\$OLDPWD1\" \"\$OLDPWD2\" \"\$OLDPWD3\" \"\$OLDPWD4\" \"\$OLDPWD5\" \"\$OLDPWD6\" \"\$OLDPWD7\" \"\$OLDPWD8\" \"\$OLDPWD9\";"

alias clearopwd="OLDPWD9='';OLDPWD8='';OLDPWD7='';OLDPWD6='';OLDPWD5='';OLDPWD4='';OLDPWD3='';OLDPWD2='';OLDPWD1='';OLDPWD0='';OLDPWD=~";
alias clropwd="OLDPWD9='';OLDPWD8='';OLDPWD7='';OLDPWD6='';OLDPWD5='';OLDPWD4='';OLDPWD3='';OLDPWD2='';OLDPWD1='';OLDPWD0='';OLDPWD=~";

# define navigation "quickslots"
alias 0="changeDir \"\$d0\""
alias 1="changeDir \"\$d1\""
alias 2="changeDir \"\$d2\""
alias 3="changeDir \"\$d3\""
alias 4="changeDir \"\$d4\""
alias 5="changeDir \"\$d5\""
alias 6="changeDir \"\$d6\""
alias 7="changeDir \"\$d7\""
alias 8="changeDir \"\$d8\""
alias 9="changeDir \"\$d9\""

alias set0="d0=\"\$(pwd)\""
alias set1="d1=\"\$(pwd)\""
alias set2="d2=\"\$(pwd)\""
alias set3="d3=\"\$(pwd)\""
alias set4="d4=\"\$(pwd)\""
alias set5="d5=\"\$(pwd)\""
alias set6="d6=\"\$(pwd)\""
alias set7="d7=\"\$(pwd)\""
alias set8="d8=\"\$(pwd)\""
alias set9="d9=\"\$(pwd)\""

alias l0="printf '\\n%s\\n\\n' \"\$d0\"; ls -acl \"\$d0\";"
alias l1="printf '\\n%s\\n\\n' \"\$d1\"; ls -acl \"\$d1\";"
alias l2="printf '\\n%s\\n\\n' \"\$d2\"; ls -acl \"\$d2\";"
alias l3="printf '\\n%s\\n\\n' \"\$d3\"; ls -acl \"\$d3\";"
alias l4="printf '\\n%s\\n\\n' \"\$d4\"; ls -acl \"\$d4\";"
alias l5="printf '\\n%s\\n\\n' \"\$d5\"; ls -acl \"\$d5\";"
alias l6="printf '\\n%s\\n\\n' \"\$d6\"; ls -acl \"\$d6\";"
alias l7="printf '\\n%s\\n\\n' \"\$d7\"; ls -acl \"\$d7\";"
alias l8="printf '\\n%s\\n\\n' \"\$d8\"; ls -acl \"\$d8\";"
alias l9="printf '\\n%s\\n\\n' \"\$d9\"; ls -acl \"\$d9\";"

alias mv0="mv -n -t \"\$d0\""
alias mv1="mv -n -t \"\$d1\""
alias mv2="mv -n -t \"\$d2\""
alias mv3="mv -n -t \"\$d3\""
alias mv4="mv -n -t \"\$d4\""
alias mv5="mv -n -t \"\$d5\""
alias mv6="mv -n -t \"\$d6\""
alias mv7="mv -n -t \"\$d7\""
alias mv8="mv -n -t \"\$d8\""
alias mv9="mv -n -t \"\$d9\""

alias cp0="cp -n -a -t \"\$d0\""
alias cp1="cp -n -a -t \"\$d1\""
alias cp2="cp -n -a -t \"\$d2\""
alias cp3="cp -n -a -t \"\$d3\""
alias cp4="cp -n -a -t \"\$d4\""
alias cp5="cp -n -a -t \"\$d5\""
alias cp6="cp -n -a -t \"\$d6\""
alias cp7="cp -n -a -t \"\$d7\""
alias cp8="cp -n -a -t \"\$d8\""
alias cp9="cp -n -a -t \"\$d9\""

alias pdir="printf '\\n\\td0: %s\\n\\td1: %s\\n\\td2: %s\\n\\td3: %s\\n\\td4: %s\\n\\td5: %s\\n\\td6: %s\\n\\td7: %s\\n\\td8: %s\\n\\td9: %s\\n\\n' \"\$d0\" \"\$d1\" \"\$d2\" \"\$d3\" \"\$d4\" \"\$d5\" \"\$d6\" \"\$d7\" \"\$d8\" \"\$d9\";"
alias pdirs="printf '\\n\\td0: %s\\n\\td1: %s\\n\\td2: %s\\n\\td3: %s\\n\\td4: %s\\n\\td5: %s\\n\\td6: %s\\n\\td7: %s\\n\\td8: %s\\n\\td9: %s\\n\\n' \"\$d0\" \"\$d1\" \"\$d2\" \"\$d3\" \"\$d4\" \"\$d5\" \"\$d6\" \"\$d7\" \"\$d8\" \"\$d9\";"
alias printd="printf '\\n\\td0: %s\\n\\td1: %s\\n\\td2: %s\\n\\td3: %s\\n\\td4: %s\\n\\td5: %s\\n\\td6: %s\\n\\td7: %s\\n\\td8: %s\\n\\td9: %s\\n\\n' \"\$d0\" \"\$d1\" \"\$d2\" \"\$d3\" \"\$d4\" \"\$d5\" \"\$d6\" \"\$d7\" \"\$d8\" \"\$d9\";"
alias printdir="printf '\\n\\td0: %s\\n\\td1: %s\\n\\td2: %s\\n\\td3: %s\\n\\td4: %s\\n\\td5: %s\\n\\td6: %s\\n\\td7: %s\\n\\td8: %s\\n\\td9: %s\\n\\n' \"\$d0\" \"\$d1\" \"\$d2\" \"\$d3\" \"\$d4\" \"\$d5\" \"\$d6\" \"\$d7\" \"\$d8\" \"\$d9\";"
alias printdirs="printf '\\n\\td0: %s\\n\\td1: %s\\n\\td2: %s\\n\\td3: %s\\n\\td4: %s\\n\\td5: %s\\n\\td6: %s\\n\\td7: %s\\n\\td8: %s\\n\\td9: %s\\n\\n' \"\$d0\" \"\$d1\" \"\$d2\" \"\$d3\" \"\$d4\" \"\$d5\" \"\$d6\" \"\$d7\" \"\$d8\" \"\$d9\";"

alias cleard="d1='';d2='';d3='';d4='';d5='';d6='';d7='';d8='';d9='';d0='';";
alias cleardirs="d1='';d2='';d3='';d4='';d5='';d6='';d7='';d8='';d9='';d0='';";
alias clearqdirs="d1='';d2='';d3='';d4='';d5='';d6='';d7='';d8='';d9='';d0='';";

alias h='changeDir ~/'
alias r='changeDir /'

alias @='nemo .'
alias explorer='nemo'

alias ~='changeDir ~'

alias u='changeDir ..'
alias up='changeDir ..'
alias uop='changeDir ..'
alias up1='changeDir ..'
alias up2='changeDir ../..'
alias up3='changeDir ../../..'
alias up4='changeDir ../../../..'
alias up5='changeDir ../../../../..'
alias up6='changeDir ../../../../../..'
alias up7='changeDir ../../../../../../..'
alias up8='changeDir ../../../../../../../..'
alias up9='changeDir ../../../../../../../../..'

alias cdnew="makeThenChangeDir";

alias tmp='changeDir /tmp'
alias home='changeDir /home'
alias etc='changeDir /etc'
alias smb='changeDir /etc/samba'

if [[ 'debian' == "${BASE_DISTRO}" ]]; then
	alias aptsrc='changeDir /etc/apt/sources.list.d/'
	alias repos='changeDir /etc/apt/sources.list.d/'
	alias sources='changeDir /etc/apt/sources.list.d/'
	alias ppas='changeDir /etc/apt/sources.list.d/'
elif [[ 'fedora' == "${BASE_DISTRO}" ]]; then
	alias repos='changeDir /etc/yum.repos.d/'
	alias sources='changeDir /etc/yum.repos.d/'
fi

alias smbconfig='changeDir /etc/samba'
alias nemodir='changeDir /usr/share/nemo'
alias nemoactions='changeDir /usr/share/nemo/actions'
alias apps='changeDir /usr/share/applications'
alias appdir='changeDir /usr/share/applications'
alias appsdir='changeDir /usr/share/applications'
alias icons='changeDir /usr/share/icons'
alias iconsdir='changeDir /usr/share/icons'
alias share='changeDir /usr/share'
alias sharedir='changeDir /usr/share'

#====================================================
# Handle my common typos / bad spelling
#====================================================
# for 'cd' :
alias cd='changeDir'
alias ad='changeDir'
alias sd='changeDir'
alias wd='changeDir'
alias we='changeDir'
alias dc='changeDir'
alias ced='changeDir'
alias cde='changeDir'
alias cxd='changeDir'
alias cdx='changeDir'
alias cs='changeDir'
alias cx='changeDir'
alias xs='changeDir'
alias xd='changeDir'
alias vf='changeDir'

# for 'up' alias I commonly use :
alias uo='changeDir ..'
alias up\[='changeDir ..'
alias upl='changeDir ..; LC_ALL=c ls -qAhclp1 --group-directories-first'

# for 'ls' or the 'l' alias I usually use :
alias ls-acl='LC_ALL=c ls -qAhclp1 --group-directories-first'
alias k='LC_ALL=c ls -qAhclp1 --group-directories-first'
alias ll'LC_ALL=c ls -qAhclp1 --group-directories-first'

# for 'echo' :
alias ecgo='echo'
alias echp='echo'
alias echi='echo'
alias eco='echo'
alias e='echo'

# for 'which' :
alias qhich='which'
alias whuch='which'
alias wcjich='which'
alias wchich='which'
alias wchic='which'
alias whick='which'

# for 'chown' :
alias chonw='chown'

# for 'man' :
alias mna='man'
alias mzn='man'

# for 'grep' :
alias fepw='grep'
alias grpe='grep'
alias greo='grep'
alias greio='grep'
alias rgep='grep'
alias gre\[='grep'

# for 'exit' :
alias :x='exit'
alias :q='exit'
alias q='exit'
alias x='exit'
alias ex='exit'
alias xeit='exit'
alias eixt='exit'
alias exti='exit'
alias exot='exit'
alias excit='exit'


