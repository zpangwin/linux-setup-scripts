#!/bin/bash

requireNemoActions="true";

SCRIPT_DIR="$( cd "$( /usr/bin/dirname "${BASH_SOURCE[0]}" )" && /bin/pwd )";
echo "SCRIPT_DIR: ${SCRIPT_DIR}";

# define script paths and flags
missingRequiredFiles="false";
sysShDir="/usr/bin";
nemoActionsDir="/usr/share/nemo/actions";
nemoShDir="${nemoActionsDir}/scripts";

if [[ "" == "${SCRIPT_DIR}" || ! -d "${SCRIPT_DIR}" ]]; then
	echo "ERROR: SCRIPT_DIR is empty or does not exist; Aborting script.";
	exit;
fi

#get sudo prompt out of the way
sudo ls -acl >/dev/null

# Make sure nemo actions/scripts folder exists
sudo mkdir -p "${nemoShDir}" 2>&1 >/dev/null;

# define scripts to install
requiredScriptsArray=(  );
requiredScriptsArray+=("${sysShDir}/is-git-dir");
requiredScriptsArray+=("${sysShDir}/is-non-git-dir");
requiredScriptsArray+=("${sysShDir}/which-git-top-dir");
requiredScriptsArray+=("${nemoShDir}/launch-gitext-browse.sh");
requiredScriptsArray+=("${nemoShDir}/launch-gitext-clone.sh");
requiredScriptsArray+=("${nemoShDir}/launch-gitext-commit.sh");
requiredScriptsArray+=("${nemoShDir}/launch-gitext-filehistory.sh");

for scriptPath in "${requiredScriptsArray[@]}"; do
	sourcePath="${SCRIPT_DIR}${scriptPath}";
	if [[ ! -f "${sourcePath}" ]]; then
		echo "ERROR: Missing Required File '${sourcePath}'";
		missingRequiredFiles="true";
	else
		sudo cp -a "${sourcePath}" "${scriptPath}";
		sudo chmod 755 "${scriptPath}";
	fi
done

requiredNemoActionsArray=(  );
requiredNemoActionsArray+=("${nemoActionsDir}/gitext-browse.nemo_action");
requiredNemoActionsArray+=("${nemoActionsDir}/gitext-clone-background.nemo_action");
requiredNemoActionsArray+=("${nemoActionsDir}/gitext-commit.nemo_action");
requiredNemoActionsArray+=("${nemoActionsDir}/gitext-filehistory.nemo_action");

for actionPath in "${requiredNemoActionsArray[@]}"; do
	sourcePath="${SCRIPT_DIR}${actionPath}";
	if [[ ! -f "${sourcePath}" ]]; then
		echo "ERROR: Missing Required File '${sourcePath}'";
		missingRequiredFiles="true";
	else
		sudo cp -a "${sourcePath}" "${actionPath}";
		sudo chmod 644 "${actionPath}";
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

if [[ "" == "${FIREFOX_WINDOWS_USER_AGENT}" ]]; then
   FIREFOX_WINDOWS_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:62.0) Gecko/20100101 Firefox/62.0";
fi
if [[ "" == "${CHROME_WINDOWS_USER_AGENT}" ]]; then
    CHROME_WINDOWS_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3445.2 Safari/537.36";
fi
if [[ "" == "${WINDOWS_USER_AGENT}" ]]; then
    WINDOWS_USER_AGENT="${FIREFOX_WINDOWS_USER_AGENT}";
fi
if [[ "" == "${USER_AGENT}" ]]; then
    USER_AGENT="${WINDOWS_USER_AGENT}";
fi

echo "";
echo "================================================================";
echo "Installing Depenencies from central repos...";
echo "================================================================";

sudo dpkg --add-architecture i386;
sudo apt-get install --install-recommends -q -y curl git imagemagick language-pack-en perl unzip wget;

