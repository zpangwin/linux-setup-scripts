
## Description

The purpose of this is to allow you to continue using system-config-samba. It was a nice little gui someone wrote for managing setup of samba shares. Unfortunately, it is severely outdated so it requires a shit ton of workarounds before you can use it.

## Issues Addressed (aka Hacks and Workarounds)

1. As of Ubuntu 19 and 20 (and thus also Linux Mint 20), many python2 libs are deprecated and no longer available in the central repository. This also applies to several older packages that were using the deprecated python2 libs and hadn't seen updates in awhile such as fslint and yup **system-config-samba**. This issue prevents you from even installing system-config-samba (via apt anyway) in newer Ubuntu-based distros. I refuse to use snaps so I have opted to manually install older copies of the DEB files. More details on this below.

2. As system-config-samba hasn't been updated in some time, it still relies on gksu for GUI-level authentication prompts. Unfortunately, gksu was deprecated and removed back in Ubuntu 18. Many sites would tell you to use the new "admin://" prefix instead but this doesn't work for all scenarios (IIRC, \*.desktop files in particular did not support it back then). Another option was to use [Polkit](https://en.wikipedia.org/wiki/Polkit) to set up exceptions and then run "[pkexec](https://itsfoss.com/gksu-replacement-ubuntu/) <command>". My script sets up both the polkit exceptions and a wrapper script for using pkexec. It even fixes the system menu so that it will launch using pkexec.

3. There is also a [bug where system-config-samba.py fails to start due to missing /etc/libuser.conf](https://bugs.launchpad.net/ubuntu/+source/libuser/+bug/1387274). Fortunately, this is easily fixed just by creating an empty file with readable permissions (the script handles this as well).

## DEB files used

The script downloads and installs DEB files from the following URLs:

```
wget http://archive.ubuntu.com/ubuntu/pool/universe/p/pygtk/python-gtk2_2.24.0-6_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/p/pygtk/python-glade2_2.24.0-6_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/libu/libuser/python-libuser_0.62~dfsg-0.1ubuntu2_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/s/system-config-samba/system-config-samba_1.2.63-0ubuntu6_all.deb
```

In theory, any mirror should work so if you want to replace them with something closer, go ahead. That said, the 4 files combined are a whopping 907.7 kB so it shouldn't be that bad.

Here are the checksums I see:

```
$ sha256sum *.deb
41c7f1c3237854b1e69a16873a845001adc3d2d610b29b016e24fcc57f1955d1  python-glade2_2.24.0-6_amd64.deb
99efe128583941807a667a16d5dcf49b652ae83b03ada620b68d20a8cff90dcd  python-gtk2_2.24.0-6_amd64.deb
bd3ecca23fa389d2eb1a21d18408a4ce4f2e80aee4613534c96b8b7a987e37f8  python-libuser_0.62~dfsg-0.1ubuntu2_amd64.deb
a07e97bd20a7904984e99be2dcafd484e5b498ff8656043aefee95d728bf1daf  system-config-samba_1.2.63-0ubuntu6_all.deb
```

If you are curious about to actually determine what libs are needed, read the script source code... I kept more detailed notes about that in there (because I am likely to forget otherwise lol).


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:


```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/samba-config
./install-scripts-with-policykit-exception.sh
```

## Status

Last tested : 2020, July 04 with Samba Server Config Tool 1.2.63
Last status : working (Mint 20.0 Cinnamon x64 in Virtualbox)
