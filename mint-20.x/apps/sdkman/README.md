

## Description

SDKMAN is a tool for managing parallel versions of multiple Software Development Kits on most Unix based systems. It provides a convenient Command Line Interface (CLI) and API for installing, switching, removing and listing Candidates.

[Official Site](https://sdkman.io/)

This script simply automates the installation steps.

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/sdkman
./install-sdkman.sh
```

## Status

Last tested : 2020, July 03 with $(sdk version)='SDKMAN 5.8.3+506'

Last status : working (Mint 20.0 Cinnamon x64 in Virtualbox)