if [[ ! -e /etc/apt/sources.list.d/mono-official-stable.list ]]; then
	echo "";
	echo "================================================================";
	echo "Installing latest Mono from mono-project.org...";
	echo "================================================================";


	# Instructions from (last updated 2019-05-04 for ubuntu 18.04):
	#	https://www.mono-project.com/download/stable/#download-lin
	#
	sudo apt-get install gnupg ca-certificates
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
	echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list;
    sudo chmod 644 /etc/apt/sources.list.d/mono-official-stable.list;
	sudo apt-get update --quiet --yes;
fi

MONO_PACKAGES="mono-runtime mono-devel mono-complete referenceassemblies-pcl ca-certificates-mono mono-xsp4";
echo -e "\nRunning: apt-get install --install-recommends -y $MONO_PACKAGES";
sudo apt-get install --install-recommends -q -y $MONO_PACKAGES;

echo "";
echo "================================================================";
echo "Installing Git Extensions...";
echo "================================================================";

GITEXT_RELEASES_BASE_URL="https://github.com/gitextensions/gitextensions/releases/tag";
#Last release that supports Mono....
GITEXT_TARGET_VERSION="v2.51.05";

#older versions (may possibly be more stable on linux)
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

GITEXT_LAST_MONO_RELEASE_LINK="${GITEXT_RELEASES_BASE_URL}/${GITEXT_TARGET_VERSION}";

# --location follows redirects
PAGE_HTML_SOURCE=$(curl --location --user-agent "${USER_AGENT}" "${GITEXT_LAST_MONO_RELEASE_LINK}");
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
	sudo cp -a -t /usr/share/pixmaps/ "${ICONS_DIR}/"*;
	sudo chown root:root /usr/share/pixmaps/git*.png;
	sudo chmod 744 /usr/share/pixmaps/git*.png;
fi

#cleanup extracted src folders - this was only used for the icons
# hardcode the path "/tmp/git-ext-icons", as ICONS_DIR can also point under Script dir and
# we don't want to remove any resources that are included with the Script / in the Scripts dir
rm -R "${EXTRACTED_SRC_DIR}" 2>/dev/null;
rm -R "${ICONS_DIR}" 2>/dev/null;

#handle extracting the mono installation zip...
echo -e "\nSetting up Git Extensions wrapper scripts...";
GIT_EXT_INSTALL_DIR="/opt/GitExtensions";

# if old install exists, then create backup but get it out of the way
if [[ -d "${GIT_EXT_INSTALL_DIR}" ]]; then
	sudo mv "${GIT_EXT_INSTALL_DIR}" "${GIT_EXT_INSTALL_DIR}".$(date +'%Y%m%d%H%M').bak
fi

sudo mv "${EXTRACTED_MONO_DIR}/GitExtensions/" "${GIT_EXT_INSTALL_DIR}/";
sudo mv "${GITEXT_MONO_ZIP}" "${GIT_EXT_INSTALL_DIR}/../${GITEXT_MONO_ZIP}";
sudo mv "${GITEXT_SRC_ZIP}" "${GIT_EXT_INSTALL_DIR}/../${GITEXT_SRC_ZIP}";
rm -r "${EXTRACTED_MONO_DIR}";

#rename included shell script
GIT_EXT_SH="${GIT_EXT_INSTALL_DIR}/gitext.sh";
sudo mv "${GIT_EXT_SH}" "${GIT_EXT_SH}.orig";

#create a new one that uses the full path to GitExtensions.exe
sudo touch "${GIT_EXT_SH}";
echo '#!/bin/bash' | sudo tee -a "${GIT_EXT_SH}" >/dev/null;
echo -e "/usr/bin/mono \"${GIT_EXT_INSTALL_DIR}/GitExtensions.exe\" \"\$@\" &\n\n" | sudo tee -a "${GIT_EXT_SH}" >/dev/null;
sudo chmod 755 "${GIT_EXT_SH}";

#create a symlink
sudo ln -fs "${GIT_EXT_SH}" "/usr/bin/gitext";

#Get rid of plugins which cause issues in Linux
rm "${GIT_EXT_INSTALL_DIR}/Plugins/Bitbucket.dll" 2>/dev/null
