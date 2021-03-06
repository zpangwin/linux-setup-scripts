
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
cd linux-setup-scripts/mint-19.3/apps/teamviewer
./install-team-viewer.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build      | Status  |
| ------------- | ------------------------| -------------- | ------------------------------- | ------- |
| 2020, Feb ??  | Mint 19.3 Cinnamon x64  | Baremetal      | TestViewer 15 | Working |


