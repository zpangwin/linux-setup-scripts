#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

if [[ "" == "${USER_AGENT}" ]]; then
	USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36";
fi

# get the sudo prompt out of the way up front
sudo ls -acl 2>/dev/null >/dev/null;

# first install zulucrypt: it is fully compatible with veracrypt volumes and will work
# as a nice fail-safe if veracrypt runs into any build errors or other issues
#
#	https://mhogomchungu.github.io/zuluCrypt/
#
#	https://www.linuxquestions.org/questions/linux-newbie-8/veracrypt-vs-zulucypt-4175612942/
#	-> this covers difference between the two
#	-> basically zulucrypt is GPL and can read and create veracrypt and truecrypt volumes
#		(as well as several others) but it is LINUX ONLY. Whereas veracrypt has a license that
#		prevents it from being included in many distros (like Fedora and Debian), and
#		supports Windows/Linux/Mac + RaspPi Linux. Having both shouldn't hurt anything
#		and
#
sudo dnf install --nogpgcheck --quiet -y zulucrypt zulucrypt-console zulucrypt-libs zulucrypt-doc 2>/dev/null >/dev/null;

#
#	https://www.addictivetips.com/ubuntu-linux-tips/use-veracrypt-on-linux/
#
#	Fedora
#		sudo dnf copr enable scx/veracrypt
#		sudo dnf install veracrypt.x86_64 -y
#
#	OpenSUSE
#		Grab the latest version of VeraCrypt from the OBS. All curren
#		https://software.opensuse.org/package/veracrypt
#
#	Download binary releases:
#		https://www.veracrypt.fr/en/Downloads.html
#		https://veracrypt.codeplex.com/releases/view/631440
#		wget https://launchpad.net/veracrypt/trunk/1.24-update7/+download/veracrypt-1.24-Update7-setup.tar.bz2
#		or
#		wget https://launchpad.net/veracrypt/trunk/1.24-update7/+download/veracrypt-1.24-Update7-openSUSE-15-x86_64.rpm
#
#	As of May 6th, 2021 the current version for Linux is:
#		1.24-Update7 (Friday August 7, 2020)
#
#	Build from source:
#	https://github.com/veracrypt/VeraCrypt
#
# ------------------------------------------------------------------------
#	Requirements for Building VeraCrypt for Linux and Mac OS X:
#
#		GNU Make
#			-> package: make (fedora33; v: 1:4.3-2.fc33)
#		GNU C++ Compiler 4.0 or compatible
#			-> package: gcc (fedora33; v: 10.3.1-1.fc33)
#		Apple Xcode (Mac OS X only)
#			-> not applicable for linux builds
#		YASM 1.3.0 or newer (Linux only, x86/x64 architecture only)
#			-> package: yasm (fedora33; v: 1.3.0-12.fc33)
#		pkg-config
#			-> package: pkgconf-pkg-config (fedora33; v: 1.7.3-5.fc33)
#		wxWidgets 3.0 shared library and header files installed or wxWidgets 3.0 library source code (available at https://www.wxwidgets.org)
#			-> package: wxBase3 (fedora33; v: 3.0.5.1-2.fc33)
#		FUSE library and header files (available at https://github.com/libfuse/libfuse and https://osxfuse.github.io/)
#			-> based on https://osxfuse.github.io description the above should say "OR" instead of "libfuse and osxfuse"
#			-> as the name implies, osxfuse appears to be mac-only so shouldn't be needed for linux build
#			-> assuming we only need libfuse
#			best guess, we want these:
#				fuse3.x86_64 : File System in Userspace (FUSE) v3 utilities
#				fuse3-devel.i686 : File System in Userspace (FUSE) v3 devel files
#				fuse3-devel.x86_64 : File System in Userspace (FUSE) v3 devel files
#				fuse3-libs.x86_64 : File System in Userspace (FUSE) v3 libraries
#				fuse3-libs.i686 : File System in Userspace (FUSE) v3 libraries
#			-> fuse3 = 3.9.4-1.fc33
# ------------------------------------------------------------------------

