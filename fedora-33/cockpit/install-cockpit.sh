#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

# https://www.maketecheasier.com/managing-linux-system-with-cockpit/
# https://www.tecmint.com/manage-kvm-virtual-machines-using-cockpit-web-console/

sudo dnf install -y cockpit cockpit-composer cockpit-doc cockpit-machines cockpit-podman;

sudo systemctl enable --now cockpit;

#	# To use remotely on fedora
#	sudo firewall-cmd --add-service=cockpit --zone=public --permanent
#
#	# to use remotely on ubuntu
#	sudo ufw allow 9090/tcp
#	sudo ufw reload
