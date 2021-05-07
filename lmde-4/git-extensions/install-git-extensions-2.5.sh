#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_DIR_PARENT=$(dirname "${SCRIPT_DIR}");
#echo "SCRIPT_DIR_PARENT is $SCRIPT_DIR_PARENT";

if [[ ! -f "${SCRIPT_DIR_PARENT}/functions.sh" ]]; then
    echo "Error: missing functions.sh; Extract github archive or clone git repo then run script from repo folder.";
    exit;
fi
. "${SCRIPT_DIR_PARENT}/functions.sh";

# get sudo prompt out of the way up front so that message displays will be cleaner
sudo ls -acl 2>&1 >/dev/null;

CHROME_WINDOWS_UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.157 Safari/537.36";

GITEXT_RELEASES_BASE_URL="https://github.com/gitextensions/gitextensions/releases/tag";
#Last release that supports Mono....
GITEXT_TARGET_VERSION="v2.51.05";

#older versions (may possibly be more stable on older versions of Linux)
#GITEXT_TARGET_VERSION="v2.51.04";
#GITEXT_TARGET_VERSION="v2.51.03";
#GITEXT_TARGET_VERSION="v2.51.02";
#GITEXT_TARGET_VERSION="v2.51.01";
#GITEXT_TARGET_VERSION="v2.51";
#GITEXT_TARGET_VERSION="v2.50.02";
#GITEXT_TARGET_VERSION="v2.50.01";
#GITEXT_TARGET_VERSION="v2.50";
#GITEXT_TARGET_VERSION="v2.49.03";
#GITEXT_TARGET_VERSION="v2.49.02";
#GITEXT_TARGET_VERSION="v2.49.01";
#GITEXT_TARGET_VERSION="v2.49";
#GITEXT_TARGET_VERSION="v2.48.05";

# define script paths
gitExtInstallDir="/opt/GitExtensions";
sysShDir="/usr/bin";
nemoActionsUserDir="${HOME}/.local/share/nemo/actions";
nemoActionsSystemDir="/usr/share/nemo/actions";
userLauncherScriptsDir="${nemoActionsUserDir}/scripts";
systemLauncherScriptsDir="${nemoActionsSystemDir}/scripts";

# define script flags
missingRequiredFiles="false";
requireNemoActions="true";
enableAllActions="false";
reinstallActionsOnly="false";
omitActions="false";
displayHelp="false";
noConditions="false";
isUserInstall="false";

# placeholder for whether sudo should be used or not
# this is only changed when isUserInstall=true
# for the purpose of not creating root-owned folders
# under the users home folder; for now, the script still
# requires sudo for installing mono / other dependencies
# but this may change in the future to allow a completely
# non-admin install
s='sudo';

#Set Passable flags
for passedarg in "$@"; do
    echo "passedarg is $passedarg"
    if [[ "${passedarg:0:1}" == "-" ]]; then
        # Check for options
		if [[ "-h" == "${passedarg}" || "--help" == "${passedarg}" ]]; then
			displayHelp="true";
		elif [[ "-r" == "${passedarg}" || "--reinstall-actions" == "${passedarg}" ]]; then
			reinstallActionsOnly="true";
		elif [[ "-o" == "${passedarg}" || "--omit-actions" == "${passedarg}" ]]; then
			omitActions="true";
		elif [[ "-C" == "${passedarg}" || "--no-conditions" == "${passedarg}" ]]; then
			noConditions="true";
		elif [[ "-u" == "${passedarg}" || "--user-install" == "${passedarg}" ]]; then
			isUserInstall="true";
		else
			echo "Unrecognized option '${passedarg}'";
			echo "";
			displayHelp="true";
		fi
    fi
done

