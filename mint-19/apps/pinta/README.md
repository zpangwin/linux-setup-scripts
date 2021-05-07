
## Description

This script installs the latest (stable) Pinta from the [official PPA](https://launchpad.net/~pinta-maintainers/+archive/ubuntu/pinta-stable).

Alternately, the official (manual) installer can be downloaded from [pinta-project.com](https://www.pinta-project.com/)

## Script Details

* Adds the Pinta PPA if you haven't already
* Install the latest version

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/pinta
./install-pinta-from-dev-repo.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Aug ??  | Mint 19.3 Cinnamon x64  | Virtualbox     | Pinta 1.7 | Working |
