#!/bin/bash

sudo apt-get update 2>&1 >/dev/null;

sudo apt-get install -y --install-recommends libpam-gnome-keyring chromium-browser;

