#!/bin/bash
gitTopLevelDir=$(/usr/bin/which-git-top-dir "$1");
if [[ "" != "${gitTopLevelDir}" ]]; then
	cd "${gitTopLevelDir}";
    /usr/bin/mono "/opt/GitExtensions/GitExtensions.exe" commit &
fi
