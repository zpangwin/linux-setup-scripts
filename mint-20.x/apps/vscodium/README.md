
## Description

You may be familiar with Microsoft's Visual Studio Code (the editor, not the full VS IDE that comes with a compiler); also known as "vscode". Visual Studio Code is open source (MIT-licensed), but this not-FLOSS license and the app also contains telemetry/tracking.

VS Codium is a project that allows individuals to re-build Microsoft's code without the telemetry.

VS Codium - [Official Site](https://vscodium.com/) | [Github Repo](https://github.com/VSCodium/vscodium)

This script uses the paulcarroty repository mentioned on the official site to automate the install process and integrate future updates into the system Update Manager.

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/vscodium
./install-vscodium.sh
```

## Status

Last tested : 2020, July 03 with VS Codium v1.46.1

```
Version: 1.46.1
Commit: cd9ea6488829f560dc949a8b2fb789f3cdc05f5d
Date: 2020-06-19T10:53:55.306Z
Electron: 7.3.1
Chrome: 78.0.3904.130
Node.js: 12.8.1
V8: 7.8.279.23-electron.0
OS: Linux x64 5.4.0-26-generic
```

Last status : working (Mint 20.0 Cinnamon x64 in Virtualbox)

