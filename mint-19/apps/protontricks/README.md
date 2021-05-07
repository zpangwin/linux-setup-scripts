
## Description

This is a utility to assist with gaming on Steam.

If you are familiar with winetricks and how it provides a simplified CLI/GUI wrapper for common wine settings/dependencies, protontricks serves a similar function for Proton. If you are unfamiliar with Proton, it is a highly customized wine wrapper created and maintained by Steam for the purpose of running Windows games on Linux. Proton has significantly better support for Steam games and contributes to the upstream wine project.

The script uses python3's pip utility to install, as per the instructions on the official [github repo](https://github.com/Matoking/protontricks).

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;

# requires wine to be installed first
cd linux-setup-scripts/mint-20.x/apps/wine-staging

# change from wine-staging folder to protontricks folder
# equivalent to:	cd linux-setup-scripts/mint-20.x/apps/protontricks
cd ../protontricks

# install protontricks
./install-protontricks.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build  | Status  |
| ------------- | ------------------------| -------------- | --------------------------- | ------- |
| |   |      |       | Needs Retest\* |


\* *Note: The installation will fail if you have not yet installed wine.*
