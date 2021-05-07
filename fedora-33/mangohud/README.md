
## Description

This script installs the latest Mangohud

WIP - currently there are issues running MangoHud directly with wine on this type of system:

    $ inxi -SG
    System:    Host: \<host\> Kernel: 5.10.19-200.fc33.x86_64 x86_64 bits: 64 Desktop: Cinnamon 4.8.6 
    Distro: Fedora release 33 (Thirty Three) 
    Graphics:  Device-1: NVIDIA GM204 [GeForce GTX 970] driver: nvidia v: 460.32.03 
    Display: x11 server: Fedora Project X.org 1.20.10 driver: loaded: nvidia resolution: 1920x1080~60Hz 
    OpenGL: renderer: GeForce GTX 970/PCIe/SSE2 v: 4.6.0 NVIDIA 460.32.03 
     
    $ wine --version
    wine-6.3 (Staging)
     
    # attempt to run a game with mangohud: no hud info is displayed, errors on terminal
    # (also tried MANGOHUD=1 which also doesn't work but without the terminal output)
    /usr/bin/env WINEDEBUG="fixme-all" WINE_LARGE_ADDRESS_AWARE=1 WINEPREFIX="/gaming/lutris/games/gog-risen-2" "/usr/bin/mangohud" "/usr/bin/wine" start /D"C:/GOG/Risen2/system"



## Script Details

WIP - currently not sure what the root cause of the error is or how to fix it

## How to install:

*NOTE: This script has dependencies on resources from my repo so it will fail if you just download the install script by itself and try to run.*

To install run the following from a terminal:

```
git clone https://github.com/zpangwin/linux-setup-scripts.git;
find linux-setup-scripts -type f -iname '*.sh' -exec chmod a+rx "{}" \;;
cd linux-setup-scripts/fedora-33/apps/mangohud
./install-mangohud.sh
```

## Status


| Date of Test  | Target Platform/DE/arch | Hardware Type  | App Name / Version / Build                | Status  |
| ------------- | ------------------------| -------------- | ----------------------------------------- | ------- |
| 2021, Mar 07  | Fedora 33 Cinnamon  | Bare Metal     | Mangohud 0.6.1 (via dnf) | NOT WORKING |

