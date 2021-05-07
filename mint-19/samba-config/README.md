
## Description

The purpose of this is to allow you to continue using system-config-samba. It was a nice little gui someone wrote for managing setup of samba shares. Unfortunately, it stopped working after gksu was deprecated and I never saw an update that moved things to policykit. It's been awhile since I originally wrote this workaround so if its been updated, then probably the original authors setup should be preferred over my workaround. That said, I've been running it on Linux Mint 19.3 without any issues.

./install-scripts-with-policykit-exception.sh will:

* create the /usr/bin/pkexec-system-config-samba wrapper script that lets you use system-config-samba through policykit instead of requiring gksu.
* automatically add a policykit exception so that you can use the system-config-samba gui without gksu
* fix the system-config-samba shortcut so that it executes the new pkexec wrapper script instead of trying to launch with the defunct gksu approach

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:


```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-19.3/apps/samba-config
./install-scripts-with-policykit-exception.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build      | Status  |
| ------------- | ------------------------| -------------- | ------------------------------- | ------- |
| 2020, Feb ??  | Mint 19.3 Cinnamon x64  | Baremetal      | Samba Server Config Tool 1.2.63 | Working |
