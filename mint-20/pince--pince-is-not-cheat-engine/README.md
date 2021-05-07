## Description

PINCE has one of those recursive acronyms that so many Linux apps do. In this case, it stands for "Pince Is Not Cheat Engine".

It is a Linux alternative to Cheat Engine. If you're not familiar with Cheat Engine, it is a memory hacker used to cheat at (primarily) single-player games. I do not advocate the use of cheat tools for multiplayer games except in the extremely rare case of dedicated servers where all participants are aware of and agree to their use. Using cheat tools in most multiplayer games runs the risk of getting VAC bans on your steam account and is highly discouraged.

Or we can borrow the short version from wiccans: "Don't be a dick"... er, I mean "An' ye harm none, do what ye will".


## How do I use it?

TBH, I have no idea. I rarely ever cheat in games... I created this installer because I thought my brother might be interested in PINCE if he ever migrated to Linux but I never really used PINCE; to be fair, I didn't really use CE much before I migrated to Linux either.

I'd recommend that you check out [their website](https://github.com/korcankaraokcu/PINCE) and maybe look on youtube. they also mentioned a discord server [here](https://discord.gg/KCNDp9m);

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/pince--pince-is-not-cheat-engine
./install-pince-w-menu-items-and-polkit-exceptions.sh
```

## Status

| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                   | Status  |
| ------------- | ------------------------| -------------- | -------------------------------------------- | ------- |
| 2020, Jul 06  | Mint 20.0 Cinnamon x64  | Virtualbox     | PINCE (built from master; commit 947ee38)    | Working |

