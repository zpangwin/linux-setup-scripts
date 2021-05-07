#!/bin/bash

echo "Installing dependencies ...";
sudo apt-get install -y git python3 python3-pip python3-setuptools python3-venv;

echo "Installing protontricks..."
sudo python3 -m pip install protontricks;


