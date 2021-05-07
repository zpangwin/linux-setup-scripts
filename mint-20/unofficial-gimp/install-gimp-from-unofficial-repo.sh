#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

USE_GIMP_PS="true";

if [[ ! -f "${SCRIPT_DIR_PARENT}/functions.sh" ]]; then
    echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
    exit;
fi
. "${SCRIPT_DIR_PARENT}/functions.sh";

if [[ -z "${UBUNTU_CODENAME}" ]]; then
	MINT_CODENAME=$(gawk -F'=' '$1 ~ /^DISTRIB_CODENAME$/ {print $2}' /etc/lsb-release);
	MINT_RELEASE=$(gawk -F'=' '$1 ~ /^DISTRIB_RELEASE$/ {print $2}' /etc/lsb-release);
	UBUNTU_CODENAME=$(gawk -F'=' '$1 ~ /^DISTRIB_CODENAME$/ {print $2}' /etc/upstream-release/lsb-release);
	UBUNTU_RELEASE=$(gawk -F'=' '$1 ~ /^DISTRIB_RELEASE$/ {print $2}' /etc/upstream-release/lsb-release);
fi

case "$UBUNTU_CODENAME" in
	bionic) a=ok ;;
	focal) a=ok ;;
	*) a=FAIL ;;
esac

if [[ "ok" != "${a}" ]]; then
    echo "Error: This PPA only supports bionic and focal as of 2020 August 15th.";
    exit;
fi

echo "Adding custom repo source ...";
addAptCustomSource unofficial-gimp-ubuntuhandbook1 "deb http://ppa.launchpad.net/ubuntuhandbook1/gimp/ubuntu ${UBUNTU_CODENAME} main";

# avoid BABL issue if otto's ppa was previously used
sudo apt install -y ppa-purge && sudo ppa-purge ppa:otto-kesselgulasch/gimp 2>/dev/null >/dev/null;

sudo apt-get update 2>/dev/null >/dev/null;

sudo apt-get install -y --install-recommends gimp gimp-gmic git;

#sudo apt-get install -y --install-recommends gimp gimp-plugin-registry;

# update menu item to make 'GIMP' appear more obviously in name (stands out better when searching in menus)
sudo sed -Ei 's/^(Name[^=]*=)(GNU Image Manipulation Program)/\1GIMP (\2)/g' /usr/share/applications/gimp.desktop;

gimpVersion=$(dpkg -s gimp | gawk -F'\\s+' '$1 ~ /^Version:/ {print $2}'|gawk -F '.' '{ print $1"."$2 }');
gimpConfigDir="${HOME}/.config/GIMP/${gimpVersion}";

# check for chroot environment
if [[ "root" == "${USER}" && "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]; then
	gimpConfigDir="/etc/skel/.config/GIMP/${gimpVersion}";
	rm -r "${gimpConfigDir}" 2>/dev/null;

# otherwise check for existing config dir and make backup
elif [[ -d "${gimpConfigDir}" && ( "true" == "${USE_GIMP_PS}" || -d "${SCRIPT_DIR}/config" ) ]]; then
	mv "${gimpConfigDir}" "${gimpConfigDir}.$(date +'%Y%m%d-%H%M%S').bak";
	rm -r "${gimpConfigDir}" 2>/dev/null;
fi

startDir=$(pwd);
if [[ "true" == "${USE_GIMP_PS}" ]]; then
	git clone https://github.com/doctormo/GimpPs.git "${gimpConfigDir}";
	cd "${gimpConfigDir}"
	git checkout -B custom-changes;

	sed -Ei "s#version='2.8'#version=\$(dpkg -s gimp | gawk -F'\\\\\\\\s+' '\$1 ~ /^Version:/ {print \$2}'|gawk -F '.' '{ print \$1\".\"\$2 }')#g" tools/install.sh;
	sed -Ei 's#(gimp_ps_directory="\$HOME)/.gimp-(\$version")#\1/.config/GIMP/\2#g' tools/install.sh;
	git add tools/install.sh;
	git commit -m "$0: updated ./tools/install.sh to work with newer versions of GIMP.";

	# update keybindings for Ctrl+S so gimp doesn't add bad defaults on firs launch
	echo '(gtk_accel_path "<Actions>/file/file-save" "")' >> "${gimpConfigDir}/menurc";
	echo '(gtk_accel_path "<Actions>/file/file-overwrite" "<Primary>s")' >> "${gimpConfigDir}/menurc";
	git add "${gimpConfigDir}/menurc";
	git commit -m "$0: updated ./menurc to bind Ctrl+S to overwrite (save) file so that GIMP doesn't default it to the Save/Export dialog instead.";

elif [[ -d "${SCRIPT_DIR}/config" ]]; then
	mkdir -p "${HOME}/.config/GIMP" 2>/dev/null;
	cp -a "${SCRIPT_DIR}/config" "${HOME}/.config/GIMP";

# Make GIMP more user-friendly
elif [[ -d "${gimpConfigDir}" ]]; then
	mkdir -p "${gimpConfigDir}" 2>/dev/null;

	cd "${gimpConfigDir}"
	git init;
	git add *;
	git commit -m 'initial commit: default gimp settings';

	# Rebind Ctrl+S so that it Saves (overwrites) original file instead of bring up Export dialog (which does not save modifications in current tab)
	sed -Ei 's|(\(gtk_accel_path "<Actions>/file/file-save").*$|\1 "")|g' "${gimpConfigDir}/menurc";
	sed -Ei 's|(\(gtk_accel_path "<Actions>/file/file-overwrite").*$|\1 "<Primary>s")|g' "${gimpConfigDir}/menurc";
	git add "${gimpConfigDir}/menurc";
	git commit -m "$0: updated ./menurc to bind Ctrl+S to overwrite (save) file so that GIMP doesn't default it to the Save/Export dialog instead.";

	# Use Ctrl +/- for zoom in/out
	sed -Ei 's|(\(gtk_accel_path "<Actions>/view/view-zoom-in").*$|\1 "<Primary>equal")|g' "${gimpConfigDir}/menurc";
	sed -Ei 's|(\(gtk_accel_path "<Actions>/view/view-zoom-out").*$|\1 "<Primary>minus")|g' "${gimpConfigDir}/menurc";
	git add "${gimpConfigDir}/menurc";
	git commit -m "$0: updated ./menurc to bind Zoom in/out to Ctrl +/-";

	# Rebind Ctrl+D to De-select instead of Duplicate
	sed -Ei 's|(\(gtk_accel_path "<Actions>/image/image-duplicate") "<Primary>d"\)|\1 "")|g' "${gimpConfigDir}/menurc";
	sed -Ei 's|(\(gtk_accel_path "<Actions>/select/select-none").*$|\1 "<Primary>d")|g' "${gimpConfigDir}/menurc";
	git add "${gimpConfigDir}/menurc";
	git commit -m "$0: updated ./menurc to rebind Ctrl+D to De-select instead of Duplicate";
fi
cd "$startDir";
