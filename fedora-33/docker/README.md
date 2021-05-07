
## Description

This script installs the latest Sublime Text from Sublime PPA.

Alternately, the official (manual) installer can be downloaded from [sublimetext.com](https://www.sublimetext.com/)

## Script Details

* Install the latest version (same as if you get it from [sublimetext.com](https://www.sublimetext.com/))
* Adds the Sublime PPA if you haven't already then installs Sublime.
* Adds a Nemo Action for "Edit with Sublime" (last I tested, around Jan/Feb 2020, this was not added during the install). For those who may not be familiar, Nemo is the default File Manager under Cinnamon DE (its display name appears as "Files" in Start Menu).


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/sublime
./install-sublime-from-dev-repo.sh
```

## Status


| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Jul 02  | Mint 20.0 Cinnamon x64  | Virtualbox     | Sublime Text v3.2.2 Build 3211 | Working |

