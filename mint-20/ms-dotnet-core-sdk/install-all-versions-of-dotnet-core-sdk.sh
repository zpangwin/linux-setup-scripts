#!/bin/bash

tempDir=$(mktemp -d /tmp/XXXX);
cd "${tempDir}";

# https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#2004-
#	https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-1804
#	https://stackoverflow.com/questions/52737293/install-dotnet-core-on-linux-mint-19

wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb;
sudo dpkg -i packages-microsoft-prod.deb;

# update apt's local cache
sudo apt-get update -y 2>/dev/null >/dev/null;

# install dotnet core sdk

# NOTE: As of 2020, July 03 there are only the 2 packages available in the MS deb file for ubuntu 20.04
#	Attempting to install 'dotnet-sdk-2.2'/'dotnet-sdk-3.0' will give errors that the packages could not be found
#
# See:
#		https://github.com/dotnet/core/issues/4360

# different apps target different versions so more is better if you are building a lot of projects
sudo apt-get install -y dotnet-sdk-2.1;
#sudo apt-get install -y dotnet-sdk-2.2;
#sudo apt-get install -y dotnet-sdk-3.0;
sudo apt-get install -y dotnet-sdk-3.1;

# opt-out of telemetry
echo "export DOTNET_CLI_TELEMETRY_OPTOUT='true';" | tee -a "${HOME}/.bashrc" "${HOME}/.profile" >/dev/null
export DOTNET_CLI_TELEMETRY_OPTOUT='true';

