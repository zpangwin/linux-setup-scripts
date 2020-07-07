
## Description

[Chromium](https://en.wikipedia.org/wiki/Chromium_%28web_browser%29) is a free and open-source software project from Google. The source code can be compiled into a web browser.

Google uses the code to make its Chrome browser, which has more features than Chromium. Many other browsers are also based on Chromium code, most notably Microsoft Edge and Opera. In addition, some parties (although not Google) build the code as-is and release browsers with the Chromium name.

The official project homepage can be found [here](https://www.chromium.org/Home). This site does offer some manual install options but these do not include update mechanisms nor will they supply source repositories so that the system's Update Manager can handle updates.

This script installs a non-snap version of chromium-browser from a PPA maintained by the [Ungoogled Chromium project folks](https://software.opensuse.org/download/package?package=ungoogled-chromium&project=home:ungoogled_chromium).

Their gitub page can be found [here](https://github.com/Eloston/ungoogled-chromium) along with a [FAQ detailing how to use extensions](https://ungoogled-software.github.io/ungoogled-chromium-wiki/faq)

## Chromium-browser in Ubuntu 20.x

Lots of Linux news sites have already covered this but in Ubuntu 20.x, Canonical decided to replace the APT installation of the chromium-browser package with one that instead installs snapd and a [snap](https://en.wikipedia.org/wiki/Snap_%28package_manager%29)-based version of chromium-browser instead of the old APT-based one. Meanwhile, the Linux Mint 20 team opted not to do this (for which I am very grateful).

There are already [many](https://www.howtogeek.com/670084/what-you-need-to-know-about-snaps-on-ubuntu-20.04/) [arguments](https://thenewstack.io/canonicals-snap-great-good-bad-ugly/) both for or [against](https://www.reddit.com/r/Ubuntu/comments/askwvp/the_snap_experience_is_bad_and_is_increasingly/) snaps specifically or containerized package managers in general (e.g. snaps/flatpak/AppImage/etc). I personally am not a fan of snaps but for me this is largely due to a "feature" which is highly annoying to me: they add a lot of block loop devices which clutter up output from many common disk-related commands like `blkid`, `fdisk -l`, `parted -l`, `mount`, '`df -H`, etc and make it harder to parse out the relevant info with the human eye.

## Known Issues

1. Extensions do not work out of the box. See this [FAQ](https://ungoogled-software.github.io/ungoogled-chromium-wiki/faq). It lists several options but the best integrated one is detailed in the README of the project "[chromium-web-store by NeverDecaf](https://github.com/NeverDecaf/chromium-web-store)". Basically, you need to see a flag, then download and install the "Chromium.Web.Store.crx" file from the project's releases page, then restart chromium.

```
Installation

1. Go to chrome://extensions and enable developer mode (toggle in top right).
2. Download the .crx from Releases and drag-and-drop it onto the chrome://extensions page.

```

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/snapless-chromium
./install-chromium-WITHOUT-snap.sh
```

## Status


| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build               | Status  |
| ------------- | ------------------------| -------------- | ---------------------------------------- | ------- |
| 2020, Jul 05  | Mint 20.0 Cinnamon x64  | Virtualbox     | Chromium 83.0.4103.116 (Developer Build) | Working\* |


\* Extensions do not work out-of-the-box. See "Known Issues" section for workarounds


