#!/bin/bash

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

# check for chroot environment
if [[ "root" == "${USER}" && "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]; then
	# make sure folder exists
	mkdir ~/.local/bin 2>&1 >/dev/null;
fi

echo "Installing dependencies ...";
sudo dnf install -y git python3 python3-pip python3-setuptools;

echo "Installing protontricks ...";
sudo pip install protontricks;

#====================================================================================
# fix permissions bc python/pip are retarded...
#====================================================================================
# have had tons of pip installs where something like this happens:
#
#	# wtf?! why is this folder and all its subs not readable by "other" users (than root)?
# 	/usr/local/lib# l
#	total 4.0K
#	drwxrwx--x. 3 root root 4.0K Nov 30 21:37 python3.9/
#
#	/usr/local/lib/python3.9# l
#	total 4.0K
#	drwxrwx--x. 14 root root 4.0K Nov 30 21:37 site-packages/
#
#	/usr/local/lib/python3.9/site-packages# l
#	total 48K
#	drwxr-x---. 3 root root 4.0K Nov 30 21:37 colorama/
#	drwxr-x---. 2 root root 4.0K Nov 30 21:37 colorama-0.4.4.dist-info/
#	drwxrwx--x. 3 root root 4.0K Nov 30 21:37 protontricks/
#	drwxrwx--x. 2 root root 4.0K Nov 30 21:37 protontricks-1.4.2-py3.9.egg-info/
#	drwxr-x---. 3 root root 4.0K Nov 30 21:37 pyte/
#	drwxr-x---. 2 root root 4.0K Nov 30 21:37 pyte-0.8.0-py3.9.egg-info/
#	drwxr-x---. 9 root root 4.0K Nov 30 21:37 thefuck/
#	drwxr-x---. 2 root root 4.0K Nov 30 21:37 thefuck-3.30.dist-info/
#	drwxrwx--x. 3 root root 4.0K Nov 30 21:37 vdf/
#	drwxrwx--x. 2 root root 4.0K Nov 30 21:37 vdf-3.3.dist-info/
#	drwxr-x---. 4 root root 4.0K Nov 30 21:37 wcwidth/
#	drwxr-x---. 2 root root 4.0K Nov 30 21:37 wcwidth-0.2.5.dist-info/
#
#====================================================================================
sudo find /usr/local/lib -maxdepth 1 -type d -regex '/usr/local/lib/python.*' -exec chown -R root:root "{}" \;;
sudo find /usr/local/lib -type d -regex '/usr/local/lib/python.*' -exec chmod 755 "{}" \;;
sudo find /usr/local/lib -type f -regex '/usr/local/lib/python.*' -exec chmod u+rw,go+r "{}" \;;
sudo find /usr/local/lib -type f -regex '/usr/local/lib/python.*\.py' -exec chmod a+x "{}" \;;

isSELinuxEnabled=$(sestatus 2>/dev/null|grep -Pci 'SELinux status:\s*enabled');
if [[ 1 == $isSELinuxEnabled && 1 == $(which restorecon 2>/dev/null|wc -l) ]]; then
	echo "Restoring SELinux Filecontext...";

	# should be a launcher in /usr/local/bin and
	# some installed 'dist-packages' dirs, e.g.:
	#	/usr/local/lib/python3.8/dist-packages/protontricks
	#	/usr/local/lib/python3.8/dist-packages/protontricks-1.4.4.dist-info
	#
	sudo restorecon /usr/local/bin/protontricks;
	# searching this way ensures that we're covered even when the protontricks version or python version changes
	# the -R on restorecon ensures that all files that are part of the install have their filecontexts updated too
	sudo find /usr/local/lib -maxdepth 3 -type d -regex '/usr/local/lib/python.*/dist-packages/protontricks.*' \
			-exec restorecon -R "{}";
	echo "SELinux filecontext restored.";
fi
