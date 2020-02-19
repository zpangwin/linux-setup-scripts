#!/bin/bash
#get sudo prompt out of the way
sudo ls -acl >/dev/null

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
	sudo apt install gnupg ca-certificates
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
	echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list;
    sudo chmod 644 /etc/apt/sources.list.d/mono-official-stable.list;
	sudo apt-get update --quiet --yes;
fi

MONO_PACKAGES="mono-runtime mono-devel mono-complete referenceassemblies-pcl ca-certificates-mono mono-xsp4";
echo -e "\nRunning: apt install --install-recommends -y $MONO_PACKAGES";
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

#Make sure scripts called by nemo actions are present
GITEXT_SCRIPTS_DIR="/usr/share/nemo/actions/scripts"

sudo mkdir -p "${GITEXT_SCRIPTS_DIR}" 2>/dev/null;

IS_GIT_DIR_SH="/usr/bin/is-git-dir";
IS_NON_GIT_DIR_SH="/usr/bin/is-non-git-dir";
WHICH_GIT_TOP_DIR_SH="/usr/bin/which-git-top-dir";
BROWSE_SH="${GITEXT_SCRIPTS_DIR}/launch-gitext-browse.sh";
CLONE_SH="${GITEXT_SCRIPTS_DIR}/launch-gitext-clone.sh";
COMMIT_SH="${GITEXT_SCRIPTS_DIR}/launch-gitext-commit.sh";
FILEHIST_SH="${GITEXT_SCRIPTS_DIR}/launch-gitext-filehistory.sh";

sudo rm "${IS_GIT_DIR_SH}" 2>/dev/null;
sudo rm "${IS_NON_GIT_DIR_SH}" 2>/dev/null;
sudo rm "${WHICH_GIT_TOP_DIR_SH}" 2>/dev/null;
sudo rm "${BROWSE_SH}" 2>/dev/null;
sudo rm "${COMMIT_SH}" 2>/dev/null;
sudo rm "${CLONE_SH}" 2>/dev/null;
sudo rm "${FILEHIST_SH}" 2>/dev/null;

# Add script for determining if passed path is under a git repo
# See: https://github.com/linuxmint/nemo/pull/2056
sudo touch "${IS_GIT_DIR_SH}";
echo '#!/bin/bash' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'path="$1";' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'if [[ "" == "$1" ]]; then' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo '	exit 500;' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'fi' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'if [[ -f "$path" ]]; then' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo '	path=$(dirname "$path");' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'fi' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'if [[ ! -d "$path" ]]; then' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo '	exit 501;' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'fi' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'ismetadir=$(echo "$path"|grep -P "/\\.git(/|\$)"|wc -l);' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'if [[ "0" != "$ismetadir" ]]; then' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo '	exit 502;' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'fi' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;
echo 'git -C "$path" rev-parse;' | sudo tee -a "${IS_GIT_DIR_SH}" >/dev/null;

# Add script for determining if passed path is NOT under a git repo
sudo touch "${IS_NON_GIT_DIR_SH}";
echo '#!/bin/bash' | sudo tee -a "${IS_NON_GIT_DIR_SH}" >/dev/null;
echo 'path="$1";' | sudo tee -a "${IS_NON_GIT_DIR_SH}" >/dev/null;
echo 'if [[ "" == "$1" ]]; then' | sudo tee -a "${IS_NON_GIT_DIR_SH}" >/dev/null;
echo '	exit 500;' | sudo tee -a "${IS_NON_GIT_DIR_SH}" >/dev/null;
echo 'fi' | sudo tee -a "${IS_NON_GIT_DIR_SH}" >/dev/null;
echo "test=\$(\"${IS_GIT_DIR_SH}\" \"\$path\");" | sudo tee -a "${IS_NON_GIT_DIR_SH}" >/dev/null;
echo 'if [[ "0" == "$?" ]]; then' | sudo tee -a "${IS_NON_GIT_DIR_SH}" >/dev/null;
echo '	exit 501;' | sudo tee -a "${IS_NON_GIT_DIR_SH}" >/dev/null;
echo 'fi' | sudo tee -a "${IS_NON_GIT_DIR_SH}" >/dev/null;
echo 'git --version;' | sudo tee -a "${IS_NON_GIT_DIR_SH}" >/dev/null;

