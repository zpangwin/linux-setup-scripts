#!/bin/bash

# get the sudo prompt out of the way up front
sudo ls -acl 2>&1 >/dev/null;

sudo apt install -y yad;

sudo cp -a ./usr/bin/chown-gui-wrapper /usr/bin/chown-gui-wrapper;
sudo cp -a ./usr/bin/pkexec-chown-gui-wrapper /usr/bin/pkexec-chown-gui-wrapper;
sudo cp -a ./usr/share/nemo/actions/change-owner.nemo_action /usr/share/nemo/actions/change-owner.nemo_action;

sudo chown root:root /usr/bin/chown-gui-wrapper;
sudo chown root:root /usr/bin/pkexec-chown-gui-wrapper;
sudo chown root:root /usr/share/nemo/actions/change-owner.nemo_action;

sudo chmod 755 /usr/bin/chown-gui-wrapper;
sudo chmod 755 /usr/bin/pkexec-chown-gui-wrapper;
sudo chmod 644 /usr/share/nemo/actions/change-owner.nemo_action;

sudo cp -a /usr/share/nemo/actions/change-owner.nemo_action /usr/share/nemo/actions/change-owner-single-file.nemo_action;
sudo mv /usr/share/nemo/actions/change-owner.nemo_action /usr/share/nemo/actions/change-owner-multiple-files.nemo_action;

sudo sed -i -E 's/^(Selection)=s/\1=m/' /usr/share/nemo/actions/change-owner-multiple-files.nemo_action;

