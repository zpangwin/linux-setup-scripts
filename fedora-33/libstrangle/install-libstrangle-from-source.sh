#!/bin/bash

# change to wherever you prefer to download code
BASE_DIR="/tmp/LibStrangleInstall"
mkdir -p "${BASE_DIR}"
cd "${BASE_DIR}"

# if you want to just use a precompiled version that's fine too:
if [[ ! -d "${BASE_DIR}/libstrangle" ]]; then
	git clone git@gitlab.com:torkel104/libstrangle.git;
else
	git -C "${BASE_DIR}/libstrangle" pull;
fi

if [[ ! -f /usr/include/gnu/stubs-32.h ]]; then
	# libstrangle requires 32-bit build dependencies
	# otherwise you will get an error about:
	#
	#		/usr/include/gnu/stubs.h:7:11: fatal error: gnu/stubs-32.h: No such file or directory
	#		    7 | # include <gnu/stubs-32.h>
	#		      |           ^~~~~~~~~~~~~~~~
	#
	# See:
	#	https://stackoverflow.com/questions/7412548/error-gnu-stubs-32-h-no-such-file-or-directory-while-compiling-nachos-source
	#
	if [[ -f /usr/bin/dnf ]]; then
		echo 'Installing 32-bit build dependencies (for libstrangle) ...';
		sudo dnf install -y glibc-devel.i686 glibc-devel.x86_64;

	elif [[ -f /usr/bin/apt-get ]]; then
		echo 'Installing 32-bit build dependencies (for libstrangle) ...';
		sudo apt-get install -y libc6-dev-i386;
	fi
fi

# Build and install LibStrangle
# Note: this one won't auto install dependencies; you need to read the README.md file
# and follow their instructions. Package names/etc will be distro-specific
#
# Depends:
#   debian-based: sudo apt-get install -y gcc-multilib g++-multilib libx11-dev mesa-common-dev
#   fedora: sudo dnf install -y gcc.x86_64 glibc-devel.x86_64 glibc-devel.i686
#   opensuse (untested): sudo zypper install -y glibc-devel-32bit gcc gcc-32bit ?
#
cd libstrangle
make
if [[ "0" != "$?" ]]; then
	echo "E: Detected errors during libstrangle build; aborting ...";
	exit -1;
fi

sudo make install
if [[ "0" != "$?" ]]; then
	echo "E: Detected during libstrangle install ...";
	exit -1;
fi
