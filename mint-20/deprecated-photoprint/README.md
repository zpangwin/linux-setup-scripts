
## Description

With Ubuntu 20, photoprint was removed from central repos.

This downloads old an copy of the DEB file and installs it. In the process, you may end up with deprecated libraries on your system.

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/deprecated-photoprint
./install-photoprint-from-old-repos.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Aug 15  | Mint 20.0 Cinnamon x64  | Virtualbox     | PhotoPrint 0.4.2-pre2 | Working |


