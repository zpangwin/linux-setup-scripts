
## Description

With Ubuntu 20, fslint was removed from central repos due to reliance on deprecated python2 libraries.

This downloads old copies of the libs and installs them. In the process, you will end up with deprecated python2 libraries on your system.

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/deprecated-fslint
./install-fslint-from-old-repos.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Jul 04  | Mint 20.0 Cinnamon x64  | Virtualbox     | fslint_2.46-1_all.deb | Working |

