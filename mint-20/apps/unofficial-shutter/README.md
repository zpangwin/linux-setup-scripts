
## Description

Shutter is an open-source GUI-based screenshot app. One feature it has that many other screenshot applications lack is that it allows you to setup a naming template with timestamps and output folder and have screenshots automatically saved to the preconfigured folder.

Shutter was removed from Ubuntu 20 central repository sources.

This script utilizes the Linux Uprising PPA to install Shutter.


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/unofficial-shutter
./install-from-shutter-from-unofficial-ppa.sh
```

## Status


| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build   | Status  |
| ------------- | ------------------------| -------------- | ---------------------------- | ------- |
| 2020, Jul 05  | Mint 20.0 Cinnamon x64  | Virtualbox     | Shutter v0.94.3 (Rev. 1306)  | Working |



