## Description

Disable or restore the Caps Lock key on Lint Mint 19.x

After running the script, reboot PC for the changes to take effect.


You can also search for "alias nocaps" in the ../new-profile/.bash_aliases file for a non-peristent solution (e.g. applies change for a single login) if you don't want to wait on a rebnoot / don't want to make the change permanent.

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/mint-20.x/apps/caps-lock
./disable-capslock-key-after-reboot.sh

# then when you are ready
sudo reboot
```

## Status

Last tested : ??? ... maybe Jan-Feb 2020

Last status : working (Mint 19.3 Cinnamon x64)