if [[ "true" == "${displayHelp}" ]]; then
	echo "Expected usage:";
	echo "   $0 [options]";
	echo "";
	echo "Normally this script will install:";
	echo "Git Extensions ${GITEXT_TARGET_VERSION} and its dependencies, including Mono.";
	echo "In addition, it will create several context-menu actions for the Nemo File Manager (Cinnamon Desktop).";
	echo "Note: that the 2.x versions of Git Extensions are the last versions that run on Mono and that the newer 3.x versions are not Linux compatible using Mono.";
	echo "";
	echo "The Nemo actions can also be reinstalled independently using the -r, --reinstall-actions options."	;
	echo "";
	echo "OPTIONS:";
	echo "   -r, --reinstall-actions    Reinstalls Nemo actions without reinstalling Git Extensions/Mono";
	echo "   -o, --omit-actions         Omits Nemo actions when installing Git Extensions/Mono";
	echo "   -C, --no-conditions        Removes the 'Conditions' parameter from Nemo actions; may be useful for older versions of Nemo which do not support this option fully. Not recommended for Nemo v4.4.2+";
	echo "   -u, --user-install         Installs for the current user only. The default is do a system install under /opt; this option installs under the user's ~/.local/share folder instead. sudo is still required for installing dependencies.";
	exit;
fi

if [[ "true" == "${isUserInstall}" ]]; then
	gitExtInstallDir="${HOME}/.local/share/GitExtensions";
	s='';
else
	#get sudo prompt out of the way
	sudo ls -acl >/dev/null
fi

