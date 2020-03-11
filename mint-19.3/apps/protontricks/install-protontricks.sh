#!/bin/bash

sudo apt-get install -y git python3 python3-pip python3-setuptools python3-venv;
python3 -m pip install --user pipx;
~/.local/bin/pipx ensurepath;
pipx install protontricks;

