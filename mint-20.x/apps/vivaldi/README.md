
## Description

This installs [Vivaldi](https://vivaldi.com/), a Chromium-based browser from official sources.

Official/manual instructions for adding to rep (e.g. automatic updates) can be found [here](https://help.vivaldi.com/article/manual-setup-vivaldi-linux-repositories/) or the [non-updating manual install instructions](https://help.vivaldi.com/article/install-the-vivaldi-browser/#linux).

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/vivaldi
./install-vivaldi.sh
```

## Status

Last tested : 2020, July 02 with Vivaldi v3.1.1929.45 (Stable channel) (64-bit)

Last status : working (Mint 20.0 Cinnamon x64 in Virtualbox)
