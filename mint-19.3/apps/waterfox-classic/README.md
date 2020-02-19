# Waterfox Classic

This script is to automate installing / updating Waterfox Classic on Linux. If there is ever an official PPA / central repo package then that should take precedence over my script. This was written to make the install process less manual.

If you prefer to install manually, then you can download the official binaries from [waterfox.net](https://www.waterfox.net/).

# Description:

There are 2 scripts in here: **install-waterfox-updates.sh** and **setup-unofficial-ppa.sh**

Both of these automate the installation process but they do so in different ways. 

**You should only use one or the other.** In theory, it shouldn't hurt anything if you were to install both because they install to different locations and have different binary names; but I would advise against it anyway (if for no other reason that wasting extra space).

I recommend that most people use **setup-unofficial-ppa.sh** (see the second to last section for installation instructions), as this version will make updates much less painful.

**setup-unofficial-ppa.sh** - this is the newer script that adds [hawkeye116477's unofficial Ubuntu PPA hosted on opensuse.org](http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/xUbuntu_18.040) and installs waterfox kde version from there. Since [hawkeye116477 is a Waterfox developer](https://github.com/MrAlex94/Waterfox/commits?author=hawkeye116477) but the PPA is not listed on the [official WF site](https://www.waterfox.net/) / [WF github page](https://github.com/MrAlex94/Waterfox), I feel this is a pretty trustworthy source but likely just a **personal** package archive.

**install-waterfox-updates.sh** - older script that downloads an archive directly from [official site](https://www.waterfox.net/). As it does web scraping, it is more prone to breaking whenever the site changes. As it deals with archives, we can't rely on package managers and updates require re-running the script and praying that the site changes didn't break it.

You will get a menu shortcut (*.desktop) file for Waterfox Classic running either script (but if you didnt listen and ran both scripts, it will point to the newer install).

Both scripts will also create a single-click shortcut for Waterfox private browsing that opens dnsleaktest.com ... because I wanted it. If anyone doesn't want that, I could probably add a flag to disable this or move that functionality to another script. In the mean time, if you really don't like having it, you can remove the private shortcut (e.g. leave only the regular shortcut) by running `sudo rm /usr/share/applications/waterfox-private.desktop`

## What does the script add?:

**setup-unofficial-ppa.sh**

* New repo source at `/etc/apt/sources.list.d/waterfox-unofficial.list`
* symlink at `/usr/bin/waterfox` (points to `/usr/bin/waterfox-classic`)
* symlink at `/usr/bin/waterfox-classic` (points to `/usr/lib/waterfox-classic/waterfox-classic-bin.sh`)
* The `waterfox-kpe` package is installed under `/usr/lib/waterfox-classic/` (not sure if it adds additional stuff)
* The `waterfox-kpe` package requires a locale so package `waterfox-locale-en` is also installed by the script
* Regular shortcut at: `/usr/share/applications/waterfox-classic.desktop` (this is added by `waterfox-kpe`)
* Single-click Private browsing shortcut at: `/usr/share/applications/waterfox-private.desktop` (this is added by the script)
* Private browsing icon at: `/usr/share/icons/private-browsing.png`

**install-waterfox-updates.sh**

* The script downloads temp files and logs debug statements to a folder under /tmp (these are purged by OS on reboot).
* The script will do web-scraping to find the download link of the latest waterfox classic listed on the official site. If the web-scraping fails, the script will abort without making any changes.
* The script will extract the archive to `/opt/waterfox-classic`
* If the script was run previously, the old `/opt/waterfox-classic` dir will be archived to `/opt/waterfox-classic-backup-YYYYmmddHHMM.7z` before extracting the latest archive.
* After a successful install, the downloaded archive will be moved under `/opt/waterfox-archives` in case you need to manually reinstall an older version later.
* symlinks at `/usr/bin/waterfox` and `/usr/bin/waterfox-classic` (both pointing to `/opt/waterfox-classic/waterfox`)
* Regular shortcut at: `/usr/share/applications/waterfox-classic.desktop` (this is added by the script)
* Single-click Private browsing shortcut at: `/usr/share/applications/waterfox-private.desktop` (this is added by the script)
* Private browsing icon at: `/usr/share/icons/private-browsing.png`


# How to use this script:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/waterfox-classic
./setup-unofficial-ppa.sh
```

Last tested : Feb 2020 with Waterfox 2020.02
Last status : working (Mint 19.3 Cinnamon x64)
(installed using install-waterfox-updates.sh)

Last tested : Feb 2020 with Waterfox 2020.02 KDE Plasma Edition
Last status : working (Mint 19.3 Cinnamon x64)
(installed using setup-unofficial-ppa.sh)

