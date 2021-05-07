
## Description

[MP3Gain](http://mp3gain.sourceforge.net/) is an audio normalization software tool. The tool is available on multiple platforms and is free software. It analyzes the MP3 and reversibly changes its volume. The volume can be adjusted for single files or as album where all files would have the same perceived loudness. It is an implementation of ReplayGain. In 2015 Debian and Ubuntu removed it from their repositories due to a lack of an active maintainer.

See:

* [ubuntuforums.org/showthread.php?t=2391446](https://ubuntuforums.org/showthread.php?t=2391446)
* [LaunchPad PPA](https://launchpad.net/~flexiondotorg/+archive/ubuntu/audio?field.series_filter=bionic)
* [Sourceforge Page](http://mp3gain.sourceforge.net/)


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/mp3gain
./install-mp3gain-from-ppa.sh
```

## Status


| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                   | Status  |
| ------------- | ------------------------| -------------- | --------------------------------------------- | ------- |
|    |    |       | TODO | TODO |



