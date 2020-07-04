# Waterfox Classic

This script is to automate installing / updating Waterfox Classic on Linux. If there is ever an official PPA / central repo package then that should take precedence over my script. This was written to make the install process less manual.

If you prefer to install manually, then you can download the official binaries from [waterfox.net](https://www.waterfox.net/).

# Description:

There are 3 scripts in here: **download-and-install-official-waterfox.sh** and **install-waterfox-from-unofficial-dev-ppa.sh**

Two of them both automate the installation process of Waterfox but they do so in different ways. The other script is for if you want to add a one-click private browsing shortcut (*.desktop).

**You should only use one or the other.** In theory, it shouldn't hurt anything if you were to install both because they install to different locations and have different binary names; but I would advise against it anyway (if for no other reason that wasting extra space).

I recommend that most people use **install-waterfox-from-unofficial-dev-ppa.sh** (see the second to last section for installation instructions), as this version will make updates much less painful.

**install-waterfox-from-unofficial-dev-ppa.sh** - this is the newer script that adds [hawkeye116477's unofficial Ubuntu PPA hosted on opensuse.org](http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/xUbuntu_20.04) and installs waterfox kde version from there. Since [hawkeye116477 is a Waterfox developer](https://github.com/MrAlex94/Waterfox/commits?author=hawkeye116477) but the PPA is not listed on the [official WF site](https://www.waterfox.net/) / [WF github page](https://github.com/MrAlex94/Waterfox), I feel this is a pretty trustworthy source but likely just a **personal** package archive.

**download-and-install-official-waterfox.sh** - older script that downloads an archive directly from [official site](https://www.waterfox.net/). As it does web scraping, it is more prone to breaking whenever the site changes. As it deals with archives, we can't rely on package managers and updates require re-running the script and praying that the site changes didn't break it.

You will get a menu shortcut (*.desktop) file for Waterfox Classic running either of the above scripts (but if you didn't listen and ran both scripts, the shortcut will probably be pointing to whichever one you ran last).

**extras/add-wf-one-click-private-browsing-icon.sh** - script that downloads the official private browsing icon from firefox source, installs it, and creates a one-click private browsing shortcut (*.desktop). If you run this by accident / have it from an older version of the install script, you can remove the private shortcut (e.g. leave only the regular shortcut) by running `sudo rm /usr/share/applications/waterfox-private.desktop`

## What does the script add?:

**install-waterfox-from-unofficial-dev-ppa.sh**

* New repo source at `/etc/apt/sources.list.d/waterfox-unofficial.list`
* symlink at `/usr/bin/waterfox` (points to `/usr/bin/waterfox-classic`)
* symlink at `/usr/bin/waterfox-classic` (points to `/usr/lib/waterfox-classic/waterfox-classic-bin.sh`)
* The `waterfox-kpe` package is installed under `/usr/lib/waterfox-classic/` (not sure if it adds additional stuff)
* The `waterfox-kpe` package requires a locale so package `waterfox-locale-en` is also installed by the script
* Regular WF shortcut at: `/usr/share/applications/waterfox-classic.desktop` (this is added by `waterfox-kpe`)

**download-and-install-official-waterfox.sh**

* The script downloads temp files and logs debug statements to a folder under /tmp (these are purged by OS on reboot).
* The script will do web-scraping to find the download link of the latest waterfox classic listed on the official site. If the web-scraping fails, the script will abort without making any changes.
* The script will extract the archive to `/opt/waterfox-classic`
* If the script was run previously, the old `/opt/waterfox-classic` dir will be archived to `/opt/waterfox-classic-backup-YYYYmmddHHMM.7z` before extracting the latest archive.
* After a successful install, the downloaded archive will be moved under `/opt/waterfox-archives` in case you need to manually reinstall an older version later.
* symlinks at `/usr/bin/waterfox` and `/usr/bin/waterfox-classic` (both pointing to `/opt/waterfox-classic/waterfox`)
* Regular WF shortcut at: `/usr/share/applications/waterfox-classic.desktop` (this is added by the script)

**extras/add-wf-one-click-private-browsing-icon.sh**

* Private browsing icon at: `/usr/share/icons/private-browsing.png`
* One-click Private browsing shortcut at: `/usr/share/applications/waterfox-private.desktop`

I am also adding some uninstall scripts but those should be considered as experimental/work-in-progress until I have time to retest them and update the testing notes at the bottom of this readme.

## How to use this script:

** Install waterfox from PPA**

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/waterfox-classic
./install-waterfox-from-unofficial-dev-ppa.sh
```

## Status

Last tested :

* install-waterfox-from-unofficial-dev-ppa.sh:	2020, July 03 with Waterfox 2020.07 (64-bit), KDE Plasma Edition
* download-and-install-official-waterfox.sh:	2020, July 03 with Waterfox 2020.07 (64-bit)
* add-wf-one-click-private-browsing-icon.sh:	2020, July 03 with Waterfox 2020.07 (64-bit)
* backup-official-waterfox.sh:					2020, July 03 with Waterfox 2020.07 (64-bit)
* remove-waterfox-from-unofficial-dev-ppa.sh:	2020, July 03 with Waterfox 2020.07 (64-bit), KDE Plasma Edition

Last status :

* install-waterfox-from-unofficial-dev-ppa.sh:	working (Mint 20.0 Cinnamon x64)
* download-and-install-official-waterfox.sh:	working (Mint 20.0 Cinnamon x64)
* add-wf-one-click-private-browsing-icon.sh:	working (Mint 20.0 Cinnamon x64)
* backup-official-waterfox.sh:					working (Mint 20.0 Cinnamon x64)
* remove-waterfox-from-unofficial-dev-ppa.sh:	working (Mint 20.0 Cinnamon x64)
