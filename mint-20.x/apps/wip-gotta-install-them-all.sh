#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

DIR_NAME=$(basename "${SCRIPT_DIR}")
#echo "DIR_NAME is $DIR_NAME";

IS_DRY_RUN="false";
if [[ "--dryrun" == "$1" || "--dryrun" == "$1" ]]; then
	IS_DRY_RUN="true";
fi

if [[ ! -f "./functions.sh" ]]; then
	echo "ERROR: This script should be run from the apps dir of the setup scripts repo.";
	echo "Aborting script...";
	exit;
fi

# get sudo prompt out of the way before other messaging
sudo ls -acl 2>/dev/null >/dev/null;

# create a map
declare -A dirScriptMap;

find "${SCRIPT_DIR}" -mindepth 2 -maxdepth 2 -type f -iname '*.sh' -print0 |
while IFS= read -r -d '' shellScript; do
	# skip empty results
	if [[ "" == "${shellScript}" ]]; then
		continue;
	fi

	# make sure it's executable...
	if [[ ! -x "${shellScript}" ]]; then
		chmod a+x "${shellScript}";
	fi

	scriptName=$(basename "${shellScript}");
	parentDir=$(dirname "${shellScript}");

	# debug
	#echo "======================================="
	#printf '\tshellScript: %s\n\tparentDir: %s\n\tscriptName: %s\n' "$shellScript" "$parentDir" "$scriptName";

	# skip certain scripts
	if [[ $scriptName =~ ^.*capslock.*$ || $scriptName =~ ^.*pince.*$ ]]; then
		continue;
	fi

	# debug
	#echo "======================================="
	#printf '\tshellScript: %s\n\tparentDir: %s\n\tscriptName: %s\n' "$shellScript" "$parentDir" "$scriptName";

	# TODO - replace this case statment with an array...
	case "${scriptName}" in


	 install-wine-devel-from-winehq-repo.sh)
		# Skipit
		continue;
		;;

	 install-wine-dev-from-winehq-repo.sh)
		# Skipit
		continue;
		;;

	 install-wine-stable-from-winehq-repo.sh)
		# Skipit
		continue;
		;;

	 backup-official-waterfox.sh)
		# Skipit
		continue;
		;;

	 remove-waterfox-from-unofficial-dev-ppa.sh)
		# Skipit
		continue;
		;;

	 launch-dual-boot-ff-as-read-only.sh)
		# Skipit
		continue;
		;;

	 setup-dual-boot-ff-as-read-only.sh)
		# Skipit
		continue;
		;;

	 download-and-install-official-waterfox.sh)
		# The PPA script should be preferred instead
		continue;
		;;
	 install-mono.sh)
		# The Mono + GitExt script should be preferred instead
		continue;
		;;
	 *) a=3 ;;
	esac

	# debug
	echo "======================================="
	printf '\tshellScript: %s\n\tparentDir: %s\n\tscriptName: %s\n' "$shellScript" "$parentDir" "$scriptName";

	cd "${parentDir}";
	bash "${scriptName}";
done
