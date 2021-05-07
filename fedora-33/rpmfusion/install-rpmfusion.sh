#!/bin/bash

# https://docs.fedoraproject.org/en-US/quick-docs/setup_rpmfusion/
# https://www.debugpoint.com/2020/07/enable-rpm-fusion-fedora-rhel-centos/

sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm;

sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm;
