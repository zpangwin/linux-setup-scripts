#!/bin/bash

#get password prompt out of the way so that output isn't disjointed
sudo ls -acl 2>&1 >/dev/null;

# Check if already installed... version in central repo is ancient and no longer works
is_installed=$(which youtube-dl 2>/dev/null|wc -l);
if [[ "1" == "${is_installed}" ]]; then
    # If installed, check version
    installed_from_central_repo=$(apt search youtube-dl|grep -P '^i'|wc -l);
    if [[ "1" == "${installed_from_central_repo}" ]]; then
        sudo apt-get remove -y youtube-dl;
    else
        # if it is already installed and NOT from central repo, then either this script was already run
        # OR ytdl was installed via pip / pip3
        ytdl_version=$(youtube-dl --version);
        six_months_ago=$(date -d "today - 6 month" "+%F");

        too_old="false";
        if [[ "${ytdl_yyyy:0:4}" -lt "${sixmon_yyyy:0:4}" ]]; then
            too_old="true";

        elif [[ "${ytdl_yyyy:0:4}" == "${sixmon_yyyy:0:4}" && "${ytdl_version:5:2}" -le "${six_months_ago:5:2}" ]]; then
            too_old="true";
        fi

        if [[ "true" == "${too_old}" ]]; then
            echo "WARNING: youtube-dl version ${ytdl_version} is already installed but it's older than 6 months.";
            exit;
        fi
    fi
fi

#
# https://github.com/ytdl-org/youtube-dl
#
sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl;
sudo chmod a+rx /usr/local/bin/youtube-dl;


