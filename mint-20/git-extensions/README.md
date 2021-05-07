
## Description

This is for installing Git Extensions 2.5 under Linux

./install-git-extensions-2.5.sh will:

* Install mono if you don't already have it
* Extract Git Extensions image icons from source, convert them, and install them as system icons
* Download and install Git Extensions 2.5 and install it to /opt/GitExtensions/
* Create several helper scripts for git under /usr/bin/
* Create several launcher scripts for launching various dialogs relative to a path in a given git repo.
* Create several context-menu items for Nemo (e.g. Nemo Actions)

What works:

* Pretty much everything; this install has been pretty stable for me for awhile

What needs work:

* If you are on older versions of Nemo, the "Conditions" parameter may not work. This isn't an issue in later versions of nemo such as the one that comes in Mint 19.3 or later but I can't remember which released that was added in. Pretty sure it wasn't present in Mint 19.1. Anyway, I'm not going to support older versions but if it doesn't work right, my advice is to edit the nemo_action in question and remove the "Conditions" parameter ... or upgrade to a newer version of Nemo. :-)

After installation, you should be able to open Nemo and:

* Right-click in the background of any non-git repo folder and see "GitExt Clone"
* Right-click on file or folder (or folder background) under a git repo and see "GitExt Browse" and "GitExt Commit"
* Right-click on file under a git repo and see "GitExt FileHistory"

If you are on an older version of Linux Mint (e.g. earlier than v19.3) or using an older version of Nemo (earlier than v4.4.2) then the Nemo actions may behave differently for you. The actions rely on a new "Conditions" feature (described [here](https://github.com/linuxmint/nemo/pull/2056)) that allows actions to display conditionally. On older versions where this is not present, you can just remove the "Conditions" property from the actions file to force it to always display (e.g. don't consider whether you are in a git repo or not).


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/git-extensions
./install-git-extensions-2.5.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Aug 15  | Mint 20.0 Cinnamon x64  | Virtualbox     | Git Extensions 2.51.05\* | Working |

\* Note: That versions after 2.51.x no longer use dot net in a way that is cross-platform compatible and thus will not work under Linux. As of 2020, Aug 15, the last version in the 2.51.x branch is 2.51.05 (released Sep 17, 2018).

## Screenshots

### Default menu items:

![Default options (folder view)](https://github.com/zpangwin/linux-setup-scripts/blob/master/imgs/git-extensions/default-menu-items.png?raw=true)

Right clicking on a folder/backgroud/file in a Git Repo:

* GitExt Browse
* GitExt Commit

Right clicking on a file in a Git Repo:

* GitExt File History

Right-clicking on a folder/backgroud outside a Git Repo:

* GitExt Clone


### Full menu items:

![Full options (file view)](https://github.com/zpangwin/linux-setup-scripts/blob/master/imgs/git-extensions/full-menu-items.png?raw=true)

Right clicking on a folder/backgroud/file in a Git Repo:

* GitExt Browse
* GitExt Commit
* GitExt Push
* GitExt Pull
* GitExt Stash
* GitExt Settings

Right clicking on a file in a Git Repo:

* GitExt Diff File
* GitExt Revert File
* GitExt File History

Right-clicking on a folder/backgroud outside a Git Repo:

* GitExt Init
* GitExt Clone

### How to customize:

**TL;DR** - go to `/usr/share/nemo/actions` and add/remove `.disabled` from the files as desired. See screenshot.

![How to customize](https://github.com/zpangwin/linux-setup-scripts/blob/master/imgs/git-extensions/how-to-customize.png?raw=true)