# I don't see anywhere that it specifically says to get 32-bit or 64-bit header
# files so I am downloading both package sets to ensure we're covered either way.
YASM_PACKAGES="yasm yasm-devel.i686 yasm-devel.x86_64";
PKGCONF_PACKAGES="pkgconf-pkg-config.x86_64 pkgconf-pkg-config.i686";
WX_PACKAGES="wxBase3.x86_64 wxBase3.i686 wxBase-devel.i686 wxBase-devel.x86_64 wxBase3-devel.i686 wxBase3-devel.x86_64 wxGTK-devel.i686 wxGTK-devel.x86_64 wxGTK3-devel.i686 wxGTK3-devel.x86_64";
FUSE_PACKAGES="fuse-devel.x86_64 fuse-devel.i686 fuse3 fuse3-devel.i686 fuse3-devel.x86_64 fuse3-libs.x86_64 fuse3-libs.i686";

BUILD_DEPENDS="make cmake gcc ${YASM_PACKAGES} ${PKGCONF_PACKAGES} ${WX_PACKAGES} ${FUSE_PACKAGES}"
sudo dnf install --nogpgcheck --quiet -y ${BUILD_DEPENDS} 2>/dev/null >/dev/null;


echo "E: NOT IMPLEMENTED";
exit -3;

startingDir="$(pwd)";
tempDir=$(mktemp -d '/tmp/XXXX');
cd "${tempDir}";

git clone https://github.com/veracrypt/VeraCrypt;

# probably not needed since we installed the packages above but better safe than sorry...
git clone https://github.com/libfuse/libfuse;
git clone https://github.com/wxWidgets/wxWidgets;

# ------------------------------------------------------------------------
# FROM:
#		https://github.com/veracrypt/VeraCrypt
# ------------------------------------------------------------------------
# Instructions for Building VeraCrypt for Linux and Mac OS X:
#
#	1. Change the current directory to the root of the VeraCrypt source code.
#	2. If you have no wxWidgets shared library installed, run the following command to configure the
#		wxWidgets static library for VeraCrypt and to build it:
#
#			make WXSTATIC=1 WX_ROOT=/usr/src/wxWidgets wxbuild
#
#		The variable WX_ROOT must point to the location of the source code of the wxWidgets library.
#		Output files will be placed in the './wxrelease/' directory.
#
#	3. To build VeraCrypt, run the following command:
#
#			make
#
#		or if you have no wxWidgets shared library installed:
#
#			make WXSTATIC=1
#
#	4. If successful, the VeraCrypt executable should be located in the directory 'Main'.
#
#		By default, a universal executable supporting both graphical and text user interface
#		(through the switch --text) is built. On Linux, a console-only executable, which requires
#		no GUI library, can be built using the 'NOGUI' parameter:
#
#			make NOGUI=1 WXSTATIC=1 WX_ROOT=/usr/src/wxWidgets wxbuild
#			make NOGUI=1 WXSTATIC=1
#
# ------------------------------------------------------------------------

#	1. Change the current directory to the root of the VeraCrypt source code.
#	-> apparently they mean 'VeraCrypt/src' not 'VeraCrypt'
#	-> as if you try the following, you'll get an error:
#			$ cd VeraCrypt
#			$ make
#			make: *** No targets specified and no makefile found.  Stop.
cd VeraCrypt/src


# 2. -> since we DO have wxWidgets installed, shouldn't have to do this step...

#	3. To build VeraCrypt, run the following command:
make

# ------------------------------------------------------------------------
# first try:
# ------------------------------------------------------------------------
# $ make
#	FuseService.cpp:16:10: fatal error: fuse.h: No such file or directory
#   16 | #include <fuse.h>
#      |          ^~~~~~~~
#
#	-> installed fuse-devel.x86_64 fuse-devel.i686

