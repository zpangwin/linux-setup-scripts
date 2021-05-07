
## Description

[Sound Switch Indicator](https://www.omgubuntu.co.uk/2016/09/indicator-sound-switcher-makes-switching-audio-devices-ubuntu-snap) aka the "indicator-sound-switcher" package is a sound input/output selector application for Linux.

It shows an icon in the indicator area or the system tray (whatever is available in your desktop environment). The icon's menu allows you to switch the current sound input and output (i.e. source ports and sink ports in PulseAudio's terms, respectively) with just two clicks.

[Homepage](https://yktoo.com/en/software/sound-switcher-indicator/) | [Github](https://github.com/yktoo/indicator-sound-switcher)


This script utilizes the LaunchPad PPA to install Sound Switch Indicator.


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/sound-switcher-indicator
./install-sound-switcher-indicator-from-ppa.sh
```

## Status


| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                   | Status  |
| ------------- | ------------------------| -------------- | -------------------------------------------- | ------- |
| 2020, Jul 06  | Mint 20.0 Cinnamon x64  | Virtualbox     | Sound Switch Indicator v2.3.4                | Working |



