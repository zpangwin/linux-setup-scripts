This is for installing Git Extensions 2.5 under Linux

./install-mono-and-git-extensions-2.5.sh will:

* Install mono if you don't already have it
* Extract Git Extensions image icons from source, convert them, and install them as system icons
* Download and install Git Extensions 2.5 and install it to /opt/GitExtensions/
* Create several helper scripts for git under /usr/bin/
* Create several launcher scripts for launching various dialogs relative to a path in a given git repo.
* Create several context-menu items for Nemo (e.g. Nemo Actions)

What works:

* Pretty much everything; this install has been pretty stable for me for awhile

What needs work:

* Need to update scripts be consistent with my other path usage: e.g. to move the launcher scripts from old location of /opt/GitExtensions/nemo-scripts to new location of /usr/share/nemo/actions/scripts as I have been doing elsewhere.
* Omit "Conditions" parameter if on older versions of Nemo.. maybe? Or display a toast noticiation warning maybe.

After installation, you should be able to open Nemo and:

* Right-click in the background of any non-git repo folder and see "GitExt Clone"
* Right-click on file or folder (or folder background) under a git repo and see "GitExt Browse" and "GitExt Commit"
* Right-click on file under a git repo and see "GitExt FileHistory"

If you are on an older version of Linux Mint (e.g. earlier than v19.3) or using an older version of Nemo (earlier than v4.4.2) then the Nemo actions may behave differently for you. The actions rely on a new "Conditions" feature (described [here](https://github.com/linuxmint/nemo/pull/2056)) that allows actions to display conditionally. On older versions where this is not present, you can just remove the "Conditions" property from the actions file to force it to always display (e.g. don't consider whether you are in a git repo or not).
