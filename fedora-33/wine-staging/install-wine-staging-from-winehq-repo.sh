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

sudo dnf erase -y wine 2>/dev/null;

# add repo source for winehq
echo "Adding WineHQ source ... ";
sudo dnf install -y dnf-plugins-core;
sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/33/winehq.repo;

# install wine-staging
echo "Installing winehq-staging ... ";
sudo dnf install -y winehq-staging;

# Prevent issue where non-root users get prompted by dnf to download GPG key during query operations
# such as 'dnf search', 'dnf list', and 'dnf deplist' among others
# this can be resolved by fixing bad permissions under /var/cache/dnf
sudo find /var/cache/dnf -type d -iregex '.*winehq.*' -not \( -perm /o+r -perm /o+x -perm /g+r -perm /g+x \) -exec chmod 755 "{}" \;;
sudo find /var/cache/dnf -type f -iregex '.*winehq.*' -not \( -perm /o+r -perm /g+r \) -exec chmod 644 "{}" \;;
