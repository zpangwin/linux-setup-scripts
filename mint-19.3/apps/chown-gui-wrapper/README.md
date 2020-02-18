
I created this mostly to have a simplified list of users when I need to change ownership when I had Nemo "Open\[ed\] as Root". This is described more fully in [nemo issue #2224](https://github.com/linuxmint/nemo/issues/2224). Alternately, I originally created this with a manual process which I documented [here](https://askubuntu.com/a/1181072).


install-scripts-with-policykit-exception.sh will:

* install the main script responsible for creating the gui and applying the owner changes to /usr/bin/chown-gui-wrapper
* install the wrapper script for policykit to /usr/bin/pkexec-chown-gui-wrapper
* create policykit exceptions so that you can run the script as root or when using the "Open as Root" option in Nemo (or be prompted for creds as regular user).
* install nemo-actions so that the option "Change Owner/Group" will appear in right-click menus in Nemo

