
## Description

Open Broadcaster Software (OBS) / OBS Studio is a free and open-source software suite for recording and live streaming. The official site can be found [here](https://obsproject.com/).

The official site provides [instructions for adding their official PPA](https://obsproject.com/wiki/install-instructions#linux), which this script automates.


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/obs-studio
./install-obs-studio-from-ppa.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                   | Status  |
| ------------- | ------------------------| -------------- | --------------------------------------------- | ------- |
|    |    |       | TODO | TODO |



