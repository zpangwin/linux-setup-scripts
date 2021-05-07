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

echo "Installing dependencies ...";
sudo dnf install -y python3-pip python3-setuptools python3-devtools;

echo "Installing thefuck ...";
sudo pip install thefuck;

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

if [[ -f "$HOME/.bashrc" && '0' == "$(grep -Pc '^\s*eval.*thefuck.*alias' "$HOME/.bashrc")" ]]; then
	echo 'eval "$(thefuck --alias)"' >> /etc/skel/.bashrc;
fi
if [[ -f /etc/skel/.bashrc && '0' == "$(grep -Pc '^\s*eval.*thefuck.*alias' /etc/skel/.bashrc)" ]]; then
	echo 'eval "$(thefuck --alias)"' | sudo tee -a /etc/skel/.bashrc >/dev/null;
fi

