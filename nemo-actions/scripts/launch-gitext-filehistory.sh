#!/bin/bash
gitTopLevelDir=$("/usr/bin/which-git-top-dir" "$1");
if [[ "" != "${gitTopLevelDir}" ]]; then
IconAcd "${gitTopLevelDir}";
    /usr/bin/mono "/opt/GitExtensions/GitExtensions.exe" filehistory "$1" &
fi
