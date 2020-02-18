# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "${HOME}/bin" ] ; then
	pathHasUsrBin=$(echo "${PATH}" | grep -P "${HOME}/bin(:|\$)" | wc -l);
	if [[ "0" == "${pathHasUsrBin}" ]]; then
	    PATH="$HOME/bin:$PATH";
	fi
fi

# set PATH so it includes user's private bin if it exists
if [[ -d "${HOME}/.local/bin" ]]; then
	pathHasLocalBin=$(echo "${PATH}" | grep -P "${HOME}/.local/bin(:|\$)" | wc -l);
	if [[ "0" == "${pathHasLocalBin}" ]]; then
		PATH="${HOME}/.local/bin:${PATH}";
	fi
fi
if [[ -d "${HOME}/go" ]]; then
	export GOPATH=${HOME}/go;
	export GOBIN=${GOPATH}/bin;
	pathHasGoBin=$(echo "${PATH}" | grep -P ":${GOBIN}(:|\$)" | wc -l);
	if [[ "0" == "${pathHasGoBin}" ]]; then
		PATH="${PATH}:${GOBIN}";
	fi
fi
export PATH="${PATH}";