if [[ "true" != "${reinstallActionsOnly}" ]]; then
	if [[ ! -e /usr/bin/mono ]]; then
		echo "";
		echo "================================================================";
		echo "Installing Mono (required for GitExt on Linux) ...";
		echo "================================================================";
		if [[ ! -f "${SCRIPT_DIR_PARENT}/mono/install-mono.sh" ]]; then
			echo "ERROR: Missing mono installer; aborting script ..."
			echo "To resolve: Extract github archive or clone git repo then run script from repo folder.";
			exit;
		fi

		# Mono is required to run Git Extensions on Linux;
		# Make sure it is installed first
		/bin/bash "${SCRIPT_DIR_PARENT}/mono/install-mono.sh";
	fi

	echo "";
	echo "================================================================";
	echo "Installing dependencies ...";
	echo "================================================================";
	sudo dpkg --add-architecture i386;
	#sudo apt-get install --install-recommends -q -y curl git imagemagick language-pack-en perl unzip wget;
	sudo apt-get install --install-recommends -q -y curl git imagemagick perl unzip wget;

	echo "";
	echo "================================================================";
	echo "Downloading Git Extensions (This may take some time) ...";
	echo "================================================================";

	GITEXT_LAST_MONO_RELEASE_LINK="${GITEXT_RELEASES_BASE_URL}/${GITEXT_TARGET_VERSION}";

	# --location follows redirects
	PAGE_HTML_SOURCE=$(curl --location --user-agent "${CHROME_WINDOWS_UA}" "${GITEXT_LAST_MONO_RELEASE_LINK}");
	GITEXT_MONO_ZIP="";
	GITEXT_MONO_ZIP_DOWNLOAD_LINK=$(echo $PAGE_HTML_SOURCE | perl -0pe "s/>\s*</>\n</g" | grep -P "href.*Mono.zip" | perl -pe 's/^.*href="([^"]+)".*$/$1/g');
	GITEXT_SRC_ZIP="";
	GITEXT_SRC_ZIP_DOWNLOAD_LINK=$(echo $PAGE_HTML_SOURCE | perl -0pe "s/>\s*</>\n</g" | grep -P ">[^<>]*Source.*zip" -B 15 | grep -P "href.*zip" | perl -pe 's/^.*href="([^"]+)".*$/$1/g');

	HTTPS_PREFX="https://"
	if [[ ${#GITEXT_MONO_ZIP_DOWNLOAD_LINK} -gt 30 && ${#GITEXT_MONO_ZIP_DOWNLOAD_LINK} -lt 300 ]]; then
		#echo -e "\nValiditing Git Extensions mono link...";

		#check url prefix
		if [[ "http" != "${GITEXT_MONO_ZIP_DOWNLOAD_LINK:0:4}" ]]; then
			if [[ "github.com" == "${GITEXT_MONO_ZIP_DOWNLOAD_LINK:0:10}" ]]; then
				GITEXT_MONO_ZIP_DOWNLOAD_LINK="${HTTPS_PREFX}${GITEXT_MONO_ZIP_DOWNLOAD_LINK}";
			else
				GITEXT_MONO_ZIP_DOWNLOAD_LINK="${HTTPS_PREFX}github.com${GITEXT_MONO_ZIP_DOWNLOAD_LINK}";
			fi
		fi
	fi
	if [[ ${#GITEXT_SRC_ZIP_DOWNLOAD_LINK} -gt 30 && ${#GITEXT_SRC_ZIP_DOWNLOAD_LINK} -lt 300 ]]; then
		#echo -e "\nValiditing Git Extensions src link...";

		#check url prefix
		if [[ "http" != "${GITEXT_SRC_ZIP_DOWNLOAD_LINK:0:4}" ]]; then
			if [[ "github.com" == "${GITEXT_SRC_ZIP_DOWNLOAD_LINK:0:10}" ]]; then
				GITEXT_SRC_ZIP_DOWNLOAD_LINK="${HTTPS_PREFX}${GITEXT_SRC_ZIP_DOWNLOAD_LINK}";
			else
				GITEXT_SRC_ZIP_DOWNLOAD_LINK="${HTTPS_PREFX}github.com${GITEXT_SRC_ZIP_DOWNLOAD_LINK}";
			fi
		fi
	fi

	#print vars
	GITEXT_MONO_ZIP="${GITEXT_MONO_ZIP_DOWNLOAD_LINK##*/}";
	GITEXT_SRC_ZIP="GitExtensions-src-${GITEXT_SRC_ZIP_DOWNLOAD_LINK##*/}";
	echo "GITEXT_MONO_ZIP_DOWNLOAD_LINK: ${GITEXT_MONO_ZIP_DOWNLOAD_LINK}";
	echo "GITEXT_MONO_ZIP: ${GITEXT_MONO_ZIP}";
	echo ''
	echo "GITEXT_SRC_ZIP_DOWNLOAD_LINK: ${GITEXT_SRC_ZIP_DOWNLOAD_LINK}";
	echo "GITEXT_SRC_ZIP: ${GITEXT_SRC_ZIP}";

	#change to temp folder before downloading
	cd /tmp;

	#download mono zip
	wget --user-agent "${USER_AGENT}" "${GITEXT_MONO_ZIP_DOWNLOAD_LINK}" --output-document="${GITEXT_MONO_ZIP}" 2>/dev/null;

	#download src zip
	wget --user-agent "${USER_AGENT}" "${GITEXT_SRC_ZIP_DOWNLOAD_LINK}" --output-document="${GITEXT_SRC_ZIP}" 2>/dev/null;

	if [[ "" == "${GITEXT_MONO_ZIP}" || ! -e "${GITEXT_MONO_ZIP}" ]]; then
		echo "ERROR: Download of ${GITEXT_MONO_ZIP} failed. Aborting Script.";
		exit;
	fi

	echo "";
	echo "================================================================";
	echo "Installing Git Extensions...";
	echo "================================================================";

	#extract archives
	EXTRACTED_MONO_DIR="${GITEXT_MONO_ZIP%.zip}";
	EXTRACTED_SRC_DIR="${GITEXT_SRC_ZIP%.zip}";
	echo -e "\nExtracting Git Extensions mono zip...";
	/usr/bin/unzip "${GITEXT_MONO_ZIP}" -d "${EXTRACTED_MONO_DIR}/" >/dev/null;
	if [[ ! -e "${EXTRACTED_MONO_DIR}/GitExtensions/GitExtensions.exe" ]]; then
		echo "ERROR: Extracting of ${GITEXT_MONO_ZIP} failed. Aborting Script.";
		exit;
	fi

	mkdir "${EXTRACTED_SRC_DIR}";
	ZIP_ICONS_RELATIVE_PATH="gitextensions-2.51.05/GitExtensionsShellEx/Resources";

	/usr/bin/unzip -o "${GITEXT_SRC_ZIP}" "${ZIP_ICONS_RELATIVE_PATH}/*.ico" -d "${EXTRACTED_SRC_DIR}/" >/dev/null;

	ICONS_DIR="/tmp/git-ext-icons";
	if [[ -e "${EXTRACTED_SRC_DIR}" ]]; then
		mkdir "${ICONS_DIR}";
		EXTRACTED_ICONS_DIR="${EXTRACTED_SRC_DIR}/${ZIP_ICONS_RELATIVE_PATH}";

		convert "${EXTRACTED_ICONS_DIR}/git-extensions-logo.ico" "${ICONS_DIR}/git-extensions-logo.png"
		convert "${EXTRACTED_ICONS_DIR}/IconBrowseFileExplorer.ico" "${ICONS_DIR}/git-ext-browse.png"
		convert "${EXTRACTED_ICONS_DIR}/IconCloneRepoGit.ico" "${ICONS_DIR}/git-ext-clone.png"
		convert "${EXTRACTED_ICONS_DIR}/IconCommit.ico" "${ICONS_DIR}/git-ext-commit.png"
		convert "${EXTRACTED_ICONS_DIR}/IconPull.ico" "${ICONS_DIR}/git-ext-pull.png"
		convert "${EXTRACTED_ICONS_DIR}/IconPush.ico" "${ICONS_DIR}/git-ext-push.png"
		convert "${EXTRACTED_ICONS_DIR}/IconRepoCreate.ico" "${ICONS_DIR}/git-ext-create-new-repo.png"
		convert "${EXTRACTED_ICONS_DIR}/IconSettings.ico" "${ICONS_DIR}/git-ext-settings.png"
		convert "${EXTRACTED_ICONS_DIR}/IconBranchCheckout.ico" "${ICONS_DIR}/git-ext-checkout-branch.png"
		convert "${EXTRACTED_ICONS_DIR}/IconBranchCreate.ico" "${ICONS_DIR}/git-ext-create-branch.png"
		convert "${EXTRACTED_ICONS_DIR}/IconDiff.ico" "${ICONS_DIR}/git-ext-diff.png"
		convert "${EXTRACTED_ICONS_DIR}/IconFileHistory.ico" "${ICONS_DIR}/git-ext-file-history.png"
		convert "${EXTRACTED_ICONS_DIR}/IconResetFileTo.ico" "${ICONS_DIR}/git-ext-reset-file.png"
		convert "${EXTRACTED_ICONS_DIR}/IconRevisionCheckout.ico" "${ICONS_DIR}/git-ext-checkout-revision.png"
		convert "${EXTRACTED_ICONS_DIR}/IconStash.ico" "${ICONS_DIR}/git-ext-stash.png"
		convert "${EXTRACTED_ICONS_DIR}/IconAbout.ico" "${ICONS_DIR}/git-ext-about.png"
		convert "${EXTRACTED_ICONS_DIR}/IconAdded.ico" "${ICONS_DIR}/git-ext-added.png"
	fi

	#If icon files found then copy them into shared system icon (requires sudo)
	if [[ -e "${ICONS_DIR}" ]]; then
		if [[ "true" == "${isUserInstall}" ]]; then
			mkdir "${HOME}/.local/share/icons/GitExtensions";
			cp -a -t "${HOME}/.local/share/icons/GitExtensions" "${ICONS_DIR}/"*;
			sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${HOME}/.local/share/icons/GitExtensions";
			find "${HOME}/.local/share/icons/GitExtensions" -type f -exec chmod 740 "{}" \;;
		else
			sudo cp -a -t /usr/share/pixmaps/ "${ICONS_DIR}/"*;
			sudo chown root:root /usr/share/pixmaps/git*.png;
			sudo chmod 744 /usr/share/pixmaps/git*.png;
		fi
	fi

	#cleanup extracted src folders - this was only used for the icons
	# hardcode the path "/tmp/git-ext-icons", as ICONS_DIR can also point under Script dir and
	# we don't want to remove any resources that are included with the Script / in the Scripts dir
	rm -R "${EXTRACTED_SRC_DIR}" 2>/dev/null;
	rm -R "${ICONS_DIR}" 2>/dev/null;

	#handle extracting the mono installation zip...
	echo -e "\nSetting up Git Extensions wrapper scripts...";

	# if old install exists, then create backup but get it out of the way
	if [[ -d "${gitExtInstallDir}" ]]; then
		${s} mv "${gitExtInstallDir}" "${gitExtInstallDir}".$(date +'%Y%m%d%H%M').bak
	fi

	${s} mv "${EXTRACTED_MONO_DIR}/GitExtensions/" "${gitExtInstallDir}/";
	${s} mv "${GITEXT_MONO_ZIP}" "$(dirname "${gitExtInstallDir}")/${GITEXT_MONO_ZIP}";
	${s} mv "${GITEXT_SRC_ZIP}" "$(dirname "${gitExtInstallDir}")/${GITEXT_SRC_ZIP}";
	rm -r "${EXTRACTED_MONO_DIR}";

	#rename included shell script
	GIT_EXT_SH="${gitExtInstallDir}/gitext.sh";
	${s} mv "${GIT_EXT_SH}" "${GIT_EXT_SH}.orig";

	#create a new one that uses the full path to GitExtensions.exe
	${s} touch "${GIT_EXT_SH}";
	echo '#!/bin/bash' | ${s} tee -a "${GIT_EXT_SH}" >/dev/null;
	echo -e "/usr/bin/mono \"${gitExtInstallDir}/GitExtensions.exe\" \"\$@\" &\n\n" | ${s} tee -a "${GIT_EXT_SH}" >/dev/null;
	${s} chmod 755 "${GIT_EXT_SH}";

	#create a symlink
	if [[ "true" == "${isUserInstall}" ]]; then
		ln -fs "${GIT_EXT_SH}" "${HOME}/.local/bin/gitext";
	else
		sudo ln -fs "${GIT_EXT_SH}" "/usr/bin/gitext";
	fi

	#Get rid of plugins which cause issues in Linux
	rm "${gitExtInstallDir}/Plugins/Bitbucket.dll" 2>/dev/null
fi

if [[ "true" != "${omitActions}" ]]; then
	if [[ "" == "${SCRIPT_DIR}" || ! -d "${SCRIPT_DIR}" ]]; then
		echo "ERROR: SCRIPT_DIR is empty or does not exist; Aborting script.";
		exit;
	fi

	# define scripts to install
	helperScriptsArray=(  );
	helperScriptsArray+=("${sysShDir}/is-git-dir");
	helperScriptsArray+=("${sysShDir}/is-non-git-dir");
	helperScriptsArray+=("${sysShDir}/which-git-top-dir");
	for scriptPath in "${helperScriptsArray[@]}"; do
		sourcePath="${SCRIPT_DIR}${scriptPath}";
		if [[ ! -f "${sourcePath}" ]]; then
			echo "ERROR: Missing Required File '${sourcePath}'";
			missingRequiredFiles="true";
			continue;
		fi

		if [[ "true" == "${isUserInstall}" ]]; then
			cp -a -t "${HOME}/.local/bin" "${sourcePath}";
			chmod 750 "${HOME}/.local/bin/$(basename "${scriptPath}")";
		else
			sudo cp -a "${sourcePath}" "${scriptPath}";
			sudo chmod 755 "${scriptPath}";
		fi
	done

	# Make sure nemo actions/scripts folder exists
	if [[ "true" == "${isUserInstall}" ]]; then
		/usr/bin/mkdir -p --mode=750 "${userLauncherScriptsDir}" 2>&1 >/dev/null;
	else
		sudo /usr/bin/mkdir -p --mode=755 "${systemLauncherScriptsDir}" 2>&1 >/dev/null;
	fi

	launcherScriptsArray=(  );
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-browse.sh");
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-clone.sh");
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-commit.sh");
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-diff-file.sh");
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-file-history.sh");
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-init.sh");
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-pull.sh");
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-push.sh");
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-revert-file.sh");
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-settings.sh");
	launcherScriptsArray+=("${systemLauncherScriptsDir}/launch-gitext-stash.sh");
	for scriptPath in "${launcherScriptsArray[@]}"; do
		sourcePath="${SCRIPT_DIR}${scriptPath}";
		if [[ ! -f "${sourcePath}" ]]; then
			echo "ERROR: Missing Required File '${sourcePath}'";
			missingRequiredFiles="true";
			continue;
		fi

		if [[ "true" == "${isUserInstall}" ]]; then
			cp -a -t "${userLauncherScriptsDir}" "${sourcePath}";
			chmod 750 "${userLauncherScriptsDir}/$(basename "${scriptPath}")";
		else
			sudo cp -a "${sourcePath}" "${scriptPath}";
			sudo chmod 755 "${scriptPath}";
			sudo chown root:root "${scriptPath}";
		fi
	done

	nemoActionsArray=(  );
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-browse.nemo_action");
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-clone-background.nemo_action");
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-commit.nemo_action");
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-diff-file.nemo_action");
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-file-history.nemo_action");
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-init-background.nemo_action");
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-pull.nemo_action");
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-push.nemo_action");
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-revert-file.nemo_action");
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-settings.nemo_action");
	nemoActionsArray+=("${nemoActionsSystemDir}/gitext-stash-changes.nemo_action");

	for actionPath in "${nemoActionsArray[@]}"; do
		sourcePath="${SCRIPT_DIR}${actionPath}";
		if [[ ! -f "${sourcePath}" ]]; then
			echo "ERROR: Missing Required File '${sourcePath}'";
			missingRequiredFiles="true";
			continue;
		fi

		if [[ "true" == "${isUserInstall}" ]]; then
			cp -a -t "${nemoActionsUserDir}" "${sourcePath}";
			chmod 750 "${nemoActionsUserDir}/$(basename "${actionPath}")";
		else
			sudo cp -a "${sourcePath}" "${actionPath}";
			sudo chmod 644 "${actionPath}";
			sudo chown root:root "${actionPath}";
		fi
	done

	if [[ "true" == "${missingRequiredFiles}" ]]; then
		if [[ "true" == "${requireNemoActions}" ]]; then
			echo "Missing one or more required files; Aborting setup script...";
			echo "";
			echo "Script is not designed for standalone execution; clone full repo and try rerunning.";
			exit;
		else
			echo "Missing one or more required files; Nemo actions may not work...";
			echo "";
			echo "Script is not designed for standalone execution; clone full repo and try rerunning.";
		fi
	fi

	if [[ "true" == "${noConditions}" ]]; then
		find "${nemoActionsSystemDir}" -iname '*gitext*.nemo_action*' -exec sed -Ei 's/^(Condition)/#\1/g' "{}" \;;
	fi

	if [[ "true" == "${reinstallActionsOnly}" ]]; then
		echo "Nemo actions / scripts reinstalled.";
		echo "Exiting without Mono / GitExtensions download.";
		exit;
	fi
fi

# Make sure install folder perms allow "other" users to read
sudo chmod -R o+r "${gitExtInstallDir}";
sudo find "${gitExtInstallDir}" -type d -exec chmod o+x "{}" \;;
