

## Description

Asbru Connection Manager is a free and open-source connection manager for Linux. It is comparable to mRemoteNG / PuTTY from Windows.

Asbru Connection Manager - [github repo](https://github.com/asbru-cm/asbru-cm) | [official site](https://www.asbru-cm.net/)
Unofficial PPA - [LaunchPad](https://launchpad.net/~asbru-cm/+archive/ubuntu/releases)

According to the official site, ACM can be installed by using the following commands on Ubuntu:

```
curl -s https://packagecloud.io/install/repositories/asbru-cm/asbru-cm/script.deb.sh | sudo bash
sudo apt install asbru-cm
```

This script instead adds a PPA from [LaunchPad](https://launchpad.net/~asbru-cm/+archive/ubuntu/releases) to ensure that updates can be managed via the system's Update Manager rather than requiring manual updates.

## PPA Author

As far as I could tell, the PPA Author was not officially involved with the Github project.

The PPA author is [Peter J. Mello](https://launchpad.net/~roguescholar) who goes by the screen name "RogueScholar" on both LaunchPad and GitHub. I did not see that name listed under the [contributors section of the asbru-cm github project](https://github.com/asbru-cm/asbru-cm/graphs/contributors) nor was the PPA referred to in the github project's README file.

Some additional info on the PPA author can be found on [his Ubuntu wiki bio page](https://wiki.ubuntu.com/RogueScholar). He seems to be involved in packaging for several open source projects (not sure of official vs unofficial capacity) and appears on several open source discussions boards including several for [ubuntu backports](http://ubuntu.5.x6.nabble.com/Bug-1853616-Re-Eoan-Backports-project-does-not-exist-td5191938.html), [inkscape](https://gitlab.com/inkscape/inkscape/-/issues/506), and some discussions on systemd. While I did not find any complaints/warnings about his PPA nor did I find anything confirming it but I am inclined to believe it is ok based on his history in the open-source community and his [Launchpad Karma](https://launchpad.net/~roguescholar/+karma).

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
| N/A  | Mint 20.0 Cinnamon x64  | Virtualbox     | Asbru Connection Manager v6.0.4 | Retest |
