
You can get the official (manual) version of TeamViewer from [teamviewer.com](https://www.teamviewer.com/en-us/download/linux/).

Note: By using my script, you agree to TeamViewer's terms of use and agree to only use it for personal use (no business).

Or using my script, it will also:

* Auto-Resolves dependencies during install.
* Install the latest team viewer (same as installing from [teamviewer.com](https://www.teamviewer.com/en-us/download/linux/))
* Creates desktop shortcut if you don't already have one
* Creates and presets config files to be the least annoying it can be from an initial state.

To use this script:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/teamviewer
./install-team-viewer.sh
```

## Status

Last tested : 2020, July 02 with TestViewer 15.7.6 (Build Date: Jun 22 2020 17:07:04)

Last status : working (Mint 20.0 Cinnamon x64)

