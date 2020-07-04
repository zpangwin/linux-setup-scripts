
## Description

VeraCrypt is a fork of the discontinued TrueCrypt project.

It is used for on-the-fly encryption (OTFE). It can create a virtual encrypted disk within a file or encrypt a partition.

The official manual setup can be found [here](https://www.veracrypt.fr/en/Downloads.html).

## Installation approach

The [Official Veracrypt Downloads](https://www.veracrypt.fr/en/Downloads.html) page, provides DEB files for Debian/Ubuntu.

I am not aware of any official PPAs for the project. However, there is an unofficial PPA that some might consider trustworthy enough:

**This script relies on that unofficial PPA so if you don't consider that trustworthy for your purposes, then it is recommended that you install manually from the official site instead.**

---

There is user Unit 193 who prepares ready builds of VeraCrypt on [Launchpad](https://launchpad.net/~unit193/+archive/ubuntu/encryption). You can easily install it by adding his repo to Ubuntu sources"[1](https://askubuntu.com/questions/929195/what-is-the-recommended-way-to-use-veracrypt-in-ubuntu)

"You should be aware that this repo is not related to the software developer and because of it you can't be 100% sure what you install or update in future. However Unit 193 is Xubuntu developer and he is well known in open source community. This is enough for me to sleep well."


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/veracrypt
./install-veracrypt.sh
```

## Status

Last tested : 2020, July 03 with 'VeraCrypt 1.24-Update4, Released by IDRIX on January 23, 2020'

Last status : working (Mint 20.0 Cinnamon x64 in Virtualbox)

