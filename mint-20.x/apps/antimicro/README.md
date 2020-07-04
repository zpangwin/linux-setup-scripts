
## Description

antimicro is a graphical program used to map keyboard keys and mouse controls to a gamepad. This program is useful for playing PC games using a gamepad that do not have any form of built-in gamepad support. However, you can use this program to control any desktop application with a gamepad; on Linux, this means that your system has to be running an X environment in order to run this program.

The official page is [here](https://github.com/AntiMicro/antimicro). The Linux deb files can be downloaded from [here](https://launchpad.net/~mdeguzis/+archive/ubuntu/libregeek/+packages).

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/antimicro
./install-antimicro.sh
```

## Status

Last tested : 2020, July 02 with antimicro 2.23 x64

Last status : working (Mint 20.0 Cinnamon x64 in Virtualbox)
