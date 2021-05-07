#!/bin/bash

tempDir=$(mktemp -d /tmp/XXXX);
cd "${tempDir}";

#	https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-1804
#	https://stackoverflow.com/questions/52737293/install-dotnet-core-on-linux-mint-19

wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb;
sudo dpkg -i packages-microsoft-prod.deb;

# update apt's local cache
sudo apt-get update -y 2>/dev/null >/dev/null;

# install dotnet core sdk
# different apps target different versions but if space is a concern, then only install what you need
sudo apt-get install -y dotnet-sdk-3.1;

# opt-out of telemetry
echo "export DOTNET_CLI_TELEMETRY_OPTOUT='true';" | tee -a "${HOME}/.bashrc" "${HOME}/.profile" >/dev/null
export DOTNET_CLI_TELEMETRY_OPTOUT='true';

