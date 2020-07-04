

## Description

Installs Adobe Acrobat Reader v9.5.5 (which is "[the last available build for Linux](https://www.fosslinux.com/1776/how-to-install-adobe-acrobat-reader-in-ubuntu-and-linux-mint.htm)".

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/acrobat-reader
./install-acrobat-reader.sh
```

## Status

Last tested : 2020, July 02 with Adobe Acrobat Reader v9.5.5

Last status : working (Mint 20.0 Cinnamon x64 in Virtualbox)

