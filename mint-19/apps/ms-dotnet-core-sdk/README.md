## Description

Installs the dotnet core sdk from Microsoft repos targeting Ubuntu. These are mostly used for cross-platform C#/.NET programming on Linux. However, it might also be a dependency for some applications which have been coded with .NET core.

This specific install targets Mint 20 (Ubuntu 20)

See

https://stackoverflow.com/questions/52737293/install-dotnet-core-on-linux-mint-19
https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-1804

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/ms-dotnet-core-sdk
./install-all-versions-of-dotnet-core-sdk.sh

# or v2.1 only
./dotnet-core-sdk-2.1-only.sh

# or v3.1 only
./dotnet-core-sdk-3.1-only.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
|   |   |      | dotnet-sdk-2.1,dotnet-sdk-3.1,all | Needs Retest |
