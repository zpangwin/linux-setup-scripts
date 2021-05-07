

## Description

Asbru Connection Manager is a free and open-source connection manager for Linux. It is comparable to mRemoteNG / PuTTY from Windows.

Asbru Connection Manager - [github repo](https://github.com/asbru-cm/asbru-cm) | [official site](https://www.asbru-cm.net/)

According to the official site, ACM can be installed by using the following commands on Ubuntu:

```
curl -s https://packagecloud.io/install/repositories/asbru-cm/asbru-cm/script.deb.sh | sudo bash
sudo apt install asbru-cm
```

This script instead adds a PPA from [LaunchPad](https://launchpad.net/~asbru-cm/+archive/ubuntu/releases) to ensure that updates can be managed via the system's Update Manager rather than requiring manual updates.


## How to install via script:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/asbru-connection-manager
./install-asbru-connection-manager-from-ppa.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2020, Jul 03  | Mint 20.0 Cinnamon x64  | Virtualbox     | sbru Connection Manager v6.0.4 | Working |
