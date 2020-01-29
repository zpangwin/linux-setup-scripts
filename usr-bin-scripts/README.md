# Custom /usr/bin Scripts

These are all installed automatically if you are using my app setup scripts. This folder is just a copy from those so that it can be viewed directly without having to first run the scripts.



## Git Extensions v2.5



See the doc under Nemo Actions for more details.

These scripts are added by running ../apps/mono+git-extensions/install-mono-and-git-extensions-2.5.sh

1. ./is-git-dir : given a file or folder path, determines if it is under a git repo (excluding the hidden .git folder). The error codes are completely arbitrary; it just needs a non-zero exit code for the Nemo Action "Condition" parameter to work correctly.

2. ./is-non-git-dir : given a file or folder path, determines if it is NOT under a git repo (excluding the hidden .git folder). The error codes are completely arbitrary; it just needs a non-zero exit code for the Nemo Action "Condition" parameter to work correctly.

3. ./which-git-top-dir : given a file or folder path, prints the path to the top-level git dir of the repo or empty string. This is used to launch Git Extensions from any point of origin under the repo without it bitching about location or launch parameters. It is used by the launcher scripts associated with particular nemo actions.



## Chown GUI Wrapper



See the doc under Nemo Actions for more details.

These scripts are added by running ../apps/chown-gui-wrapper/install-scripts-with-policykit-exception.sh

1. ./pkexec-chown-gui-wrapper : wrapper script to give you toast notifications if you don't have yad installed AND which facilitates the handoff to policykit so that the chown-gui-wrapper script can be run with root perms even though it displays a gui. Requires adding a policykit exception if you are installing manually.

2. ./chown-gui-wrapper : handles all the work of creating a gui wrapper with yad and then applying any ownership changes to the path(s) in question. In hindsight, it probably would have been less work to write in python but what's done is done.



## Samba Config



This script is added by running ../apps/samba-config/install-scripts-with-policykit-exception.sh

The purpose of this is to allow you to continue using system-config-samba. It was a nice little gui someone wrote for managing setup of samba shares. Unfortunately, it stopped working after gksu was deprecated and I never saw an update that moved things to policykit. It's been awhile since I originally wrote this workaround so if its been updated, then probably the original authors setup should be preferred over my workaround. That said, I've been running it on Linux Mint 19.3 without any issues.

* ./pkexec-system-config-samba : wrapper script that lets you use system-config-samba through policykit instead of requiring gksu. Requires adding a policykit exception and updating the original menu shortcut (.desktop file) to use "Exec=/usr/bin/pkexec-system-config-samba" if you are installing manually.



## Discord to Systray

Ok, so I don't currently have a setup script for this one. There are some notes in:
../apps/discord/autostart-discord-minimized.txt

and maybe I'll update it to a setup script when I get back into gaming again.

The purpose of this script was that I wanted to have Discord in my startup applications (auto-starts) but I wanted it to open to the system tray rather than popping up a window and bugging me. I haven't been on discord in a while so it is possible (but I suspect unlikely) that they have fixed this issue in their application code directly. It is also possible that this script no longer works correctly or maybe there were still some window issues with this script; I don't really remember TBH. See [this reddit thread](https://www.reddit.com/r/discordapp/comments/ar9mbg/linux_how_can_i_start_discord_on_login_minimized/) for details... unforunately, since its reddit the thread has been archived (I disagree with reddit's practice of locking down/archiving old posts.. at least for technical discussions).


* ./discord-to-systray : attempts to put discord in its place (in the systray) without showing you a window when it first starts up.


