# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

bashrcDebugLevel=0;		# no debug messages
#bashrcDebugLevel=1;		# section names only
#bashrcDebugLevel=2;		# section names + file load messages
#bashrcDebugLevel=3;		# all messages

[[ $bashrcDebugLevel -ge 1 ]] && echo "Loading .bashrc ...";

# If not running interactively, don't do anything
case $- in
	*i*) ;;
	  *) return;;
esac

# =======================================================================================================================
# User specific shell settings
# =======================================================================================================================
[[ $bashrcDebugLevel -ge 1 ]] && echo "  Defining User shell settings ...";

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# defining default settings for xz to use best compression (see man xz)
XZ_DEFAULTS=-9e

#Disable stupid behavior of Ctrl+S so it does't freeze cli editors like vi
# See: https://unix.stackexchange.com/questions/72086/ctrl-s-hang-terminal-emulator
stty -ixon

# basic aliases in case no alias file defined / it has errors
alias l='ls -cls'
alias up='cd ..'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Set more secure default file perms
#   See:
#   https://www.computernetworkingnotes.com/rhce-study-guide/how-to-change-default-umask-permission-in-linux.html
#
#  When a new file or folder is created it uses a default permission which is
#  determined by an initial permission minus the umask bits
#     initial dir permission  = 0777
#     initial file permission = 0666
#     default root umask      = 0022 (dirs => 755, files => 644)
#     default non-root umask  = 0002 (dirs => 775, files => 664)
#     non-root with o-rwx     = 0007 (dirs => 770, files => 660)
if [[ 'root' == "$USER" ]]; then
	umask 0022;
else
	umask 0007
fi

# To define more complex ACLs, you will need to first ensure that the drive is mounted in fstab
# with ACLs and then define ACLs for the given directory
#   https://superuser.com/questions/264383/how-to-set-file-permissions-so-that-new-files-inherit-same-permissions
# e.g
#
# $ grep acl /etc/fstab
# UUID=some-uuid-blah-blah   /media/mymount    ext4  defaults,nofail,x-systemd.device-timeout=5s,nodev,acl,lazytime
#
# then
# setfacl -d -m u::rwX,g::rwX,o::- /media/mymount/shareddir
# or
# setfacl -d -m u:someuser:rwX,g:somegroup:rwX,o::- /media/mymount/shareddir
#

# =======================================================================================================================
# User specific color settings
# =======================================================================================================================
[[ $bashrcDebugLevel -ge 1 ]] && echo "  Defining User color settings ...";

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
	xterm-color|*-256color) color_prompt=yes;;
	*)
		if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
			color_prompt=yes;
		fi
		;;
esac

if [ "$color_prompt" = yes ]; then
	if [[ 'root' == "$USER" ]]; then
		PS1='\[\033[01;31m\]I_AM_ROOT\[\033[00m\]\[\033[32m\]@\h\[\033[00m\]:\[\033[01;38;2;255;140;0m\]\w\[\033[00m\]\[\033[01;31m\]\n\$\[\033[00m\] '
	else
 		PS1='\[\033[01;36m\]\u\[\033[00m\]\[\033[32m\]@\h\[\033[00m\]:\[\033[01;38;2;255;140;0m\]\w\[\033[00m\]\[\033[01;31m\]\n\$\[\033[00m\] '
	fi
else
	PS1='\u@\h:\w\n\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
	if [[ 'root' == "$USER" ]]; then
		PS1="\[\e]0;ROOT@\h: \w\a\]$PS1"
	else
		PS1="\[\e]0;\u@\h: \w\a\]$PS1"
	fi
	;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
	[[ -r ~/.dircolors ]] && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	alias ls='ls --color=auto'
	#alias dir='dir --color=auto'
	#alias vdir='vdir --color=auto'

	if [[ -f /bin/grep ]]; then
		alias grep='/bin/grep --color=auto'
	else
		alias grep='/usr/bin/grep --color=auto'
	fi
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
fi

