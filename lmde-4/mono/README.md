## Description

This is for installing Mono under Linux. For manual instructions, see [the official instructions for adding the Mono repo](https://www.mono-project.com/download/stable/#download-lin-debian).

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/mono
./install-mono.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| N/A  | Mint 20.0 Cinnamon x64  | Virtualbox     | Mono JIT compiler version 6.10.0.104      | Retest |

