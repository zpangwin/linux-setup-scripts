
## Script Purpose

This installs the latest wine-staging from winehq and its dependency, libfaudio. As of last check, libfaudio is not in the central repository and requires a second PPA to get a version that will work with wine-staging.

If you prefer to manually install wine staging, you can visit [winehg.org](https://wiki.winehq.org/Download) for the official binaries or follow [their instructions for adding the official PPA](https://wiki.winehq.org/Ubuntu). If you are sticking with Wine-stable this may not cause any issues (I haven't tested the vanilla install experience in awhile); but if you are experiencing issues with getting libfaudio and wine-staging to play nice, that's what this script was written to fix.

I have confirmed that the script works fine for installing wine-staging + libfaudio on a fresh install of Mint 19.3 Cinnamon but have heard that in some situations, the system may still have dependency issues that the script does not currently fix.

## What does the script do

* Adds signing key for [winehg.org](https://wiki.winehq.org/)
* Adds signing key for [opensuse.org wine libfaudio Ubuntu builds](https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04) (this info came from [winehq](https://forum.winehq.org/viewtopic.php?f=8&t=32192) [forums](https://forum.winehq.org/viewtopic.php?f=8&t=32545)).
* Adds winehq PPA source
* Adds opensuse.org wine libfaudio PPA source
* Adds x86 support (i386) if not already present
* Attempts to resolve any libfaudio / wine circular-dependency issues by force purging them from system with dpkg
* Installs libfaudio dependency
* Installs fonts-wine libwine winehq-staging
* Installs the [latest winetricks from github](https://github.com/Winetricks/winetricks)


## To use this script:

This script depends on functions in ../functions.sh; the easiest way to take care of those is to just clone the project and run the script from a directory. Alternately, if you know how to edit scripts you can copy the required functions into the script (but I don't support that process).

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/wine-staging
./install-from-winehq-repo.sh
```

Last tested : Feb 2020 with TestViewer 15
Last status : working (Mint 19.3 Cinnamon x64)


