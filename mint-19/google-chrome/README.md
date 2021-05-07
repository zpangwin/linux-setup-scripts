
## Description

This adds the official Google PPA for Chrome and installs the latest stable version.

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/google-chrome
./install-google-chrome.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Feb ??  | Mint 19.3 Cinnamon x64  | Baremetal      | Chrome v?? | Working \* |


\* There may possiblity be an issue I need to fix where the PPA gets once by the script and then the apt install of chrome blindly adds the PPA again... I don't think this occurred last time but need to confirm.

If this does happen, you will see something about duplicate sources when you run `sudo apt update`. To fix, first **MAKE BACKUPS** of and then edit the source list files under `/etc/apt/sources.list.d/` folder then `sudo apt update` to refresh/confirm errors are resolved.
