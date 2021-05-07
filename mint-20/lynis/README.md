
## Description

lynis is an auditing tool that can be used to identify bad security configurations on your machine.

* [Howtogeek.com: How to Audit Your Linux System's Security with Lynis](https://www.howtogeek.com/674288/how-to-audit-your-linux-systems-security-with-lynis/)
* [Official Lynis homepage](https://cisofy.com/lynis/#introduction)
* [Official Lynis Github](https://github.com/CISOfy/Lynis)
* [Lynis PPA/Launchpad page](https://launchpad.net/~cisofy/+archive/ubuntu/lynis) - note this page appears to be outdated (has builds from utopic; attempting to add on bionic results in an error).
* [Official Lynis Community Repo](https://packages.cisofy.com/community/)


## Installation approach

The official repos were installing v2.6.2-1 on LM19 as of 2020 Aug 28. According to [github](https://github.com/CISOfy/lynis/releases/tag/2.6.2), that version was released 2018 Feb 13 while the latest release on github was v3.0.0 on 2020 Jun 18.

This script uses the PPA to install a more update-to-date verion


## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/lynis
./install-lynis-from-dev-repo.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| N/A  | Mint 20.0 Cinnamon x64  | Virtualbox     |  | UNTESTED |


