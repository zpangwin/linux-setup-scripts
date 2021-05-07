
## Description

This installs [Vivaldi](https://vivaldi.com/), a Chromium-based browser from official sources.

Official/manual instructions for adding to rep (e.g. automatic updates) can be found [here](https://help.vivaldi.com/article/manual-setup-vivaldi-linux-repositories/) or the [non-updating manual install instructions](https://help.vivaldi.com/article/install-the-vivaldi-browser/#linux).

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/vivaldi
./install-vivaldi.sh
```

## Status

Script was installing Brave ok as of June 2020.

