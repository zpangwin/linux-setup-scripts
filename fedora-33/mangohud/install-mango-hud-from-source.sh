#!/bin/bash

# change to wherever you prefer to download code
BASE_DIR="/tmp/MangoHudInstall"
mkdir -p "${BASE_DIR}"
cd "${BASE_DIR}"

# if you want to just use a precompiled version that's fine too:
#   tar.gz: https://github.com/flightlessmango/MangoHud/releases
#   fedora: sudo dnf install -y mangohud
#   ubuntu: https://launchpad.net/~flexiondotorg/+archive/ubuntu/mangohud

# otherwise, clone the mangohud and libstrangle repos
if [[ ! -d "${BASE_DIR}/MangoHud" ]]; then
	git clone git@github.com:flightlessmango/MangoHud.git;
else
	git -C "${BASE_DIR}/MangoHud" pull;
fi

# build and install MangeHud
# script will prompt you for missing depends; you just have to type 'y' and enter
cd MangoHud
yes y | ./build.sh build
if [[ "0" != "$?" ]]; then
	echo "E: Detected errors during MangoHud build; aborting ...";
	exit -1;
fi

yes y | ./build.sh package
if [[ "0" != "$?" ]]; then
	echo "E: Detected errors during MangoHud packaging; aborting ...";
	exit -1;
fi

yes y | ./build.sh install
if [[ "0" != "$?" ]]; then
	echo "E: Detected during MangoHud install ...";
	exit -1;
fi
