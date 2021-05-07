# Waterfox Classic

This script is to automate installing Waterfox Classic on Linux. If there is ever an official PPA / central repo package then that should take precedence over my script. This was written to make the install process less manual.

** Note: This simply installs the current version of Waterfox Classic but does NOT add any entries for it to be kept up-to-date by the system. To update, you will need to re-run the script manually. For this reason, it is recommended to use the unofficial ppa version instead (see app install folder ../unofficial-waterfox).**

If you prefer to install manually, then you can download the official binaries from [waterfox.net](https://www.waterfox.net/).

# Description:

This script automates the installation process of Waterfox. This is an older script that downloads an archive directly from [official site](https://www.waterfox.net/). As it does web scraping, it is more prone to breaking whenever the site changes. As it deals with archives, we can't rely on package managers and updates require re-running the script and praying that the site changes didn't break it.

## What does the script add?:

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

## How to use this script:

** Install waterfox from PPA**

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/waterfox-classic
./download-and-install-official-waterfox.sh
```

## Status

| Script                                      | Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build   | Status  |
| ------------------------------------------- | ------------- | ------------------------| -------------- | ---------------------------- | ------- |
| download-and-install-official-waterfox.sh | 2020, Jul 03  | Mint 20.0 Cinnamon x64  | Virtualbox     | Waterfox 2020.07 (64-bit)  | Working |
| add-wf-one-click-private-browsing-icon.sh | 2020, Jul 03  | Mint 20.0 Cinnamon x64  | Virtualbox     | Waterfox 2020.07 (64-bit)  | Working |
| backup-official-waterfox.sh               | 2020, Jul 03  | Mint 20.0 Cinnamon x64  | Virtualbox     | Waterfox 2020.07 (64-bit)  | Working |
