
## Script Purpose

This installs the latest wine-staging from winehq. As of Debian 11 bullseye, libfaudio is now in the central repository and no longer requires a secondary sources to get a version that will work with wine-staging. However, LMDE 4/Debian 10 buster repos do not contain libfaudio and require installing it from secondary sources.

If you prefer to manually install wine staging, you can visit [winehg.org](https://wiki.winehq.org/Download) for the official binaries or follow [their instructions for adding the official sources](https://wiki.winehq.org/Debian) and lbfaudio from unofficial sources hosted on OpenSuse's servers - see notes [here](https://www.linuxuprising.com/2019/09/how-to-install-wine-staging-development.html).

## Issues Solved (Hacks and Workarounds)

1. Under Mint 19.x/Ubuntu 18.x/LMDE4/Debian 10 buster, no libfaudio package exists in the central repos and you will end up with broken packages if you try to install. In Mint 20.x/Ubuntu 20.x/Debian 11 bullseye, libfaudio now exists in the central repos even on a fresh, vanilla install so this workaround is no longer required/used.

## What does the script do

* Adds signing key for [winehg.org](https://wiki.winehq.org/)
* Adds winehq PPA source
* Adds x86 support (i386) if not already present
* Installs fonts-wine libwine winehq-staging
* Installs the [latest winetricks from github](https://github.com/Winetricks/winetricks)

## To use this script:

This script depends on functions in ../functions.sh; the easiest way to take care of those is to just clone the project and run the script from a directory. Alternately, if you know how to edit scripts you can copy the required functions into the script (but I don't support that process).

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/wine-staging
./install-wine-staging-from-winehq-repo.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| N/A  | Mint 20.0 Cinnamon x64  | Virtualbox     | wine-5.11 (Staging)                       | Retest |
| N/A  | Mint 20.0 Cinnamon x64  | Virtualbox     | winetricks 20200412-next                  | Retest |

