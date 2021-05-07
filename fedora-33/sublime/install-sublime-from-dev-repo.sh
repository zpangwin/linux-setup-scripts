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

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

nemoActionOnly="false";
arg1="$1";
if [[ $arg1 =~ ^\-\-*nemo\-?only ]]; then
	nemoActionOnly="true";
fi

if [[ "true" != "${nemoActionOnly}" ]]; then
	# add key
	echo "Adding key ...";
	sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg;

	# add repo
	echo "Adding custom repo source ...";
	sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo;

	echo "Installing sublime ...";
	sudo dnf install -y sublime-text;

	# Create symlinks for sublime
	if [[ -f /opt/sublime_text/sublime_text ]]; then
		sudo ln -s /opt/sublime_text/sublime_text /usr/bin/sublime;
		sudo ln -s /opt/sublime_text/sublime_text /usr/bin/sublime-text;
		sudo ln -s /opt/sublime_text/sublime_text /usr/bin/sublime_text;
	fi
fi

if [[ "" != "${SCRIPT_DIR}" ]]; then
	hasMissingFiles="false";
	if [[ ! -f "${SCRIPT_DIR}/usr/share/nemo/actions/edit-with-sublime.nemo_action" ]]; then
		hasMissingFiles="true";
	fi

	if [[ "false" == "${hasMissingFiles}" ]]; then
		sudo cp -a -t "/usr/share/nemo/actions" "${SCRIPT_DIR}/usr/share/nemo/actions"/*;
		sudo chown root:root "/usr/share/nemo/actions/edit-with-sublime.nemo_action";
		sudo chmod 644 "/usr/share/nemo/actions/edit-with-sublime.nemo_action";
		isSELinuxEnabled=$(sestatus 2>/dev/null|grep -Pci 'SELinux status:\s*enabled');
		if [[ 1 == $isSELinuxEnabled && 1 == $(which restorecon 2>/dev/null|wc -l) ]]; then
			echo "Restoring SELinux Filecontext...";
			sudo restorecon "/usr/share/nemo/actions/edit-with-sublime.nemo_action";
			echo "SELinux filecontext restored.";
		fi
	fi

	mkdir -p "${HOME}/.config/sublime-text-3/Packages/User" 2>/dev/null;

	hasExistingUserKeymap="false";
	if [[ -f "${HOME}/.config/sublime-text-3/Packages/User/Default (Linux).sublime-keymap" ]]; then
		hasExistingUserKeymap="true";
	fi
	if [[ "false" == "${hasExistingUserKeymap}" && -f "${SCRIPT_DIR}/.config/sublime-text-3/Packages/User/Default (Linux).sublime-keymap" ]]; then
		cp -a -t "${HOME}/.config/sublime-text-3/Packages/User" "${SCRIPT_DIR}/.config/sublime-text-3/Packages/User/Default (Linux).sublime-keymap";
	fi

	hasExistingUserConfig="false";
	if [[ -f "${HOME}/.config/sublime-text-3/Packages/User/Preferences.sublime-settings" ]]; then
		hasExistingUserConfig="true";
	fi
	if [[ "false" == "${hasExistingUserConfig}" && -f "${SCRIPT_DIR}/.config/sublime-text-3/Packages/User/Preferences.sublime-settings" ]]; then
		cp -a -t "${HOME}/.config/sublime-text-3/Packages/User" "${SCRIPT_DIR}/.config/sublime-text-3/Packages/User/Preferences.sublime-settings";
	fi
fi
