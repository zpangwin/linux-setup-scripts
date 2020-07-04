
## Description

This script installs the latest Firefox Nightly PPA which has a separate binary named 'firefox-trunk' as well as a separate profile (allowing you to install/run it alongside the stable version of firefox)

see:

* [Reddit: Correct way to install Firefox Nightly on Ubuntu?](https://old.reddit.com/r/firefox/comments/6sx7eb/correct_way_to_install_firefox_nightly_on_ubuntu/)
* [Ubuntu-mozilla-daily PPA on LaunchPad](https://launchpad.net/%7Eubuntu-mozilla-daily/+archive/ubuntu/ppa)

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/firefox-nightly
./install-firefox-nightly-from-ppa.sh
```

## Status

Last tested : 2020, July 03 with Firefox Nightly 80.0a1 (2020-07-03)(64-bit)

Last status : working (Mint 20.0 Cinnamon x64)

