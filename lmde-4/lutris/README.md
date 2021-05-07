

## Description

Lutris is a FOSS (free and open source) game manager for Linux-based operating systems developed and maintained by Mathieu Comandon and the community

Lutris has one-click installation available for hundreds of games on its website, and also integrates with the Steam website. Installer scripts are available for some difficult to install WINE games including League of Legends.

Lutris - [Official Site](https://lutris.net/) | main [Github Repo](https://github.com/lutris/lutris)

This script automates the install of Lutris from ppa:lutris-team/lutris so that you will continue to get updates via your system's Update Manager.

## Prerequisites

1. Script expects you to have wine staging installed already. This can be done easily using my wine-staging setup script.
2. If you have an NVIDIA card, script expects you to have installed proprietary drivers AND Vulkan. It will prompt you.

## Potential Issues

* Probably needs to be retested on fresh installs for machines running Nvidia/AMD GPUs.
* For Nvidia, should probably add a section noting *how* to install proprietary drivers AND Vulkan to the README.

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/lutris
./install-lutris.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Jul 03  | Mint 20.0 Cinnamon x64  | Virtualbox     | Lutris v0.5.6 | Working\* |

\* Only superficial application launch was tested. More involved testing (installing runners/games) was not done in this test due to limitations of virtual machines/time.




