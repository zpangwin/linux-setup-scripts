
## Description

This installs [Brave](https://brave.com/), a Chromium-based browser from official sources.

Official/manual instructions can be found [here](https://brave-browser.readthedocs.io/en/latest/installing-brave.html#linux)

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/brave
./install-brave.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Jul 02  | Mint 20.0 Cinnamon x64  | Virtualbox     | Brave v1.10.97 | Working |

