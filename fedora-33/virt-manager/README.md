
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
cd linux-setup-scripts/mint-19.3/apps/virtualbox+ext-pack
./install-latest-virtualbox.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build      | Status  |
| ------------- | ------------------------| -------------- | ------------------------------- | ------- |
| 2020, Feb ??  | Mint 19.3 Cinnamon x64  | Baremetal      | Virtualbox 6.1 | Working |

