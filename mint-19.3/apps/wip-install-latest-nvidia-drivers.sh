#!/bin/bash

echo "";
echo "================================================================";
echo "Handling Proprietary NVIDIA Drivers...";
echo "================================================================";
sudo dpkg --add-architecture i386;

# ==============================================================================================
# Option 1 (newer; this is what I am using in this script):
# ==============================================================================================
# Use the 'ubuntu-drivers devices' command as recommended from the
# following links to identify the recommended nvidia driver for the current system:
#	https://linuxconfig.org/how-to-install-nvidia-drivers-on-linux-mint
#	https://computingforgeeks.com/how-to-install-nvidia-drivers-on-linux-mint-19-tara/
# ==============================================================================================
function installWithoutPPA() {
	local RECOMMENDED_UBUNTU_DRIVER=$(ubuntu-drivers devices | grep -P 'nvidia-driver.*recommended');
	#echo "RECOMMENDED_UBUNTU_DRIVER: $RECOMMENDED_UBUNTU_DRIVER";
	if [[ "" == "$RECOMMENDED_UBUNTU_DRIVER" ]]; then
		echo "ERROR: Unable to determine recommended NVIDIA driver from 'ubuntu-drivers devices' command.";
		return;
	fi
	local NVIDIA_PACKAGE_NAME=$(echo $RECOMMENDED_UBUNTU_DRIVER | sed 's|^driver : \([A-Za-z][-A-Za-z0-9_.]*\)[ \t].*$|\1|g');
	echo "Found recommended NVIDIA package name as '$NVIDIA_PACKAGE_NAME'";
	if [[ $NVIDIA_PACKAGE_NAME =~ ^nvidia.[1-9][0-9]*$ || $NVIDIA_PACKAGE_NAME =~ ^nvidia.driver.[1-9][0-9]*$ ]]; then
		local NVIDIA_VERSION=$(echo "$NVIDIA_PACKAGE_NAME" | sed 's|^.*[^0-9]\([0-9][0-9.]*\)$|\1|g');
		local NVIDIA_64BIT_LIBS="libnvidia-gl-${NVIDIA_VERSION} nvidia-dkms-${NVIDIA_VERSION}";
		local NVIDIA_32BIT_LIBS="libc6:i386 libnvidia-gl-${NVIDIA_VERSION}:i386";
		#echo -e "NVIDIA_VERSION: $NVIDIA_VERSION\nNVIDIA_32BIT_LIBS: $NVIDIA_32BIT_LIBS\nNVIDIA_64BIT_LIBS: $NVIDIA_64BIT_LIBS";
		sudo apt install -y --install-suggests $NVIDIA_PACKAGE_NAME $NVIDIA_64BIT_LIBS $NVIDIA_32BIT_LIBS nvidia-settings;
		if [[ "$?" != "0" ]]; then
			echo -e "ERROR: Failed to install packages:\n\t$NVIDIA_PACKAGE_NAME $NVIDIA_32BIT_LIBS nvidia-settings";
		fi
	else
		echo "ERROR: Unable to determine recommended package from 'ubuntu-drivers devices' output.";
		return;
	fi
}
# UPDATE: 4/4/2019:
#	Lutris saw I had v390 from this but suggested that I still upgrade
#   to the latest v418 or whatever. So updating to use original method
#		sudo add-apt-repository ppa:graphics-drivers/ppa
#		sudo apt update
#		sudo apt dist-upgrade
#
#installWithoutPPA;

