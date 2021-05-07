
## Description

This script installs the latest GIMP from the [unofficial PPA from ubuntuhandbook.org](https://launchpad.net/~ubuntuhandbook1/+archive/ubuntu/gimp). You can read more about this on ubuntuhandbook.org's [article on installing gimp 2.10](http://ubuntuhandbook.org/index.php/2020/07/ppa-install-gimp-2-10-20-ubuntu-20-04/)

If you don't need the most recent version and are not interested in any plugins/tweaks, then you can just install it from your central repo using: `sudo apt install -y gimp`. In my testing on Linux Mint 19.3 during 2020 Aug, the central repo installed gimp 2.8.22; using the unofficial ppa, it installed gimp 2.10

## Script Details

* Adds unofficial PPA if you don't haven't it added already
* Install the latest version
*

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/unofficial-gimp
./install-gimp-from-unofficial-repo.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build   | Status  |
| ------------- | ------------------------| -------------- | ---------------------------- | ------- |
| 2020, Aug 12  | Mint 19.3 Cinnamon x64  | Baremetal      | GIMP 2.10                    | Working |
| N/A  | Mint 20.0 Cinnamon x64  | ??      | GIMP 2.10                    | Needs Retest |


