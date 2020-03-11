#!/bin/bash
echo "";
echo "================================================================";
echo "Removing Proprietary NVIDIA Drivers...";
echo "================================================================";

#uninstall vulkin
echo "Removing vulkan packages ...";
sudo apt-get purge -y libvulkan1 libvulkan1:i386

#uninstall nvidia drivers
echo "Removing nvidia related packages ...";
sudo apt-get purge -y nvidia* libnvidia*;

# Remove PPA if present
echo "Checking for and removing any nvidia PPA ...";

# 3.1 - make a full dir backup, just to be safe
fileTimestamp=$(date +'%Y%m%d-%H%M');
sudo cp -a /etc/apt/sources.list.d /etc/apt/sources.list.d-${fileTimestamp}-before-removing-nvidia-driver-ppa-bak;

# 3.2 - remove any sources with nvidia in the file name
sudo find /etc/apt/sources.list.d -iname '*nvidia*.list' -type f -delete;
sudo find /etc/apt/sources.list.d -iname '*graphics*drivers*.list' -type f -delete;

# 3.3 - loop through sources and check for nvidia
find /etc/apt/sources.list.d -iname '*.list' -type f -print0 |
while IFS= read -r -d '' filepath; do
	# count matches
	hasNiviaReferences=$(grep -Pi '(nvidia|graphics\-drivers)' "$filepath"|wc -l);

	# if no matches, the skip any further processing
	if [[ "0" == "${hasNiviaReferences}" ]]; then
		continue;
	fi

	# otherwise make a backup
	sudo cp -a "$filepath" "${filepath}${fileTimestamp}.bak";

	# then remove nvidia refs from file
	sudo sed -i '/^.*nvidia.*/d' "$filepath";
	sudo sed -i '/^.*graphics.*drivers.*/d' "$filepath";

	# if reserved files, then skip any further processing
	filename=$(basename "$filepath");
	if [[ "official-package-repositories.list" == "${filename}" ]]; then
		continue;
	fi
	if [[ "additional-package-repositories.list" == "${filename}" ]]; then
		continue;
	fi

	# take active line count
	activeLineCount=$(cat "$filepath"|grep -Pv '^(#|$)'|wc -l);

	# only if active line count is zero, delete file
	if [[ "0" == "${activeLineCount}" ]]; then
		sudo rm "$filepath";
	fi
done

echo "";
echo "Finished removing nvidia packages and/or sources.";
echo "";