# Add script for determing the top level git dir, given some path under the repo
sudo touch "${WHICH_GIT_TOP_DIR_SH}";
echo '#!/bin/bash' | sudo tee -a "${WHICH_GIT_TOP_DIR_SH}" >/dev/null;
echo 'passedPath="$1";' | sudo tee -a "${WHICH_GIT_TOP_DIR_SH}" >/dev/null;
echo 'if [[ -s "${passedPath}" ]]; then' | sudo tee -a "${WHICH_GIT_TOP_DIR_SH}" >/dev/null;
echo '	if [[ -f "${passedPath}" ]]; then' | sudo tee -a "${WHICH_GIT_TOP_DIR_SH}" >/dev/null;
echo '		passedPath=$(dirname "${passedPath}");' | sudo tee -a "${WHICH_GIT_TOP_DIR_SH}" >/dev/null;
echo '	fi' | sudo tee -a "${WHICH_GIT_TOP_DIR_SH}" >/dev/null;
echo '	if [[ -d "${passedPath}" ]]; then' | sudo tee -a "${WHICH_GIT_TOP_DIR_SH}" >/dev/null;
echo '		git -C "${passedPath}" rev-parse --show-toplevel 2>/dev/null;' | sudo tee -a "${WHICH_GIT_TOP_DIR_SH}" >/dev/null;
echo '	fi' | sudo tee -a "${WHICH_GIT_TOP_DIR_SH}" >/dev/null;
echo 'fi' | sudo tee -a "${WHICH_GIT_TOP_DIR_SH}" >/dev/null;

sudo touch "${BROWSE_SH}";
echo '#!/bin/bash' | sudo tee -a "${BROWSE_SH}" >/dev/null;
echo "gitTopLevelDir=\$(\"${WHICH_GIT_TOP_DIR_SH}\" \"\$1\");" | sudo tee -a "${BROWSE_SH}" >/dev/null;
echo 'if [[ "" != "${gitTopLevelDir}" ]]; then' | sudo tee -a "${BROWSE_SH}" >/dev/null;
echo '	cd "${gitTopLevelDir}";' | sudo tee -a "${BROWSE_SH}" >/dev/null;
echo "    /usr/bin/mono \"${GIT_EXT_INSTALL_DIR}/GitExtensions.exe\" browse &" | sudo tee -a "${BROWSE_SH}" >/dev/null;
echo 'fi' | sudo tee -a "${BROWSE_SH}" >/dev/null;

sudo touch "${COMMIT_SH}";
echo '#!/bin/bash' | sudo tee -a "${COMMIT_SH}" >/dev/null;
echo "gitTopLevelDir=\$(\"${WHICH_GIT_TOP_DIR_SH}\" \"\$1\");" | sudo tee -a "${COMMIT_SH}" >/dev/null;
echo 'if [[ "" != "${gitTopLevelDir}" ]]; then' | sudo tee -a "${COMMIT_SH}" >/dev/null;
echo '	cd "${gitTopLevelDir}";' | sudo tee -a "${COMMIT_SH}" >/dev/null;
echo "    /usr/bin/mono \"${GIT_EXT_INSTALL_DIR}/GitExtensions.exe\" commit &" | sudo tee -a "${COMMIT_SH}" >/dev/null;
echo 'fi' | sudo tee -a "${COMMIT_SH}" >/dev/null;

sudo touch "${CLONE_SH}";
echo '#!/bin/bash' | sudo tee -a "${CLONE_SH}" >/dev/null;
echo "/usr/bin/mono \"${GIT_EXT_INSTALL_DIR}/GitExtensions.exe\" clone \"\$@\" &" | sudo tee -a "${CLONE_SH}" >/dev/null;