# ------------------------------------------------------------------------
# second try:
# ------------------------------------------------------------------------
# $ make
#	SystemPrecompiled.h:13:10: fatal error: wx/wx.h: No such file or directory
#   13 | #include <wx/wx.h>
#      |          ^~~~~~~~~
#compilation terminated.
#
#	-> after running:
#	$ dnf search wx|grep devel|grep -Pv 'ming|GTK|golang|mathgl|sqlite|pdf|svg'
#	wxBase-devel.i686 : Development files for the wxBase3 library
#	wxBase-devel.x86_64 : Development files for the wxBase3 library
#	wxBase3-devel.i686 : Development files for the wxBase3 library
#	wxBase3-devel.x86_64 : Development files for the wxBase3 library
#
#	-> i'm seeing that the bxBase packages have exEdigets 3 in the description too
#
#	-> installed wxBase-devel.i686 wxBase-devel.x86_64 wxBase3-devel.i686 wxBase3-devel.x86_64

# ------------------------------------------------------------------------
# third try:
# ------------------------------------------------------------------------
# $ make
#	Precompiling SystemPrecompiled.h
#	/bin/sh: -c: line 0: unexpected EOF while looking for matching `''
#	/bin/sh: -c: line 1: syntax error: unexpected end of file
#	make[1]: *** [/tmp/DgZk/VeraCrypt/src/Build/Include/Makefile.inc:50: SystemPrecompiled.h.gch] Error 1
#	make: *** [Makefile:423: all] Error 2
#
#	-> https://github.com/veracrypt/VeraCrypt/issues/221
#	-> https://readme.phys.ethz.ch/linux/build_veracrypt_from_source/
#	-> https://randomgooby.wordpress.com/2015/03/02/quick-tip-veracrypt-on-a-raspberry-pi-2/
#		-> sounds like I should follow step #2 (build wxWidgets instead of using system files) after all
#	-> https://github.com/veracrypt/VeraCrypt/issues/87
#		-> someone else mentions not being able to build on fedora 31 on Jan 25, 2020
#
#	-> https://github.com/veracrypt/VeraCrypt/issues/357
#	-> warnings to ignore
#
#	-> https://github.com/veracrypt/VeraCrypt/issues/325
#	->	Nevermind, wrong wx version installed on Fedora 28. Proper versions are:
#		sudo dnf install wxGTK3\*
#
#	-> https://stackoverflow.com/questions/29464583/how-to-make-gcc-not-generate-h-gch-files
#		Files ending in .gch are precompiled headers - header files which have been pre-compiled in
#		order to reduce compilation time when you (re)compile your main program.
#
# -> based on the comment from issue # 325, going to try the easy fix of installing more shit first
#
#	$ dnf search wx|grep -P '^wx.*GTK.*devel'
#	wxGTK-devel.i686 : Development files for the wxGTK library
#	wxGTK-devel.x86_64 : Development files for the wxGTK library
#	wxGTK3-devel.i686 : Development files for the wxGTK3 library
#	wxGTK3-devel.x86_64 : Development files for the wxGTK3 library
#
#	-> ++ wxGTK-devel.i686 wxGTK-devel.x86_64 wxGTK3-devel.i686 wxGTK3-devel.x86_64
#

# ------------------------------------------------------------------------
# fourth try:
# ------------------------------------------------------------------------
# SUCCESS ! No build errors (oly 2 warnings).
#	4. If successful, the VeraCrypt executable should be located in the directory 'Main'.
# -> yup

# below were yanked from existing install on LM19
if [[ -f "${SCRIPT_DIR}/veracrypt.desktop" ]]; then
	sudo cp -a --no-preserve=ownership -t /usr/share/applications "${SCRIPT_DIR}/veracrypt.desktop";
	sudo chown root:root "/usr/share/applications/veracrypt.desktop";
	sudo chmod 644 "/usr/share/applications/veracrypt.desktop";
fi

if [[ -f "${SCRIPT_DIR}/veracrypt.xpm" ]]; then
	if [[ ! -d /usr/share/pixmaps ]]; then
		sudo mkdir -p -m 755 /usr/share/pixmaps;
	fi
	sudo cp -a --no-preserve=ownership -t /usr/share/pixmaps "${SCRIPT_DIR}/veracrypt.xpm";
	sudo chown root:root "/usr/share/pixmaps/veracrypt.xpm";
	sudo chmod 644 "/usr/share/pixmaps/veracrypt.xpm";
fi

# return to starting dir
cd "${startingDir}";
