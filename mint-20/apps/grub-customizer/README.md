
## Description

[Grub Customizer](https://launchpad.net/grub-customizer) is a graphical interface to configure the GRUB2/BURG settings and menuentries

This script utilizes the LaunchPad PPA to install Grub Customizer.


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/grub-customizer
./install-grub-customizer-from-ppa.sh
```

## Status


| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                   | Status  |
| ------------- | ------------------------| -------------- | -------------------------------------------- | ------- |
| 2020, Jul 06  | Mint 20.0 Cinnamon x64  | Virtualbox     | grub-customizer v5.1.0                       | Working |