sudo touch "${FILEHIST_SH}";
echo '#!/bin/bash' | sudo tee -a "${FILEHIST_SH}" >/dev/null;
echo "gitTopLevelDir=\$(\"${WHICH_GIT_TOP_DIR_SH}\" \"\$1\");" | sudo tee -a "${FILEHIST_SH}" >/dev/null;
echo 'if [[ "" != "${gitTopLevelDir}" ]]; then' | sudo tee -a "${FILEHIST_SH}" >/dev/null;
echo '	cd "${gitTopLevelDir}";' | sudo tee -a "${FILEHIST_SH}" >/dev/null;
echo "    /usr/bin/mono \"${GIT_EXT_INSTALL_DIR}/GitExtensions.exe\" filehistory \"\$1\" &" | sudo tee -a "${FILEHIST_SH}" >/dev/null;
echo 'fi' | sudo tee -a "${FILEHIST_SH}" >/dev/null;

#set script perms
sudo chmod 755 "${IS_GIT_DIR_SH}";
sudo chmod 755 "${IS_NON_GIT_DIR_SH}";
sudo chmod 755 "${WHICH_GIT_TOP_DIR_SH}";
sudo chmod 755 "${BROWSE_SH}";
sudo chmod 755 "${COMMIT_SH}";
sudo chmod 755 "${CLONE_SH}";
sudo chmod 755 "${FILEHIST_SH}";

#Create Nemo actions
BROWSE_ACTION="/usr/share/nemo/actions/gitext-browse.nemo_action";
CLONE_ACTION="/usr/share/nemo/actions/gitext-clone-background.nemo_action";
COMMIT_ACTION="/usr/share/nemo/actions/gitext-commit.nemo_action";
FILEHIST_ACTION="/usr/share/nemo/actions/gitext-filehistory.nemo_action";

sudo rm "${BROWSE_ACTION}" 2>/dev/null;
sudo rm "${COMMIT_ACTION}" 2>/dev/null;
sudo rm "${CLONE_ACTION}" 2>/dev/null;
sudo rm "${FILEHIST_ACTION}" 2>/dev/null;

sudo touch "${BROWSE_ACTION}";
echo '[Nemo Action]' | sudo tee -a "${BROWSE_ACTION}" >/dev/null;
echo 'Name=GitExt Browse' | sudo tee -a "${BROWSE_ACTION}" >/dev/null;
echo 'Comment=GitExt Browse' | sudo tee -a "${BROWSE_ACTION}" >/dev/null;
echo "Exec=\"${BROWSE_SH}\" %F" | sudo tee -a "${BROWSE_ACTION}" >/dev/null;
echo "Dependencies=git;mono;${GIT_EXT_INSTALL_DIR}/gitext.sh;${BROWSE_SH};" | sudo tee -a "${BROWSE_ACTION}" >/dev/null;
echo 'Icon-Name=git-ext-browse' | sudo tee -a "${BROWSE_ACTION}" >/dev/null;
echo 'Selection=Any' | sudo tee -a "${BROWSE_ACTION}" >/dev/null;
echo 'Extensions=any;' | sudo tee -a "${BROWSE_ACTION}" >/dev/null;
echo 'Quote=double' | sudo tee -a "${BROWSE_ACTION}" >/dev/null;
echo "Conditions=exec ${IS_GIT_DIR_SH} %F" | sudo tee -a "${BROWSE_ACTION}" >/dev/null;

