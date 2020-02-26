# Firefox icon scripts

These scripts don't install Firefox -- it should already be preinstalled on most Linux distros, including Linux Mint.Due to Mozilla licensing terms, Linux Mint is not allowed to package the official Firefox images in the distro without opening itself up to legal issues. However, as users we are allowed to modify our individual firefox installations. I am not a lawyer. But the Firefox codebase is open-source and under the terms Mozilla sets forth we are free to download and modify the source-code for our own personal use but not to distribute those modifications unless we remove any and all Mozilla / Firefox branding.

# Description:


There are 2 scripts in here: **fix-ugly-firefox-icons.sh** and **add-ff-one-click-private-browsing-icon.sh**


**fix-ugly-firefox-icons.sh** - This script just downloads the official Firefox icons from their open-source code repository and replaces the ugly Firefox icons in the Linux Mint default themes. Be aware that running this script and then packaging and **redistributing** the end result could still land you in hot water with Mozilla. But if you are just running this on your local, then no muss, no fuss. Also if you don't use one of the Mint default themes then this script might not help you much except as a reference. If anyone has additional theme requests, I would be open to adding; especially if that themes icons follow a similar format. **This repository does not contain any Mozilla source code/icons/images/etc**; it merely automates the process of manually retrieving the files from their public repository. If you would like to use the images for non-personal use, you will need to seek permission from Mozilla directly just as you would if you had downloaded the images manually.

**add-ff-one-click-private-browsing-icon.sh** - script that downloads the official private browsing icon from firefox source, installs it, and creates a one-click private browsing shortcut (*.desktop). If you run this by accident or decide you n longer want the shortcut, you can remove the private shortcut (e.g. leave only the regular shortcut) by running `sudo rm /usr/share/applications/firefox-private.desktop`

## What does the script add?:

**fix-ugly-firefox-icons.sh**

This script replaces various firefox icons in the Linux Mint default theme sets. It does not make backups because I really dislike the originals (but it would be easy enough to add if anyone requests it).

Here is a list of the images that are replaced, for `${size}` use the following sizes: `16 22 24 32 48 64 128 256`:

* `/usr/share/icons/HighContrast/${size}x${size}/apps/firefox.png`
* `/usr/share/icons/Mint-Y/apps/${size}@2x/firefox.png`
* `/usr/share/icons/Mint-Y/apps/${size}/firefox.png`
* `/usr/share/icons/Mint-X/apps/${size}/firefox.png`

If I recall correctly, some of the various permutations of SIZE x LOCATION don't have images in the original themes but it's been awhile since I checked so I could be mistaken. Also, you won't see the changes take effect until you log-off and back in (or maybe it was after reboot?).

**add-ff-one-click-private-browsing-icon.sh**

* Private browsing icon at: `/usr/share/icons/private-browsing.png`
* One-click Private browsing shortcut at: `/usr/share/applications/firefox-private.desktop`

# How to use these scripts:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/firefox
./fix-ugly-firefox-icons.sh
./add-ff-one-click-private-browsing-icon.sh
```

## Status

Last tested : Feb 2020 with Firefox 73.0 (64-bit)

Last status : working (Mint 19.3 Cinnamon x64)

