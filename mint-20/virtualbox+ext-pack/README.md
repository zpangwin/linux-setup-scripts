
## Description

This installs the latest virtualbox and its associated extensions pack.

Alternately, you can get the Official (manual) installer from [virtualbox.org](https://www.virtualbox.org/wiki/Downloads)

## Script Details

* Adds the Official [virtualbox.org](https://www.virtualbox.org/) PPA to your sources per [the official instructions](https://www.virtualbox.org/wiki/Linux_Downloads)
* Determines and installs the newest version available
* Finds and downloads the corresponding extensions pack from the Virtualbox site
* Automates the install of the extensions pack

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/virtualbox+ext-pack
./install-latest-virtualbox.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build               | Status  |
| ------------- | ------------------------| -------------- | ---------------------------------------- | ------- |
| 2020, Jul 06  | Mint 20.0 Cinnamon x64  | Virtualbox     | Virtualbox 6.1.10 r138449 (Qt5.12.8)     | Working |

