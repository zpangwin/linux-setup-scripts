
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

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Jul 03  | Mint 20.0 Cinnamon x64  | Virtualbox     | VS Codium 1.46.1 | Working |

