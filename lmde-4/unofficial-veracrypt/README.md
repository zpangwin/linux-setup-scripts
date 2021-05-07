
## Description

VeraCrypt is a fork of the discontinued TrueCrypt project.

It is used for on-the-fly encryption (OTFE). It can create a virtual encrypted disk within a file or encrypt a partition.

The official manual setup can be found [here](https://www.veracrypt.fr/en/Downloads.html).

## Installation approach

The [Official Veracrypt Downloads](https://www.veracrypt.fr/en/Downloads.html) page, provides DEB files for Debian/Ubuntu.

I am not aware of any official PPAs/secondary sources for the project. However, there is an unofficial Debian source that some might consider trustworthy enough:

**This script relies on that unofficial PPA so if you don't consider that trustworthy for your purposes, then it is recommended that you install manually from the official site instead.**

---

There is source hosted on the OpenSuse servers [here](https://software.opensuse.org/download.html?project=home%3Astevenpusser%3Averacrypt&package=veracrypt) that is packaged by user Steven Pusser, who apparently packages several various application including pale moon (a somewhat popular firefox fork) as can be see [here](https://antixlinux.com/forum-archive/latest-palemoon-browser-t7203.html).

The directions provided on the [OBS page](https://software.opensuse.org/download.html?project=home%3Astevenpusser%3Averacrypt&package=veracrypt) for Debian 10 Buster are as follows:

    echo 'deb http://download.opensuse.org/repositories/home:/stevenpusser:/veracrypt/Debian_10/ /' | sudo tee /etc/apt/sources.list.d/home:stevenpusser:veracrypt.list
    curl -fsSL https://download.opensuse.org/repositories/home:stevenpusser:veracrypt/Debian_10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home:stevenpusser:veracrypt.gpg > /dev/null
    sudo apt update
    sudo apt install veracrypt

I used slightly different commands as follows (bc I am picky about my apt list filename formats and like using consistent commands in my app setup scripts):

    echo 'deb http://download.opensuse.org/repositories/home:/stevenpusser:/veracrypt/Debian_10/ /' | sudo tee /etc/apt/sources.list.d/unofficial-veracrypt-stevenpusser.list;
    sudo chmod 644 /etc/apt/sources.list.d/unofficial-veracrypt-stevenpusser.list;
    wget -qO - https://download.opensuse.org/repositories/home:stevenpusser:veracrypt/Debian_10/Release.key | sudo apt-key add -;
    sudo apt-get update;
    sudo apt-get install -y veracrypt;


"You should be aware that this repo is not related to the software developer and because of it you can't be 100% sure what you install or update in future. However the packager (stevenpusser) who appears to have been actively involved in the opensource community and a packager for [palemoon](https://antixlinux.com/forum-archive/latest-palemoon-browser-t7203.html) (a somewhat popular firefox fork).


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/unofficial-veracrypt
./install-veracrypt-from-unofficial-repo.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| N/A  | Mint 20.0 Cinnamon x64  | Virtualbox     | VeraCrypt 1.24-Update4, Released by IDRIX | Retest |


