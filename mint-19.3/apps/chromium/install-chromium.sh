#!/bin/bash

sudo apt update;

sudo apt install -y --install-recommends chromium-browser;

# fix shortcut to avoid stupid keyring prompts
if [[ ! -e /usr/share/applications/chromium-browser.desktop.orig ]]; then
    cp -a /usr/share/applications/chromium-browser.desktop /usr/share/applications/chromium-browser.desktop.orig;
fi
sudo sed -i -E 's/^(Exec=chromium\-browser)( \-\-incognito| %U|)$/\1 \-\-password-store=basic \2/g' /usr/share/applications/chromium-browser.desktop;
