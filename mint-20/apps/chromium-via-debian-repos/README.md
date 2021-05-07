
## Description

This script installs the chromium from the Debian repos so you can have chromium without resorting to snaps.

This script is automating the steps described in the [Terminal Tricks youtube video "Let's Install Chromium in Ubuntu Without Snap"](https://www.youtube.com/watch?v=Gk2QH2PocA8); manual instructions can also be found in the [Terminal Tricks github page](https://github.com/ayitsleo/terminaltricks/blob/master/apt-pinning-chromium/README.md) if you don't want to watch the video.


## Script Details

* Adds debian repos for chromium only
* Install the latest version of chromium

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/chromium-via-debian-repos
./install-chromium-from-debian-repos.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| N/A  | Mint 20.0 Cinnamon x64  | Virtualbox     |  | Needs Retest |

