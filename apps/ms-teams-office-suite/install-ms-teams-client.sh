#!/bin/bash

# See
# https://www.forbes.com/sites/jasonevangelho/2019/09/10/slack-gets-some-competition-microsoft-teams-is-under-development-for-linux/#6231e48727d5
# https://www.forbes.com/sites/jasonevangelho/2019/12/10/microsoft-just-released-its-first-native-office-app-for-linux/#c1fae1f70fa5
# https://www.theverge.com/2019/12/10/21004846/microsoft-office-linux-microsoft-teams-app-launch-public-preview
#
# https://teams.microsoft.com/download
# https://techcommunity.microsoft.com/t5/Microsoft-Teams-Blog/Microsoft-Teams-is-now-available-on-Linux/ba-p/1056267
#

sudo apt update -y;
sudo apt install -y gdebi-core libxml2:i386 libcanberra-gtk-module:i386 gtk2-engines-murrine:i386 libatk-adaptor:i386;

mkdir /tmp/ms-teams-client;
cd /tmp/ms-teams-client;

DEB_LINK="https://teams.microsoft.com/downloads/desktopurl?env=production&plat=linux&arch=x64&download=true&linuxArchiveType=deb";
DEB_NAME="ms-teams-client-amd64.deb";

wget --output-document="${DEB_NAME}" "${DEB_LINK}";
sudo gdebi --non-interactive "${DEB_NAME}";
