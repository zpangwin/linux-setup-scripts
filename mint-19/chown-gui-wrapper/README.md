
## Description

I created this mostly to have a simplified list of users when I need to change ownership when I had Nemo "Open\[ed\] as Root". This is described more fully in [nemo issue #2224](https://github.com/linuxmint/nemo/issues/2224). Alternately, I originally created this with a manual process which I documented [here](https://askubuntu.com/a/1181072).

## Script Details

install-scripts-with-policykit-exception.sh will:

* install the main script responsible for creating the gui and applying the owner changes to /usr/bin/chown-gui-wrapper
* install the wrapper script for policykit to /usr/bin/pkexec-chown-gui-wrapper
* create policykit exceptions so that you can run the script as root or when using the "Open as Root" option in Nemo (or be prompted for creds as regular user).
* install nemo-actions so that the option "Change Owner/Group" will appear in right-click menus in Nemo

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/chown-gui-wrapper
./install-chown-gui-with-policykit-exception.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Feb ??  | Mint 19.3 Cinnamon x64  | Baremetal      | chown-gui-wrapper                         | Working |


## Screenshots

Main dialog:

![Main dialog](https://github.com/zpangwin/linux-setup-scripts/blob/master/imgs/chown-gui-wrapper/chown-gui-wrapper_main.png?raw=true)


&nbsp;


Users Dropdown (running as root):

![Users Dropdown](https://github.com/zpangwin/linux-setup-scripts/blob/master/imgs/chown-gui-wrapper/chown-gui-wrapper_users-dropdown.png?raw=true)
