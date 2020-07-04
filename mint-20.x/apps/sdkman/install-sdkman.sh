#!/bin/bash


# https://sdkman.io/install

if [[ "" == "${USER_AGENT}" ]]; then
	USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36";
fi

curl -L -A "${USER_AGENT}" --silent "https://get.sdkman.io" | bash

source "$HOME/.sdkman/bin/sdkman-init.sh"

if [[ '1' == $(sdk version|tail -1|grep -P 'SDKMAN \d+' -c) ]]; then
	echo "INSTALL SUCCESSFUL";
else
	echo "ERROR: MANUALLY VERIFY INSTALL by running: sdk version";
fi

