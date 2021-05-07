#!/bin/bash

sudo wget --output-document="/usr/bin/vcs-1.13.4.bash" "https://p.outlyer.net/vcs/files/vcs-1.13.4.bash";
sudo ln -s /usr/bin/vcs-1.13.4.bash /usr/bin/vcs;
sudo chmod a+x /usr/bin/vcs*;
