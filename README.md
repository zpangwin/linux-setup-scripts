# linux-setup-scripts

## Overview

Misc scripts for linux (targeting linux mint only)

## Description

TLDR; these are my own personal app install/update scripts. USE AT YOUR OWN RISK. I TAKE NO RESPONSIBILTY FOR DAMAGED SYSTEM CONFIGS / SOFTWARE CONFLICTS / FRACKED COMPUTERS / LOST KITTENS / INCREASED DESIRED TO CONSUME ALCOHOL.

That said:

* Mostly these scripts are hacks to handle things that aren't in the central repo and usually take manual intervention. I use them to install/update things so that I don't have to manually handle it on multiple computers. Yes, Ansible/Puppet/etc would probably be better solutions. But I don't care.
* These scripts are not very well organized in terms of WIP vs "Works great now" vs "Worked a month ago". That could change eventually after I've put more thought into it but for now it's AS-IS. Anything that is a TXT file hasn't been scripted yet. Usually, the scripts in sub-folders have been tested and worked for me.
* I **only** test on whatever versions of Linux that I'm running at home or at my parents... so the latest version of Linux Mint :-P ... would probably work on other \*nix systems, potentially even apple/bsd stuff if it had the GNU coreutils. But you're on your own for testing.
* If you notice issues/have suggestions with one of my scripts, please feel free to submit the issue on github. I'm not going to go out of my way to support other distros but if its something reasonable or the script just stopped working on Mint or even if theres just a better way to do something, I'll take a look at it when I get time.

## LICENSE

Most of this stuff is just some hacked together shell scripts to automate various install/update tasks of other utilities. BUT if you want them to have a license, we'll say GPLv3 on my scripts.

I don't distribute any binaries/source/other resources for the applications that my scripts operate on, but obviously those applications would each be subject to their own individual licenses as well.

Forking the project is fine but I don't give consent to including my scripts on any corporate or for-profit distribution; they are intended for use on private computers only.


## Broken Scripts

Nothing that I'm aware of currently... but the one most prone to breaking based on past experience is the waterfox-classic updater; site changes a fair bit. Maybe one of these days, I'll get off my duff, figure out how to package things as *.deb files and create a PPA, then see if I can help the author... you know, actually trying to fix the problem instead of scripting a workaround ^_^
