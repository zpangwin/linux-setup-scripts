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

#get sudo prompt out of the way
sudo ls -acl >/dev/null

# with Ubuntu 20, fslint is no longer available in the central repos
# workaround: manually install deb files from old packages
#	https://askubuntu.com/questions/1233710/where-is-fslint-duplicate-file-finder-for-ubuntu-20-04
#

startDir=$(pwd);
tmpDir=$(mktemp -d /tmp/XXX);
cd "${tmpDir}";

wget http://archive.ubuntu.com/ubuntu/pool/universe/p/photoprint/photoprint_0.4.2~pre2-2.5_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/main/g/gutenprint/libgutenprint2_5.2.13-2_amd64.deb

sudo apt-get install -y ./*.deb

cd "${startDir}";
