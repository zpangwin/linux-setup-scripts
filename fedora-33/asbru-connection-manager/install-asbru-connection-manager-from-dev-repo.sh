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

#	https://www.asbru-cm.net/
#
# 2020-Mar-01: New process is to download install script from them
# and run it. When reviewing install script code, it appeared to
# detect (rpm-based) OS and install as a REPO rather than just
# installing a single version of the app with no update mechanism

curl -1sLf 'https://dl.cloudsmith.io/public/asbru-cm/release/cfg/setup/bash.rpm.sh' | sudo -E bash;
sudo dnf install -y asbru-cm;

# Prevent issue where non-root users get prompted by dnf to download GPG key during query operations
# such as 'dnf search', 'dnf list', and 'dnf deplist' among others
# this can be resolved by fixing bad permissions under /var/cache/dnf
sudo find /var/cache/dnf -type d -iregex '.*asbru.*' -not \( -perm /o+r -perm /o+x -perm /g+r -perm /g+x \) -exec chmod 755 "{}" \;;
sudo find /var/cache/dnf -type f -iregex '.*asbru.*' -not \( -perm /o+r -perm /g+r \) -exec chmod 644 "{}" \;;


