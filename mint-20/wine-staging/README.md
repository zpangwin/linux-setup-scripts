
## Script Purpose

This installs the latest wine-staging from winehq. As of Mint 20.x/Ubuntu 20.x, libfaudio is now in the central repository and no longer requires a second PPA to get a version that will work with wine-staging.

If you prefer to manually install wine staging, you can visit [winehg.org](https://wiki.winehq.org/Download) for the official binaries or follow [their instructions for adding the official PPA](https://wiki.winehq.org/Ubuntu).

## Issues Solved (Hacks and Workarounds)

1. Under Mint 19.x/Ubuntu 18.x, no libfaudio package exists in the central repos and you will end up with broken packages if you try to install. Previously (under Mint 19.x/Ubuntu 18.x), this was solved by adding a private repository source for the libfaudio and installing it prior to installing wine-staging. In Mint 20.x/Ubuntu 20.x, libfaudio now exists in the central repos even on a fresh, vanilla install so this workaround is no longer required/used.

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
| 2020, Jul 04  | Mint 20.0 Cinnamon x64  | Virtualbox     | wine-5.11 (Staging)                       | Working |
| 2020, Jul 04  | Mint 20.0 Cinnamon x64  | Virtualbox     | winetricks 20200412-next                  | Working |