# change the color of directories shown with ls so that they are readable against a dark background
LS_COLORS=$LS_COLORS:'di=0;38;2;255;140;0:' ; export LS_COLORS

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# =======================================================================================================================
# User specific environment variables (note: some of these are referenced by aliases/functions)
# =======================================================================================================================
[[ $bashrcDebugLevel -ge 1 ]] && echo "  Defining User environment variables ...";

# I am using a cache file to reduce file lookup and processing overhead for one-time setups
# particularly variables set based on distro which are not likely to change very often
# when the variables need to be refreshed, the cache file can simply be deleted and it will
# automatically be recreated next time a bash shell is run.
if [ -f ~/.bash_varcache ]; then
	. ~/.bash_varcache;
elif [[ -f ~/.bash_set_distro_vars ]]; then
	. ~/.bash_set_distro_vars;

	#set a default user agent if one is not already defined somewhere else; handy for quick one-off tests with wget/curl/etc
	if [[ -z "${CHROME_USER_AGENT}" ]]; then
		CHROME_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36";
		export CHROME_USER_AGENT="${CHROME_USER_AGENT}";
		export CHROME_UA="${CHROME_USER_AGENT}";
	fi
	if [[ -z "${FIREFOX_USER_AGENT}" ]]; then
		FIREFOX_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:60.0) Gecko/20100101 Firefox/70.0";
		export FIREFOX_USER_AGENT="${FIREFOX_USER_AGENT}";
		export FIREFOX_UA="${FIREFOX_USER_AGENT}";
		export FF_USER_AGENT="${FIREFOX_USER_AGENT}";
	fi
	if [[ -z "${USER_AGENT}" ]]; then
		if [[ -n "${UA}" ]]; then
			USER_AGENT="${UA}";
		elif [[ -n "${CHROME_USER_AGENT}" ]]; then
			USER_AGENT="${CHROME_USER_AGENT}";
		elif [[ -n "${FIREFOX_USER_AGENT}" ]]; then
			USER_AGENT="${FIREFOX_USER_AGENT}";
		fi
	fi
	if [[ -n "${USER_AGENT}" ]]; then
		[[ -z "${UA}" ]] && UA="${USER_AGENT}";
		export USER_AGENT="${USER_AGENT}";
		export UA="${UA}";
	fi

	echo "export DISTRO_NAME='$DISTRO_NAME'" >> ~/.bash_varcache;
	echo "export DISTRO_VERSION='$DISTRO_VERSION'" >> ~/.bash_varcache;
	echo "export PARENT_DISTRO='$PARENT_DISTRO'" >> ~/.bash_varcache;
	echo "export BASE_DISTRO='$BASE_DISTRO'" >> ~/.bash_varcache;

	[[ ! -z "$DEBIAN_CODENAME" ]] && echo "export DEBIAN_CODENAME='$DEBIAN_CODENAME'" >> ~/.bash_varcache;
	[[ ! -z "$DEBIAN_VERSION" ]] && echo "export DEBIAN_VERSION='$DEBIAN_VERSION'" >> ~/.bash_varcache;

	[[ ! -z "$UBUNTU_CODENAME" ]] && echo "export UBUNTU_CODENAME='$UBUNTU_CODENAME'" >> ~/.bash_varcache;
	[[ ! -z "$UBUNTU_VERSION" ]] && echo "export UBUNTU_VERSION='$UBUNTU_VERSION'" >> ~/.bash_varcache;

	[[ ! -z "$MINT_CODENAME" ]] && echo "export MINT_CODENAME='$MINT_CODENAME'" >> ~/.bash_varcache;
	[[ ! -z "$MINT_VERSION" ]] && echo "export MINT_VERSION='$MINT_VERSION'" >> ~/.bash_varcache;

	[[ ! -z "$CHROME_USER_AGENT" ]] && echo "export CHROME_USER_AGENT='$CHROME_USER_AGENT'" >> ~/.bash_varcache;
	[[ ! -z "$FIREFOX_USER_AGENT" ]] && echo "export FIREFOX_USER_AGENT='$FIREFOX_USER_AGENT'" >> ~/.bash_varcache;
	[[ ! -z "$USER_AGENT" ]] && echo "export USER_AGENT='$USER_AGENT'" >> ~/.bash_varcache;
	[[ ! -z "$UA" ]] && echo "export UA='$UA'" >> ~/.bash_varcache;

	THEFUCK_IS_INSTALLED=0;
	if [[ -f /usr/local/bin/thefuck ]]; then
		THEFUCK_IS_INSTALLED=1;
	fi
	echo "export THEFUCK_IS_INSTALLED=$THEFUCK_IS_INSTALLED" >> ~/.bash_varcache;

	# is sdkman installed? check custom system locations first, then fallback to user HOME
	# note: depsite the auto-generated message saying it needs to be at the END, sdkman
	# will work just fine from ANY location in the file as long as its variable is exported
	# and it's init file is sourced. So the variable will be set into the cache and the init
	# file can be conditionally sourced based on if the variable exists or not (below)
	if [[ 0 == $UID && -f "/usr/local/sdkman/bin/sdkman-init.sh" ]]; then
		export SDKMAN_DIR="/usr/local/sdkman";

	elif [[ 0 == $UID && -f "/usr/share/sdkman/bin/sdkman-init.sh" ]]; then
		export SDKMAN_DIR="/usr/share/sdkman";

	elif [[ 0 == $UID && -f "/opt/sdkman/bin/sdkman-init.sh" ]]; then
		export SDKMAN_DIR="/opt/sdkman";

	elif [[ 0 != $UID && -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
		export SDKMAN_DIR="$HOME/.sdkman";
	fi
	[[ ! -z "$SDKMAN_DIR" ]] && echo "export SDKMAN_DIR='$SDKMAN_DIR'" >> ~/.bash_varcache;


	if [[ 0 != $UID ]]; then
		# only set if not set at system-level
		if [[ -z "$GOPATH" ]]; then
			if [[ -d "$HOME/go" ]]; then
				export GOPATH="$HOME/go";

			elif [[ -d "$HOME/go" ]]; then
				export GOPATH="$HOME/go";
			fi
			[[ ! -z "$GOPATH" ]] && echo "export GOPATH='$GOPATH'" >> ~/.bash_varcache;
		fi
		if [[ ! -z "$GOPATH" && -z "$GOBIN" ]]; then
			if [[ "$GOPATH" == "$HOME/go" ]]; then
				mkdir -p "$GOPATH/bin" 2>/dev/null;
				export GOBIN="$GOPATH/bin";

			elif [[ -d "$GOPATH/bin" ]]; then
				export GOBIN="$GOPATH/bin";
			fi
			[[ ! -z "$GOBIN" ]] && echo "export GOBIN='$GOBIN'" >> ~/.bash_varcache;
		fi

		# only set if not set at system-level
		if [[ -z "$JAVA_HOME" ]]; then
			if [[ -d "/usr/lib/jvm/java-11-openjdk" ]]; then
				export JAVA_HOME="/usr/lib/jvm/java-11-openjdk";

			elif [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
				export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64";

			elif [[ -d "/usr/lib/jvm/java-8-openjdk-amd64" ]]; then
				export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64";
			fi
			[[ ! -z "$JAVA_HOME" ]] && echo "export JAVA_HOME='$JAVA_HOME'" >> ~/.bash_varcache;
		fi

		# only set if not set at system-level
		if [[ -z "$CARGO_HOME" ]]; then
			if [[ -d "$HOME/.cargo" ]]; then
				export CARGO_HOME="$HOME/.cargo";
			fi
			[[ ! -z "$CARGO_HOME" ]] && echo "export CARGO_HOME='$CARGO_HOME'" >> ~/.bash_varcache;
		fi
		if [[ ! -z "$CARGO_HOME" && -z "$CARGO_BIN" ]]; then
			if [[ ! -z "$CARGO_HOME" && -d "$CARGO_HOME/bin" ]]; then
				export CARGO_BIN="$CARGO_HOME/bin";
			fi
			[[ ! -z "$CARGO_BIN" ]] && echo "export CARGO_BIN='$CARGO_BIN'" >> ~/.bash_varcache;
		fi

		# Nodejs: https://www.tecmint.com/nvm-install-multiple-nodejs-versions-in-linux/
		#	NVM = Node Version Manager
		#
		# only set if not set at system-level
		if [[ -z "$NODEJS_NVM_DIR" || -z "$NVM_DIR" ]]; then
			if [[ ! -z "$NODEJS_NVM_DIR" && -s "$NODEJS_NVM_DIR/nvm.sh" && -s "$NODEJS_NVM_DIR/bash_completion" ]]; then
				NVM_DIR="$NODEJS_NVM_DIR";

			elif [[ ! -z "$NVM_DIR" && -s "$NVM_DIR/nvm.sh" && -s "$NVM_DIR/bash_completion" ]]; then
				NODEJS_NVM_DIR="$NVM_DIR";

			elif [[ -d "$HOME/.nvm" && -s "$HOME/.nvm/nvm.sh" && -s "$HOME/.nvm/bash_completion" ]]; then
				export NODEJS_NVM_DIR="$HOME/.nvm";
				export NVM_DIR="$HOME/.nvm";
			fi
			[[ ! -z "$NODEJS_NVM_DIR" ]] && echo "export NODEJS_NVM_DIR='$NODEJS_NVM_DIR'" >> ~/.bash_varcache;
			[[ ! -z "$NVM_DIR" ]] && echo "export NVM_DIR='$NVM_DIR'" >> ~/.bash_varcache;
		fi
	fi
fi
# end use cache/gen cache block

if [[ $bashrcDebugLevel -ge 3 ]]; then
	echo "";
	echo "      CHROME_USER_AGENT:  '$CHROME_USER_AGENT'";
	echo "      FIREFOX_USER_AGENT: '$FIREFOX_USER_AGENT'";
	echo "      USER_AGENT:         '$USER_AGENT'";
fi

# this is to make git not be a stupid git who pesters you for commit messages during auto-merges
# and to instead just use the default fucking message for an automerge, like any sane individual
# See:
# https://stackoverflow.com/questions/12752288/git-merge-doesnt-use-default-merge-message-opens-editor-with-default-message
#
export GIT_MERGE_AUTOEDIT=no

# =======================================================================================================================
# User specific aliases and functions
# =======================================================================================================================
[[ $bashrcDebugLevel -ge 1 ]] && echo "  Loading User aliases and functions ...";

# This determines which bash sub-scripts to load and in what order
#   It includes things like .bash_functions and .bash_aliases
aryFilesToSource=(  )
aryFilesToSource+=("${HOME}/.bash_functions");
aryFilesToSource+=("${HOME}/.bash_aliases");

if [[ ! -z "$SDKMAN_DIR" ]]; then
	aryFilesToSource+=("${SDKMAN_DIR}/bin/sdkman-init.sh");
fi

if [[ 0 != $UID && ! -z "$NVM_DIR" ]]; then
	aryFilesToSource+=("$NVM_DIR/nvm.sh");
	aryFilesToSource+=("$NVM_DIR/bash_completion");
fi

if [[ '0' != "${#aryFilesToSource[@]}" ]]; then
	for srcFile in "${aryFilesToSource[@]}"; do
		if [[ -f "${srcFile}" ]]; then
			[[ $bashrcDebugLevel -ge 2 ]] && echo "    Loading '${srcFile}' ...";
			source "${srcFile}";
			[[ $bashrcDebugLevel -ge 2 ]] && echo "    Loaded '${srcFile}' ...";
		fi
	done
fi
unset aryFilesToSource;

# =======================================================================================================================
# User specific history settings
# =======================================================================================================================
[[ $bashrcDebugLevel -ge 1 ]] && echo "  Defining User history settings ...";

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
#HISTSIZE=1000
#HISTFILESIZE=2000

# Unlimited history size
HISTSIZE=-1
HISTFILESIZE=-1

# use seed value of seconds so that we are not checking this every single time a terminal is launched...
# this changes so the check is run whenever a terminal is launched when seconds is evenly divisible by 10
histSS=$(date +'%S');
if [[ $bashrcDebugLevel -ge 3 || '0' == "${histSS:1:1}" ]]; then
	# check if history is getting too big ...
	# requires functions to be loaded

	[[ $bashrcDebugLevel -ge 3 ]] && echo "    Checking history size ...";
	if (( $(cat "$HOME/.bash_history" 2>/dev/null|wc -l) > 5000 )); then
		if [[ "1" == "$(type -t backupAndCleanBashHistory|wc -l)" ]]; then
			echo "    WARNING: .bash_history over 5000k lines; rotating file to backup ...";
			# rotate cleaned history to new file for easier searching
			mv "$HOME/.bash_history" "$HOME/.bash_history."$(date +'%Y%m%d%H%M%S').bak;
			touch "$HOME/.bash_history" && chmod 600 "$_";
		fi
	fi
fi

# =======================================================================================================================
# User specific paths
# =======================================================================================================================
[[ $bashrcDebugLevel -ge 1 ]] && echo "  Defining User paths ...";

# define paths to add (if not present) and the order in which to add them (start of list => FRONT of PATH var)
aryUserOrderedPaths=(  );
aryUserOrderedPaths+=("$HOME/.local/bin");
aryUserOrderedPaths+=("$HOME/bin");
[[ 0 != $UID && ! -z "$JAVA_HOME" && -d "$JAVA_HOME/bin" ]] && aryUserOrderedPaths+=("$JAVA_HOME/bin");

# Loop through desired paths backwards to ensure the order above is preserved
if [[ '0' != "${#aryUserOrderedPaths[@]}" ]]; then
	for ((i = $(( ${#aryUserOrderedPaths[@]} - 1 )); i >= 0 ; i--)); do
		pathToCheck="${aryUserOrderedPaths[$i]}";

		# check if path is already in PATH var; if not, prepend it
		if [[ ! ":$PATH:" =~ ":${pathToCheck}:" ]]; then
			PATH="${pathToCheck}:$PATH";
		fi
	done
fi
unset aryUserOrderedPaths;

# define paths to add (if not present) which will simply be appended to the end of PATH in any order
aryUserUnorderedPaths=(  );
[[ 0 != $UID && ! -z "$GOBIN" ]]     && aryUserOrderedPaths+=("$GOBIN");
[[ 0 != $UID && ! -z "$CARGO_BIN" ]] && aryUserOrderedPaths+=("$CARGO_BIN");

if [[ '0' != "${#aryUserUnorderedPaths[@]}" ]]; then
	for pathToCheck in $(echo "${aryUserUnorderedPaths[@]}"); do
		# check if path is already in PATH var; if not, append it
		if [[ ! ":$PATH:" =~ ":${pathToCheck}:" ]]; then
			PATH="$PATH:${pathToCheck}";
		fi
	done
fi
unset aryUserUnorderedPaths;

export PATH="${PATH}";

[[ $bashrcDebugLevel -ge 3 ]] && echo "      PATH='$PATH'";
unset bashrcDebugLevel;

if [[ 0 != $UID && 1 == ${THEFUCK_IS_INSTALLED} ]]; then
	eval "$(thefuck --alias)"
fi

