
## Description

Installs Microsoft teams client for Linux.

*Note: I don't generally use MS Teams. If the link breaks, let me know.*

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/ms-teams
./install-ms-teams-client.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Jul 03  | Mint 20.0 Cinnamon x64  | Virtualbox     | Teams v1.3.00.16851 100 | Working  |

