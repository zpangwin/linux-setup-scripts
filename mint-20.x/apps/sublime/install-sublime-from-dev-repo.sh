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

nemoActionOnly="false";
arg1="$1";
if [[ $arg1 =~ ^\-\-*nemo\-?only ]]; then
	nemoActionOnly="true";
fi

if [[ "true" != "${nemoActionOnly}" ]]; then
	# add key
	echo "Adding key ...";
	wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -;

	# add repo
	echo "Adding custom repo source ...";
	addCustomSource sublimetext deb https://download.sublimetext.com/ apt/stable/

	echo "Updating apt's local cache ...";
	sudo apt-get update 2>&1 >/dev/null;

	echo "Installing sublime ...";
	sudo apt-get install -y --install-recommends sublime-text;

	# Create symlinks for sublime
	if [[ -f /opt/sublime_text/sublime_text ]]; then
	    ln -s /opt/sublime_text/sublime_text /usr/bin/sublime;
	    ln -s /opt/sublime_text/sublime_text /usr/bin/sublime-text;
	    ln -s /opt/sublime_text/sublime_text /usr/bin/sublime_text;
	fi
fi

if [[ "" != "${SCRIPT_DIR}" ]]; then
	hasMissingFiles="false";
	if [[ ! -f "${SCRIPT_DIR}/usr/share/nemo/actions/edit-with-sublime.nemo_action" ]]; then
		hasMissingFiles="true";
	elif [[ ! -f "${SCRIPT_DIR}/usr/share/nemo/actions/scripts/multi-file-handler.sh" ]]; then
		hasMissingFiles="true";
	fi

	if [[ "false" == "${hasMissingFiles}" ]]; then
		sudo cp -a -t "/usr/share/nemo/actions" "${SCRIPT_DIR}/usr/share/nemo/actions"/*;

		sudo chown root:root "/usr/share/nemo/actions/edit-with-sublime.nemo_action";
		sudo chmod 644 "/usr/share/nemo/actions/edit-with-sublime.nemo_action";

		sudo chown root:root "/usr/share/nemo/actions/scripts";
		sudo chmod 655 "/usr/share/nemo/actions/scripts";

		sudo chown root:root "/usr/share/nemo/actions/scripts/multi-file-handler.sh";
		sudo chmod 755 "/usr/share/nemo/actions/scripts/multi-file-handler.sh";
	fi
fi

