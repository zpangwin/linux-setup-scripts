# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples


if [[ "" == "${USERHOME}" ]]; then
	export USERHOME="/home/${USER}";
fi

if [[ "" == "${USERSCRIPTS}" && -e "${USERHOME}/Scripts" ]]; then
	export USERSCRIPTS="${USERHOME}/Scripts";
fi


# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

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

# cleanup junk from history file on new session
if [[ -e "$HOME/.bash_history" ]]; then
	# remove leading spaces
	sed -i -E 's/^\s+//g' "$HOME/.bash_history";

	# remove all various read statements
	sed -i '/^cls$/d' "$HOME/.bash_history";
	sed -i '/^history/d' "$HOME/.bash_history";
	sed -i '/^l$/d' "$HOME/.bash_history";
	sed -i '/^s$/d' "$HOME/.bash_history";
	sed -i '/^ls -acl$/d' "$HOME/.bash_history";
	sed -i '/^up[1-9]?$/d' "$HOME/.bash_history";
	sed -i '/^xfind$/d' "$HOME/.bash_history";
	sed -i '/^pcinfo$/d' "$HOME/.bash_history";
	sed -i '/^ipaddr$/d' "$HOME/.bash_history";

	# remove all various read statements with a single argument
	sed -i '/^l \/[A-Za-z0-9\-\/]*$/d' "$HOME/.bash_history";
	sed -i '/^ls \/[A-Za-z0-9\-\/]*$/d' "$HOME/.bash_history";
	sed -i '/^ls -acl \/[A-Za-z0-9\-\/]*$/d' "$HOME/.bash_history";
	sed -i '/^man [A-Za-z0-9\-]*$/d' "$HOME/.bash_history";
	sed -i '/^which [A-Za-z0-9\-]*$/d' "$HOME/.bash_history";
	sed -i '/^echo "[^"]*"$/d' "$HOME/.bash_history";
	sed -i '/^md5sum "?[^"|]*"?$/d' "$HOME/.bash_history";
	sed -i '/^sha256sum "?[^"|]*"?$/d' "$HOME/.bash_history";
	sed -i '/^sha512sum "?[^"|]*"?$/d' "$HOME/.bash_history";

	# remove all "gstat" alias / various git calls
	sed -i '/^gstat$/d' "$HOME/.bash_history";
	sed -i '/^git init$/d' "$HOME/.bash_history";
	sed -i '/^git push$/d' "$HOME/.bash_history";
	sed -i '/^git pull$/d' "$HOME/.bash_history";
	sed -i '/^git status$/d' "$HOME/.bash_history";
	sed -i '/^g?pull$/d' "$HOME/.bash_history";
	sed -i '/^g?push$/d' "$HOME/.bash_history";

	# remove empty lines
	sed -i '/^$/d' "$HOME/.bash_history";
fi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Function definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.

if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

#set a default user agent if one is not already defined somewhere else; handy for quick one-off tests with wget/curl/etc
if [[ "" == "${CHROME_USER_AGENT}" ]]; then
	CHROME_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36";
fi
if [[ "" == "${FIREFOX_USER_AGENT}" ]]; then
	FIREFOX_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:60.0) Gecko/20100101 Firefox/70.0";
fi
if [[ "" == "${USER_AGENT}" ]]; then
	if [[ "" != "${UA}" ]]; then
		USER_AGENT="${UA}";
	else
		if [[ "" != "${CHROME_USER_AGENT}" ]]; then
			USER_AGENT="${CHROME_USER_AGENT}";
		elif [[ "" != "${FIREFOX_USER_AGENT}" ]]; then
			USER_AGENT="${FIREFOX_USER_AGENT}";
		fi
	fi
fi
if [[ "" == "${UA}" && "" != "${USER_AGENT}" ]]; then
	UA="${USER_AGENT}";
fi

#Disable stupid behavior of Ctrl+S so it does't freeze cli editors like vi
# See: https://unix.stackexchange.com/questions/72086/ctrl-s-hang-terminal-emulator
stty -ixon

if [[ -d "${HOME}/.local/bin" ]]; then
	# added by pipx (https://github.com/pipxproject/pipx)
	pathHasLocalBin=$(echo "${PATH}" | grep -P "${HOME}/.local/bin(:|\$)" | wc -l);
	if [[ "0" == "${pathHasLocalBin}" ]]; then
		PATH="${HOME}/.local/bin:${PATH}";
	fi
fi

# Path additions for GOLANG
if [[ -d "${HOME}/go" ]]; then
	export GOPATH=${HOME}/go;
	export GOBIN=${GOPATH}/bin;
	pathHasGoBin=$(echo "${PATH}" | grep -P ":${GOBIN}(:|\$)" | wc -l);
	if [[ "0" == "${pathHasGoBin}" ]]; then
		PATH="${PATH}:${GOBIN}";
	fi
fi

#set more secure default file perms
#   https://geek-university.com/linux/set-the-default-permissions-for-newly-created-files/
# normally perms default to 666; with umask of 006 == perms now default to 660
umask 006


export PATH="${PATH}";

