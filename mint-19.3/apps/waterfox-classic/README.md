
** WARNING: This script is currently broken. **

It was having some download issues and I haven't looked at it since [this issue](https://github.com/MrAlex94/Waterfox/issues/1356) was opened for the glibc requirements on LTS versions. I had an updated version on another PC that fixed the download issue but I haven't merged that in yet.

I'll probably look at it sometime after the next release is out / the official WF site stops listing the official download as having GLBIC v2.28 as a requirement.


# Waterfox Classic

This script is to automate installing / updating Waterfox Classic on Linux. If there is ever an official PPA / central repo package then that should take precedence over my script. This was written to make the install process less manual.

## What it does:

Installs waterfox to /opt/waterfox-classic/. If waterfox is already installed at the same location and the new archive is successfully dowloaded, it will first make a backup of the old install at /opt/waterfox-installation-backup.7z.

It will also:

* Create a symlink at /usr/bin/waterfox pointing to /opt/waterfox-classic/waterfox
* Create a menu shortcut (.desktop file) for both Waterfox and for "Private Waterfox" (so you can open a private instance with one click)
* Set the private shortcut to open dnsleaktest.com so you can verify your connection isn't leaking dns
* Save a copy of the installer under /opt/waterfox-archives (so you can run the previous installer if issues are encountered)

