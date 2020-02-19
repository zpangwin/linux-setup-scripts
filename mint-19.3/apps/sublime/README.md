
Official (manual) installer can be downloaded from [sublimetext.com](https://www.sublimetext.com/)

Or using my script, it will also:

* Install the latest version (same as if you get it from [sublimetext.com](https://www.sublimetext.com/))
* Adds the Sublime PPA if you haven't already then installs Sublime.
* Adds a Nemo Action for "Edit with Sublime" (last I tested, around Jan/Feb 2020, this was not added during the install). For those who may not be familiar, Nemo is the default File Manager under Cinnamon DE (its display name appears as "Files" in Start Menu).


To use this script:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/sublime
./install-from-dev-repo.sh
```


Last tested : Feb 2020 with Sublime 3
Last status : working (Mint 19.3 Cinnamon x64)

