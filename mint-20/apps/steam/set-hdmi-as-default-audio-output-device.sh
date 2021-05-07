#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

if [[ ! -f "${SCRIPT_DIR_PARENT}/functions.sh" ]]; then
    echo "Error: missing functions.sh; Extract archive or clone git repo then run script from there.";
    exit;
fi
. "${SCRIPT_DIR_PARENT}/functions.sh";

# This is mostly an issue with Proton/SteamPlay games and largely does not apply to native games

# 0. make sure pulse audio is installed
sudo apt-get install -y pavucontrol;

# 1. get pulse-audio hdmi device name and index
hdmiDeviceName=$(pactl list short sinks|gawk -F'\\s+' '$2 ~ /^.*[Hh][Dd][Mm][Ii].*$/ { print $2 }');
hdmiDeviceIndex=$(pactl list short sinks|gawk -F'\\s+' '$2 ~ /^.*[Hh][Dd][Mm][Ii].*$/ { print $1 }');

if [[ '' == "$hdmiDeviceName" ]]; then
	echo "ERROR: failed to get hdmi device name from \$(pactl list short sinks)";
	exit;
fi
if [[ '' == "$hdmiDeviceIndex" ]]; then
	echo "ERROR: failed to get hdmi device index from \$(pactl list short sinks)";
	exit;
fi
if [[ ! $hdmiDeviceIndex =~ ^[0-9]{1,}$ ]]; then
	echo "ERROR: found invalid hdmi device index '${hdmiDeviceIndex}' from \$(pactl list short sinks)";
	exit;
fi

# 2. permanently set hdmi audio as the default pulse-audio device
sudo cp -a /etc/pulse/default.pa /etc/pulse/default.pa.$(date +'%Y%m%d%H%M%S').bak;

isPulseDefaultOutputSet=$(grep -Pc '^set-default-sink .*$' /etc/pulse/default.pa);
if [[ '0' == "${isPulseDefaultOutputSet}" ]]; then
	# add new definition above comment
	sudo sed -Ei "s/^(#set[-]default[-]sink output)\$/\\1\\nset-default-sink ${hdmiDeviceIndex}/g" /etc/pulse/default.pa

else
	# replace existing definition
	sudo sed -Ei "s/^(set[-]default[-]sink .*)\$/\\1\\nset-default-sink ${hdmiDeviceIndex}/g" /etc/pulse/default.pa
fi


# 3. update active pulse-audio session to use hdmi as output
sudo pactl set-default-sink $(pactl list short sinks|gawk -F'\\s+' '$2 ~ /^.*[Hh][Dd][Mm][Ii].*$/ { print $2 }');

# 4. "It seems some games are using alsa instead of pulse."
# Source:
#	https://steamcommunity.com/app/221410/discussions/0/618458030650103916/
#	https://github.com/ValveSoftware/steam-for-linux/issues/5254

# 4.1 check for missing defs
isMissingAlsaDefs="false";

for f in $(echo "$HOME/.asoundrc /etc/asound.conf"); do echo "f: $f"; done

if [[ "true" == "${isMissingAlsaDefs}" ]]; then
	sudo cp -a /etc/pulse/default.pa /etc/pulse/default.pa.$(date +'%Y%m%d%H%M%S').bak;
fi

