
## Description

Installs youtube-dl from source.

Note: I haven't checked in awhile but last I did the youtube-dl-gui app was not compatible with this as the CLI/terminal version has been migrated to python3 but the gui was still on python2.

## How to install:

*NOTE: Some scripts have dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/youtube-dl
./install-youtube-dl.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build   | Status  |
| ------------- | ------------------------| -------------- | ---------------------------- | ------- |
|   |  |      |     | Needs Retest |
