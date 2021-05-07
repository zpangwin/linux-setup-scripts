
## Description

Obviously anyone can download Steam from [their site](https://store.steampowered.com/about/) or from the central repos using `sudo apt install steam`.

But this script is more ambitious. It aims to do the following:

* Adds x86 support (i386) if not already present
* Install steam via official PPA
* Open TCP/UDP port 27036 so that in-home streaming will work with other computers on LAN
* Install latest Glorious Eggroll (GE) Proton builds

## To use this script:

This script depends on functions in ../functions.sh; the easiest way to take care of those is to just clone the project and run the script from a directory. Alternately, if you know how to edit scripts you can copy the required functions into the script (but I don't support that process).

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/steam

# install with default options
./install-and-setup-steam.sh

# view help
./install-and-setup-steam.sh --help

# default options but don't use PPA; install from central repo
./install-and-setup-steam.sh --noppa

# assume steam is already installed and just get the newest GE Proton build
./install-and-setup-steam.sh --update-only
```

Last tested : N/A
Last status : NOT TESTED (Mint 19.3 Cinnamon x64)


