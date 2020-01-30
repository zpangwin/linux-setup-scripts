
Installs newer ubuntu-make version of Eclipse JEE edition


* Adds PPA ppa:lyzardking/ubuntu-make for ubuntu-make, if not already present
* Installs ubuntu-make if not already present
* Uses Ubuntu-make to get a newer version of Eclipse than available in the central repo
* Installs elipse to "${HOME}/eclipse-jee"
* Creates a workspace directory at "${HOME}/eclipse-jee-workspace"
* Creates a menu shortcut (.desktop file)
* Menu automatically specifies workspace dir so you should not get prompted for one
