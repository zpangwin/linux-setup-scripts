# Waterfox Classic

This script is to automate installing / updating Waterfox Classic on Linux. If there is ever an official PPA / central repo package then that should take precedence over my script. This was written to make the install process less manual.

If you prefer to install manually, then you can download the official binaries from [waterfox.net](https://www.waterfox.net/).

# Description:

This script automates the installation process of Waterfox. It adds [hawkeye116477's unofficial Ubuntu PPA hosted on opensuse.org](http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/xUbuntu_18.04) and installs waterfox kde version from there. Since [hawkeye116477 is a Waterfox developer](https://github.com/MrAlex94/Waterfox/commits?author=hawkeye116477) but the PPA is not listed on the [official WF site](https://www.waterfox.net/) / [WF github page](https://github.com/MrAlex94/Waterfox), I feel this is a pretty trustworthy source but likely just a **personal** package archive.

## What does the script add?:

**install-waterfox-from-unofficial-dev-ppa.sh**

* New repo source at `/etc/apt/sources.list.d/waterfox-unofficial.list`
* symlink at `/usr/bin/waterfox` (points to `/usr/bin/waterfox-classic`)
* symlink at `/usr/bin/waterfox-classic` (points to `/usr/lib/waterfox-classic/waterfox-classic-bin.sh`)
* The `waterfox-kpe` package is installed under `/usr/lib/waterfox-classic/` (not sure if it adds additional stuff)
* The `waterfox-kpe` package requires a locale so package `waterfox-locale-en` is also installed by the script
* Regular WF shortcut at: `/usr/share/applications/waterfox-classic.desktop` (this is added by `waterfox-kpe`)

**extras/add-wf-one-click-private-browsing-icon.sh**

* Private browsing icon at: `/usr/share/icons/private-browsing.png`
* One-click Private browsing shortcut at: `/usr/share/applications/waterfox-private.desktop`

## How to use this script:

** Install waterfox from PPA**

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/unofficial-waterfox-classic
./install-waterfox-from-unofficial-dev-ppa.sh
```

## Status

| Script                                      | Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build   | Status  |
| ------------------------------------------- | ------------- | ------------------------| -------------- | ---------------------------- | ------- |
| install-waterfox-from-unofficial-dev-ppa.sh | 2020, Feb 25  | Mint 19.3 Cinnamon x64  | Baremetal     | Waterfox 2020.02.1 KDE Plasma Edition | Working |
| add-wf-one-click-private-browsing-icon.sh   | 2020, Feb 25  | Mint 19.3 Cinnamon x64  | Baremetal     | Waterfox 2020.02.1 KDE Plasma Edition | Working |
| remove-waterfox-from-unofficial-dev-ppa.sh  | 2020, Feb 25  | Mint 19.3 Cinnamon x64  | Baremetal     | Waterfox 2020.02.1 KDE Plasma Edition | Working |
