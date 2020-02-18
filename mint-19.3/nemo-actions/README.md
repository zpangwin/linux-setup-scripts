# Nemo Actions

The Nemo file manager, like Nautilus which it was originally based on, supports adding custom context-menu (appears when you right-click) via nemo_action files. These are just text files that define what to display and what should get called when you click it. You can view a sample file that contains documentation at "/usr/share/nemo/actions/sample.nemo_action" or [online here](https://github.com/linuxmint/nemo/blob/master/files/usr/share/nemo/actions/sample.nemo_action).

This folder contains several custom nemo action files that I have wrote and their associated scripts. I like to put my "action" scripts under a separate subfolder under my nemo actions folder (NOT the existing scripts folder that appears at the same level as actions but a new folder). I also tend to install these under "/usr/share/nemo/actions" so that they are available to all users but they can also be installed for a single user under "$HOME/.local/share/nemo/actions".

**AFTER COPYING, YOU MUST SET PERMISSIONS FOR BOTH THE ACTIONS AND THEIR ASSOCIATED SCRIPTS BEFORE NEMO WILL USE THEM**

```
	sudo chown -R root:root /usr/share/nemo/actions;
	sudo chmod 644 /usr/share/nemo/actions/*.nemo_action;
	sudo chmod 755 /usr/share/nemo/actions/scripts/*;

```


------


## Actions for intergrating Git Extensions v2.5

** NOT NEEDED IF YOU INSTALLED FROM MY SCRIPT **

These are the manual install versions of the Nemo Actions created when running my Git Extensions setup script (see ../apps/mono+git-extensions/install-mono-and-git-extensions-2.5.sh). If you are installing these manually, it assumes that you already have mono installed and a Git Extensions install located at /opt/GitExtensions. The Linux install instructions for Git Extensions can be found [here](https://github.com/gitextensions/gitextensions/wiki/How-To:-run-Git-Extensions-on-Linux) but keep in mind that you must have the 2.5.x series or older as the newer 3.x series is not supported for mono.

These actions each work by calling a script particular to that action (browse, commit, etc) which in turn calls the main GitExtensions script (/opt/GitExtensions/gitext.sh) from the appropriate folder. It uses some additional helper scripts that are installed under /usr/bin during the setup script (or see ../usr-bin-scripts/\*git\* for manual install) for resolving the top-level folder of the repo and/or determining if a path is under a git repo or not.

At this time, the actions will display conditionally if you are using Mint 19.3 or newer (Nemo 4.4.2). Older versions of Nemo/Cinnamon/Mint should still display the actions but you might want to remove the Conditions property if you encounter issues with it displaying inconsistently. I don't believe Nemo currently supports sub-menus but if this is implemented, I may revise to more closely mimic the appearance of the Git Extensions menu on Windows. You should be able to invoke Browse/Commit actions from any file, subfolder, or subfolder-background of any git repo (except from the hidden .git folder). The FileHistory action can be invoked from any file under a git repo. The Clone action can be invoked from the background of any non-git folder.

* ./gitext-browse.nemo_action : Adds context-menu option for directly opening the Browse dialog (Commit history/git log)
* ./gitext-clone.nemo_action  : Adds context-menu option for directly opening the Clone dialog
* ./gitext-commit.nemo_action : Adds context-menu option for directly opening the Commit dialog
* ./gitext-filehistory.nemo_action : Adds context-menu option for directly opening the File History dialog

Required scripts:

* ./scripts/launch-gitext-browse.sh : copy to /usr/share/nemo/actions/scripts/
* ./scripts/launch-gitext-clone.sh : copy to /usr/share/nemo/actions/scripts/
* ./scripts/launch-gitext-commit.sh : copy to /usr/share/nemo/actions/scripts/
* ./scripts/launch-gitext-filehistory.sh : copy to /usr/share/nemo/actions/scripts/

------


## Actions for format conversions

I think these require ffmpeg and tesseract-ocr to be installed from central repos.

* ./convert-video-to-mp3.nemo_action : Converts/extracts audio from video files and saves as mp3. requires ffmpeg.
* ./convert-video-to-ogg.nemo_action : Converts/extracts audio from video files and saves as ogg. requires ffmpeg.
* ./get-image-text-via-ocr.nemo_action : Tries to do OCR on an image and save the text to a file and cleanup junk characters. requires tesseract-ocr. your mileage may vary depending on the image, tesseract's ability to match to text, and luck.


Required scripts:

* ./scripts/convert-video-to-mp3.sh : copy to /usr/share/nemo/actions/scripts/
* ./scripts/convert-video-to-ogg.sh : copy to /usr/share/nemo/actions/scripts/
* ./scripts/get-image-text-via-ocr.sh : copy to /usr/share/nemo/actions/scripts/


------


## Change owner actions

** NOT NEEDED IF YOU INSTALLED FROM MY SCRIPT **

I created this mostly to have a simplified list of users when I need to change ownership when I had Nemo "Open\[ed\] as Root".
This is described more fully in [nemo issue #2224](https://github.com/linuxmint/nemo/issues/2224). These are the manual install versions of the Nemo Actions created when running my Change Owner GUI setup script (see ../apps/chown-gui-wrapper/install-scripts-with-policykit-exception.sh). Alternately, I originally created this with a manual process which I documented [here](https://askubuntu.com/a/1181072).

These require yad to be installed from the central repo. It also uses some additional helper scripts that are installed under /usr/bin during the setup script (or see ../usr-bin-scripts/\*chown-gui\* for manual install) and requires that a policykit exception be added. Having a policykit exception allows a graphical application to run as root following the deprecation of gksu.

* ./change-owner-multiple-files.nemo_action : lets you change owner on a selection of files/folders
* ./change-owner-single-file.nemo_action : lets you change owner on a single of file/folder or folder background.

------

## Other misc actions

There is a small chance that the sublime action is added automatically after an install but I'm pretty sure it didn't and I had to make my own.

* ./edit-with-sublime.nemo_action : Adds a simple 'Edit with Sublime' option to files. Requires [sublime-text](https://www.sublimetext.com/3)
* ./show-display-option-on-desktop-context-menu.nemo_action | Adds "Display Settings" option to desktop context menu just like on Windows. See [nemo issue #2223](https://github.com/linuxmint/nemo/issues/2223)