# ==============================================================================================
# Option 2 (older method that I was previously using)
# -> including this only for reference in case option 1 ever breaks/stops working.
# This uses the 'official' PPA from the Ubuntu team which contains the
# Propreitary Nvidia drivers. See here for more info:
#	https://itsfoss.com/ubuntu-official-ppa-graphics/
#	https://launchpad.net/~graphics-drivers/+archive/ubuntu/ppa
# ==============================================================================================
#Nvidia proprietary drivers
#add-apt-repository -y ppa:graphics-drivers/ppa;
# updated to the below format to prevent errors the following error under Linux Mint 19:
#           root@<mycomputer> / #/usr/bin/add-apt-repository ppa:graphics-drivers/ppa
#               You are about to add the following PPA:
#               Traceback (most recent call last):
#                   File "/usr/lib/linuxmint/mintSources/mintSources.py", line 1557, in <module>
#               add_repository_via_cli(ppa_line, codename, options.forceYes, use_ppas)
#                   File "/usr/lib/linuxmint/mintSources/mintSources.py", line 141, in add_repository_via_cli
#                   print(" %s" % (ppa_info["description"]))
#               UnicodeEncodeError: 'ascii' codec can't encode characters in position 1000-1003: ordinal not in range(128)
#
#'This aprostrophe is just to fix sublime syntax highlighting from thinking there is a continuation of a wrapped string
# ==============================================================================================
#First check for the source in the apt *.list files contents
function installNvidiaPPAandLatestDrivers() {
	local IS_NVIDIA_REPO_ADDED=$(grep -P -R -i '(nvidia|graphics\-drivers)' /etc/apt/sources.list.d/* | wc -l);
	if [[ "0" == "${IS_NVIDIA_REPO_ADDED}" ]]; then
		#if not found, then also check the apt *.list file names
		IS_NVIDIA_REPO_ADDED=$(ls -acl /etc/apt/sources.list.d/* | grep -P -i '(nvidia|graphics\-drivers)' | wc -l);
	fi
	#If nvidia has not been added to the sources, then add the ppa
	if [[ "0" == "${IS_NVIDIA_REPO_ADDED}" ]]; then
		echo "The Official Ubuntu PPA for NVIDIA drivers was not present; adding now...";
		LC_ALL=C.UTF-8 sudo add-apt-repository -y ppa:graphics-drivers/ppa;
		local NVIDIA_REPO_ADDED_OK="$?";
		if [[ "0" == "${NVIDIA_REPO_ADDED_OK}" ]]; then
			echo "The Official Ubuntu PPA for NVIDIA drivers was added successfully.";
		else
			echo "ERROR: Failed to add Official Ubuntu PPA for NVIDIA drivers; updating list of packages...";
			return;
		fi
	else
		echo "The Official Ubuntu PPA for NVIDIA drivers was already present; updating list of packages...";
	fi
	#Update cached list of available software
	sudo apt-get update;

    #Attempt to get the latest Nvidia proprietary driver package name and install it
    local NVIDIA_PACKAGE_NAME=$(apt-cache search nvidia | grep -i -v "\-dev" | grep -P -i "^nvidia\-driver\-\d+\s" | sort | tail -n 1 | perl -pe "s/^(nvidia\-driver\-\d+)\s.*$/\$1/g");
    if [[ $NVIDIA_PACKAGE_NAME =~ ^nvidia.[1-9][0-9]*$ || $NVIDIA_PACKAGE_NAME =~ ^nvidia.driver.[1-9][0-9]*$ ]]; then
    	echo "Found package '$NVIDIA_PACKAGE_NAME'; installing...";
        #sudo apt install --install-recommends -y "${NVIDIA_PACKAGE_NAME}";

		local NVIDIA_VERSION=$(echo "$NVIDIA_PACKAGE_NAME" | sed 's|^.*[^0-9]\([0-9][0-9.]*\)$|\1|g');
		local NVIDIA_64BIT_LIBS="libnvidia-gl-${NVIDIA_VERSION} nvidia-dkms-${NVIDIA_VERSION}";
		local NVIDIA_32BIT_LIBS="libc6:i386 libnvidia-gl-${NVIDIA_VERSION}:i386";
		#echo -e "NVIDIA_VERSION: $NVIDIA_VERSION\nNVIDIA_32BIT_LIBS: $NVIDIA_32BIT_LIBS\nNVIDIA_64BIT_LIBS: $NVIDIA_64BIT_LIBS";
		sudo apt install -y --install-suggests $NVIDIA_PACKAGE_NAME $NVIDIA_64BIT_LIBS $NVIDIA_32BIT_LIBS nvidia-settings;
		if [[ "$?" != "0" ]]; then
			echo -e "ERROR: Failed to install packages:\n\t$NVIDIA_PACKAGE_NAME $NVIDIA_32BIT_LIBS nvidia-settings";
		fi
    else
		echo "ERROR: Failed to find nvidia package to install...";
		return;
    fi
}
installNvidiaPPAandLatestDrivers;

# ==============================================================================================
# Now check for an issue that can sometimes prevent steam from launching
# when using the proprietary NVIDIA drivers...
#	https://askubuntu.com/questions/834254/steam-libgl-error-no-matching-fbconfigs-or-visuals-found-libgl-error-failed-t
#	https://github.com/ValveSoftware/steam-for-linux/issues/5884
#		=> Swrast is mesa's slower software renderer and hints that your nvidia driver
#			install is broken or incomplete. You may need libc6:i386 installed before
#			running nvidia's manual installer or use an appropriate PPA like
#			https://launchpad.net/~graphics-drivers/+archive/ubuntu/ppa.
#		=> mostly likely need to run something like
#				sudo apt install nvidia-driver-410 nvidia-driver-410:i386
#		   or maybe
#				sudo apt install libnvidia-gl-410:i386
#		   The nvidia driver needs the running kernel module version to match the
#		   userspace version, and the 32 bit userspace and 64 bit userspace libraries
#		   are in separate packages on ubuntu.
#
# After installing NVIDIA and then rebooting (without the below fix).
# If you run steam from terminal, it gives:
#	~$ /usr/bin/steam
#	Running Steam on linuxmint 19.1 64-bit
#	STEAM_RUNTIME is enabled automatically
#	Pins up-to-date!
#	Installing breakpad exception handler for appid(steam)/version(1550534751)
#	libGL error: No matching fbConfigs or visuals found
#	libGL error: failed to load driver: swrast
# ==============================================================================================


#install vulkin
sudo apt install libvulkan1 libvulkan1:i386;
