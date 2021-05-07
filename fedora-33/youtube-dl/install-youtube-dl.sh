#!/bin/bash

#get password prompt out of the way so that output isn't disjointed
sudo ls -acl 2>&1 >/dev/null;

# Check if already installed... version in central repo is ancient and no longer works
is_installed=$(which youtube-dl 2>/dev/null|wc -l);
if [[ "1" == "${is_installed}" ]]; then

	# Try updating to see if we have the script-based version ...
	isNonUpdatable=$(sudo youtube-dl -U);
	if [[ $isNonUpdatable =~ ^.*installed.*with.*package\ manager,\ pip,\ setup.py\ or\ a\ tarball.*$ ]]; then

		# determine how it was installed...
		target='unknown'
		if [[ '0' != "$(dnf history userinstalled|grep -c youtube-dl)" ]]; then
			target='package manager'

		elif [[ '0' != "$(pip list|grep -c youtube-dl)" ]]; then
			target='pip'
		fi

		if [[ 'pip' == "$target" ]]; then
			# system installs
			echo 'Removing pip system installs...'
			sudo pip uninstall -y youtube-dl youtube-dl-cli youtube-dl-gui;

			# user installs
			echo 'Removing pip user installs...'
			pip uninstall -y youtube-dl youtube-dl-cli youtube-dl-gui;

		elif [[ 'package manager' == "$target" ]]; then
			echo 'Removing version installed from package manager...'
			sudo dnf remove -y youtube-dl;
		else
			echo "ERROR: ${isNonUpdatable}";
			echo "Unable to determine install method. Please uninstall manually and rerun script.";
			exit;
		fi

		is_installed=$(which youtube-dl 2>/dev/null|wc -l);
		if [[ "1" == "${is_installed}" ]]; then
			echo "ERROR: ${isNonUpdatable}";
			echo "Unable to remove old youtube-dl install. Please uninstall manually and rerun script.";
			exit;
		fi
	fi
	exit;
fi

#
# https://github.com/ytdl-org/youtube-dl
#
sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl;
sudo chmod a+rx /usr/local/bin/youtube-dl;

isSELinuxEnabled=$(sestatus 2>/dev/null|grep -Pci 'SELinux status:\s*enabled');
if [[ 1 == $isSELinuxEnabled && 1 == $(which restorecon 2>/dev/null|wc -l) ]]; then
	echo "Restoring SELinux Filecontext...";
	sudo restorecon /usr/local/bin/youtube-dl;
	echo "done";
fi