sudo touch "${COMMIT_ACTION}";
echo '[Nemo Action]' | sudo tee -a "${COMMIT_ACTION}" >/dev/null;
echo 'Name=GitExt Commit' | sudo tee -a "${COMMIT_ACTION}" >/dev/null;
echo 'Comment=GitExt Commit' | sudo tee -a "${COMMIT_ACTION}" >/dev/null;
echo "Exec=\"${COMMIT_SH}\" %F" | sudo tee -a "${COMMIT_ACTION}" >/dev/null;
echo "Dependencies=git;mono;${GIT_EXT_INSTALL_DIR}/gitext.sh;${COMMIT_SH};" | sudo tee -a "${COMMIT_ACTION}" >/dev/null;
echo 'Icon-Name=git-ext-commit' | sudo tee -a "${COMMIT_ACTION}" >/dev/null;
echo 'Selection=Any' | sudo tee -a "${COMMIT_ACTION}" >/dev/null;
echo 'Extensions=any;' | sudo tee -a "${COMMIT_ACTION}" >/dev/null;
echo 'Quote=double' | sudo tee -a "${COMMIT_ACTION}" >/dev/null;
echo "Conditions=exec ${IS_GIT_DIR_SH} %F" | sudo tee -a "${COMMIT_ACTION}" >/dev/null;

sudo touch "${CLONE_ACTION}";
echo '[Nemo Action]' | sudo tee -a "${CLONE_ACTION}" >/dev/null;
echo 'Name=GitExt Clone' | sudo tee -a "${CLONE_ACTION}" >/dev/null;
echo 'Comment=GitExt Clone' | sudo tee -a "${CLONE_ACTION}" >/dev/null;
echo "Exec=\"${CLONE_SH}\" %F" | sudo tee -a "${CLONE_ACTION}" >/dev/null;
echo "Dependencies=git;mono;${GIT_EXT_INSTALL_DIR}/gitext.sh;${CLONE_SH};" | sudo tee -a "${CLONE_ACTION}" >/dev/null;
echo 'Icon-Name=git-ext-clone' | sudo tee -a "${CLONE_ACTION}" >/dev/null;
echo 'Selection=none' | sudo tee -a "${CLONE_ACTION}" >/dev/null;
echo 'Extensions=none;' | sudo tee -a "${CLONE_ACTION}" >/dev/null;
echo 'Quote=double' | sudo tee -a "${CLONE_ACTION}" >/dev/null;
echo "Conditions=exec ${IS_NON_GIT_DIR_SH} %F" | sudo tee -a "${CLONE_ACTION}" >/dev/null;

sudo touch "${FILEHIST_ACTION}";
echo '[Nemo Action]' | sudo tee -a "${FILEHIST_ACTION}" >/dev/null;
echo 'Name=GitExt File History' | sudo tee -a "${FILEHIST_ACTION}" >/dev/null;
echo 'Comment=GitExt File History' | sudo tee -a "${FILEHIST_ACTION}" >/dev/null;
echo "Exec=\"${FILEHIST_SH}\" %F" | sudo tee -a "${FILEHIST_ACTION}" >/dev/null;
echo "Dependencies=git;mono;${GIT_EXT_INSTALL_DIR}/gitext.sh;${COMMIT_SH};" | sudo tee -a "${FILEHIST_ACTION}" >/dev/null;
echo 'Icon-Name=git-ext-file-history' | sudo tee -a "${FILEHIST_ACTION}" >/dev/null;
echo 'Selection=s' | sudo tee -a "${FILEHIST_ACTION}" >/dev/null;
echo 'Extensions=nodirs;' | sudo tee -a "${FILEHIST_ACTION}" >/dev/null;
echo 'Quote=double' | sudo tee -a "${FILEHIST_ACTION}" >/dev/null;
echo "Conditions=exec ${IS_GIT_DIR_SH} %F" | sudo tee -a "${FILEHIST_ACTION}" >/dev/null;


#set action perms
sudo chmod 644 "${BROWSE_ACTION}";
sudo chmod 644 "${COMMIT_ACTION}";
sudo chmod 644 "${CLONE_ACTION}";
sudo chmod 644 "${FILEHIST_ACTION}";

#Get rid of plugins which cause issues in Linux
rm "${GIT_EXT_INSTALL_DIR}/Plugins/Bitbucket.dll" 2>/dev/null



