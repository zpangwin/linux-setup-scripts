#!/bin/bash

BASE_DISTRO='unknown';
if [[ -f /etc/debian_version ]]; then
    BASE_DISTRO='debian';
elif [[ -f /etc/fedora-release ]]; then
    BASE_DISTRO='fedora';
fi
export BASE_DISTRO="${BASE_DISTRO}";

#echo "DISABLE_STDOUT_IN_FUNCTIONS: $DISABLE_STDOUT_IN_FUNCTIONS"

function addPPAIfNotInSources () {
    if [[ 'debian' != "${BASE_DISTRO}" || ! -f /etc/lsb-release ]]; then
        echo "ERROR: function addPPAIfNotInSources() -- and PPAs in general -- only work with Ubuntu-based distros.";
        return -1;
    fi
}
function addCustomSource() {
	echo "W: addCustomSource is deprecated. Please replace with package manager-specific"
	echo "function call. e.g. addAptCustomSource(), addYumCustomSource(), etc"
	# Pass all args as-is (preserving positional params and quoted strings)
	addAptCustomSource "$@"
}
function addAptCustomSource() {
    if [[ 'debian' != "${BASE_DISTRO}" ]]; then
        echo "ERROR: function addCustomSource() has not been updated to work with non-debian distros.";
        return -1;
    fi

	# get sudo prompt out of way up-front so that it
	# doesn't appear in the middle of other output
	sudo ls -acl 2>/dev/null >/dev/null;

	local useLogFile="false";
	local logFile="/dev/null";
	if [[ "" != "${INSTALL_LOG}" ]]; then
		useLogFile="true";
		logFile="${INSTALL_LOG}";
	fi

	local errorMessage="";
	local showUsageInfo="false";
	local hasMissingOrInvalidInfo="false";

	if [[ "-h" == "$1" || "--help" == "$1" ]]; then
		showUsageInfo="true";
	fi

	local outputFileName="$1";
	local repoDetails="$2";
	local appendEntry="false";
	if [[ "true" != "$showUsageInfo" ]]; then
		if [[ "0" != "${#@}" && "1" != "${#@}" ]]; then
			echo "addCustomSource(): validating '$1' '${@:2}'";
			echo "";
		fi

		#if not just displaying help info, then check passed args
		if [[ "" == "${outputFileName}" ]]; then
			hasMissingOrInvalidInfo="true";
			errorMessage="no arguments";

		elif [[ "" == "${repoDetails}" ]]; then
			hasMissingOrInvalidInfo="true";
			errorMessage="missing arguments - must have REPO_NAME and REPO_DETAILS";

		elif [[ "official-package-repositories" == "$outputFileName" || "additional-repositories" == "$outputFileName" ]]; then
			hasMissingOrInvalidInfo="true";
			errorMessage="invalid REPO_NAME '${outputFileName}'; this name is reserved for system usage";

		elif [[ ! $outputFileName =~ ^[A-Za-z0-9][-A-Za-z0-9._]*[A-Za-z0-9]$ ]]; then
			hasMissingOrInvalidInfo="true";
			errorMessage="invalid REPO_NAME '${outputFileName}' - only alphanum/hyphen/period allowed, must start/end with alphanum";
		fi

		if [[ 'true' != "${hasMissingOrInvalidInfo}" ]]; then
			echo "Validating repo details";
			#check if more than 2 args
			arg3="$3";
			arg4="$4";
			arg5="$5";
			arg6="$6";
			if [[ 'deb' == "${repoDetails}" || 'deb-src' == "${repoDetails}" ]]; then
				echo "Found repoDetails as multiple arguments; attempting to combine ...";
				if [[ 'deb-src' == "${repoDetails}" ]]; then
					appendEntry="true";
				fi

				if [[ "" == "${arg3}" || "" == "${arg4}" ]]; then
					hasMissingOrInvalidInfo="true";
					errorMessage="missing/invalid repo details (only 'deb' but not server/path). Try quoting args after file name?";

				elif [[ ! $arg3 =~ ^https?:\/\/[A-Za-z0-9][-A-Za-z0-9.]*.*$ ]]; then
					hasMissingOrInvalidInfo="true";
					errorMessage="missing/invalid repo details (repo server) for '${arg3}'. Try quoting args after file name?";

				elif [[ "" != "${arg6}" ]]; then
					repoDetails="${repoDetails} $arg3 $arg4 $arg6";

				elif [[ "" != "${arg5}" ]]; then
					repoDetails="${repoDetails} $arg3 $arg4 $arg5";

				else
					repoDetails="${repoDetails} $arg3 $arg4";
				fi
			fi

			# Check known formats
			architecturelessRepoDetails=$(echo "$repoDetails"|sed -E 's/(\s+)\[arch=\w+\]\s+/\1/g');
			echo "architecturelessRepoDetails: '${architecturelessRepoDetails}'";
			if [[ $architecturelessRepoDetails =~ ^deb\-src\ https?:\/\/[A-Za-z0-9][-A-Za-z0-9.]*[^\ ]*\ [^\ ]*\ ?[^\ ]*$ ]]; then
				appendEntry="true";
				echo "OK: repo details appear to be valid.";
				repoDetails="$repoDetails";

			elif [[ $architecturelessRepoDetails =~ ^deb\ https?:\/\/[A-Za-z0-9][-A-Za-z0-9.]*[^\ ]*\ [^\ ]*\ ?[^\ ]*$ ]]; then
				echo "OK: repo details appear to be valid.";
				repoDetails="$repoDetails";

			elif [[ $architecturelessRepoDetails =~ ^https?:\/\/[A-Za-z0-9][-A-Za-z0-9.*[^\ ]*\ [^\ ]*\ ?[^\ ]*$ ]]; then
				echo "OK: repo details appear to be valid but does not start with 'deb'; prepending ...";
				repoDetails="deb $repoDetails";

			else
				hasMissingOrInvalidInfo="true";
				errorMessage="invalid/unsupported repo details format for '${repoDetails}'";
			fi
		fi
	fi

	if [[ "true" == "$showUsageInfo" || "true" == "$hasMissingOrInvalidInfo" ]]; then
		if [[ "true" == "$hasMissingOrInvalidInfo" ]]; then
			echo "ERROR: addCustomSource(): ${errorMessage}." | tee -a "${logFile}";
		fi
		echo "" | tee -a "${logFile}";
		echo "usage:" | tee -a "${logFile}";
		echo "   addCustomSource REPO_NAME REPO_DETAILS" | tee -a "${logFile}";
		echo "" | tee -a "${logFile}";
		echo "   Adds the specified source under /etc/apt/sources.list.d/" | tee -a "${logFile}";
		echo "   if it does not already exist. Both the repo name and the" | tee -a "${logFile}";
		echo "   details will be considered when checking for existing sources." | tee -a "${logFile}";
		echo "" | tee -a "${logFile}";
		echo "   REPO_NAME:    user-defined name; only used for the" | tee -a "${logFile}";
		echo "                 naming the apt source list file." | tee -a "${logFile}";
		echo "                 Names must start/end with alphanumeric characters." | tee -a "${logFile}";
		echo "                 Hyphens/periods are allowed for intervening characters." | tee -a "${logFile}";
		echo "" | tee -a "${logFile}";
		echo "   REPO_DETAILS: Info that goes in the apt source list file." | tee -a "${logFile}";
		echo "                 Generally is in the format of:" | tee -a "${logFile}";
		echo "                 deb REPO_BASE_URL REPO_RELATIVE_PATH" | tee -a "${logFile}";
		echo "" | tee -a "${logFile}";
		echo "examples:" | tee -a "${logFile}";
		echo "   addCustomSource sublimetext 'deb https://download.sublimetext.com/ apt/stable/' " | tee -a "${logFile}";
		echo "   addCustomSource sublimetext deb https://download.sublimetext.com/ apt/stable/ " | tee -a "${logFile}";
		echo "" | tee -a "${logFile}";
		return;
	fi

	#check if it already exists...
	echo "Checking if repo source file already exists..." | tee -a "${logFile}";
	if [[ 'false' == "${appendEntry}" && -f "/etc/apt/sources.list.d/${outputFileName}.list" ]]; then
		echo "addCustomSource(): Source ${outputFileName} already defined; skipping..." | tee -a "${logFile}";
		return;
	elif [[ 'true' == "${appendEntry}" && ! -f "/etc/apt/sources.list.d/${outputFileName}.list" ]]; then
		echo "addCustomSource(): Source ${outputFileName} doesn't have any binary sources defined; skipping..." | tee -a "${logFile}";
		return;
    else
        echo "  -> PASSED";
	fi

	#check if details already exist...
	echo "Checking if repo details not already defined in another file ..." | tee -a "${logFile}";
	local existingRepoDetsCount=$(sudo grep -Ri "${repoDetails}" /etc/apt/sources.list.d/*.list 2>/dev/null|wc -l);
	if [[ "0" != "${existingRepoDetsCount}" ]]; then
		echo "addCustomSource(): Repo details already defined for '${repoDetails}'; skipping..." | tee -a "${logFile}";
		echo "Existing matches:" | tee -a "${logFile}";
		echo "" | tee -a "${logFile}";
        sudo grep -RHni "${repoDetails}" /etc/apt/sources.list.d/*.list 2>/dev/null | tee -a "${logFile}";
		return;
    else
        echo "  -> PASSED";
	fi

	# add new source
	echo "Adding source as '${outputFileName}.list' ..." | tee -a "${logFile}";
	if [[ 'true' == "${appendEntry}" ]]; then
		echo "${repoDetails}" | sudo tee -a "/etc/apt/sources.list.d/${outputFileName}.list" >/dev/null;
	else
		echo "${repoDetails}" | sudo tee "/etc/apt/sources.list.d/${outputFileName}.list" >/dev/null;
	fi

	# safety
	sudo chown root:root /etc/apt/sources.list.d/*.list;
	sudo chmod 644 /etc/apt/sources.list.d/*.list;
}
function verifyAndInstallPackagesFromMap() {
    #================================================================
    # This function will verify all of the passed packages are
    # installed. If any are not installed, it will attempt to
    # install them. If all packages are verified as installed, it
    # will return 0 to indicate success. Otherwise, it will return
    # a non-zero value to indicate failure.
    #================================================================
    if [[ 'debian' != "${BASE_DISTRO}" ]]; then
        echo "ERROR: function verifyAndInstallPackagesFromMap() has not been updated to work with non-debian distros.";
        return -1;
    fi

    # get sudo prompt out of way up-front so that it
    # doesn't appear in the middle of other output
    sudo ls -acl 2>/dev/null >/dev/null;

    # ==================================================================
    # This function expects $1 to be an associative array (aka a map)
    # which contains:
    #   Map<Key=localBinaryPath,Value=packageNameOfBinary>
    # where
    # localBinaryPath     = path to a local binary (e.g. /usr/bin/7z)
    # packageNameOfBinary = install package for binary (e.g. p7zip-full)
    # ==================================================================
    # Sample usage:
    #
    # # 1) Define a dependenciesMap
    # declare -A dependenciesMap=(
    #   ['/usr/bin/7z']='p7zip-full'
    #   ['/usr/bin/curl']='curl'
    #   ['/usr/bin/yad']='yad'
    #   ['/usr/bin/convert']='imagemagick'
    # );
    #
    # # 2) pass map to function
    # verifyAndInstallPackagesFromMap "$(declare -p dependenciesMap)";
    #
    # # 3) check function return code (0 is pass; non-zero is fail)
    # if [[ "0" == "$?" ]]; then echo "pass"; else echo "fail"; fi
    # ==================================================================
    if [[ "" == "$1" ]]; then
        return 501;
    fi

    local binPathKey="";
    local packageNameValue="";
    local binExists="";
    local status=0;

    eval "declare -A dependenciesMap="${1#*=}
    for i in "${!dependenciesMap[@]}"; do
        binPathKey="$i";
        reqPkgName="${dependenciesMap[$binPathKey]}";
        #echo "-----------"
        #printf "%s\t%s\n" "$binPathKey ==> ${reqPkgName}"

        #check if binary path exists
        binExists=$(/usr/bin/which "${binPathKey}" 2>/dev/null|wc -l);
        #printf "%s\t%s\t:\t%s\n" "$binPathKey ==> ${reqPkgName}" "$binExists"
        if [[ "1" == "${binExists}" ]]; then
            # if it exists, then we can skip that dependency
            continue;

        elif [[ "0" == "${binExists}" ]]; then
            # attempt to install missing package
            sudo apt-get install -y "${reqPkgName}" 2>&1 >/dev/null;
            if [[ "$?" != "0" ]]; then
                status=503;
                continue;
            fi
            binExists=$(/usr/bin/which "${binPathKey}" 2>/dev/null|wc -l);
            if [[ "1" != "${binExists}" ]]; then
                status=504;
                continue;
            fi
        else
            # any other possibility means multiple matches were
            # returned from /usr/bin/which; which should not be possible
            status=505;
            continue;
        fi
        printf "%s\t%s\n" "$binPathKey ==> ${reqPkgName}";
    done
    return ${status};
}
function verifyAndInstallPackagesFromList() {
    #================================================================
    # This function will verify all of the passed packages are
    # installed. If any are not installed, it will attempt to
    # install them. If all packages are verified as installed, it
    # will return 0 to indicate success. Otherwise, it will return
    # a non-zero value to indicate failure.
    #================================================================
    if [[ 'debian' != "${BASE_DISTRO}" ]]; then
        echo "ERROR: function verifyAndInstallPackagesFromList() has not been updated to work with non-debian distros.";
        return -1;
    fi

    # get sudo prompt out of way up-front so that it
	# doesn't appear in the middle of other output
	sudo ls -acl 2>/dev/null >/dev/null;

	# This function should not be called if there are no
	# required packages; instead assume this is an error
	if [[ "" == "$1" ]]; then
		return 501;
	fi

	# if checks are disabled, then abort without error
	local skipFlagName="--no-verify-depends";
	local option="$2";
	if [[ "${option}" == "${skipFlagName}" ]]; then
		return 0;
	fi

	local quietFlagName="--quiet";
	local requiredPackagesList="$1";
	local status=0;
	for reqPkgName in $(echo "${requiredPackagesList}"); do
		pkgStatus=$(apt search "${reqPkgName}"|grep -P "^i\\w*\\s+\\b${reqPkgName}\\b"|wc -l);
		if [[ "1" == "${pkgStatus}" ]]; then
			# package already installed; skip to next one
			continue;
		elif [[ "0" != "${pkgStatus}" ]]; then
			if [[ "${option}" != "${quietFlagName}" ]]; then
				echo "ERROR: package '${reqPkgName}' cannot be verified due to multiple matches.";
				echo "Script needs to be updated or used with the ${skipFlagName} option.";
			fi
			status=502;
			continue;
		else
			sudo apt-get install -y "${reqPkgName}" 2>&1 >/dev/null;
			if [[ "$?" != "0" ]]; then
				status=503;
				continue;
			fi
			pkgStatus=$(apt search "${reqPkgName}"|grep -P "^i\\w*\\s+\\b${reqPkgName}\\b"|wc -l);
			if [[ "1" != "${pkgStatus}" ]]; then
				status=504;
				continue;
			fi
		fi
	done
	return ${status};
}
function whichPackage() {
    if [[ "" == "$1" || "-h" == "$1" || "--help" == "$1" ]]; then
        echo "Expected usage";
        echo "   whichPackage binaryName";
        echo "or whichPackage pathToBinary";
        echo "";
        echo "Finds what package a binary is from (e.g. /usr/bin/7z => p7zip-full)";
        echo "  binaryName   - Name of a binary on \$PATH such as 7z, curl, firefox, etc";
        echo "  pathToBinary - Path to a binary installed by a package. This can be the path of an actual file (e.g. /usr/bin/7z) or a symlink to an actual file (e.g. /usr/bin/vi); however either the resolved file must be part of a package.";
        echo "";
        return;
    fi
    local path="$1";
    if [[ "~/" == "${path:0:2}" ]]; then
        path="$HOME/${path:2}";
    elif [[ "./" == "${path:0:2}" ]]; then
        path="$PWD/${path:2}";
    fi

    # if path is really just a name, try looking it up
    # using which
    if [[ $path =~ ^[A-Za-z0-9][-A-Za-z0-9._+]*$ ]]; then
        binLocation=$(which $path 2>/dev/null);
        if [[ "" != "${binLocation}" && -e "${binLocation}" ]]; then
            if [[ -L "${binLocation}" ]]; then
                realLoc=$(realpath "${binLocation}");
                path="${realLoc}";
            else
                path="${binLocation}";
            fi
        fi
    fi
    dpkg -S "${path}"|awk -F: '{print $1}';
}
function installDependenciesFromDebFile() {
    if [[ 'debian' != "${BASE_DISTRO}" ]]; then
        echo "ERROR: function installDependenciesFromDebFile() has not been updated to work with non-debian distros.";
        return -1;
    fi

	local debFilePath="$1";
	local excludedPackagesRegex="$2"
	if [[ "" == "${debFilePath}" || ".deb" != "${debFilePath:${#debFilePath}-4}" ]]; then
		if [[ "-h" != "$1" && "--help" != "$1" ]]; then
			echo "ERROR: Missing or invalid .deb file.";
		fi
		echo "Expected usage:";
		echo "installDependenciesFromDebFile /path/to/some.deb [EXCLUDE_REGEX]";
		echo "";
		echo "This function will parse the dependencies required by the deb file and attempt to install them, provided they exist in the central repositories.";
		echo "";
		echo "EXCLUDE_REGEX - an optional Perl-style regex pattern of any packages to be excluded.";
		echo "";
		echo "Examples:";
		echo " # To exclude all occurrences of 'qt56-teamviewer' any of the following would work: ";
		echo " installDependenciesFromDebFile teamviewer_amd64.deb 'qt56-teamviewer'";
		echo " installDependenciesFromDebFile teamviewer_amd64.deb 'qt\\d+-teamviewer'";
		echo " installDependenciesFromDebFile teamviewer_amd64.deb '[\\S]*teamviewer[\\S]*'";
		return -1;
	fi
	if [[ ! -f "${debFilePath}" ]]; then
		echo "ERROR: Passed file '${debFilePath}' does not exist.";
		return 2;
	fi

	local debFileName=$(basename "${debFilePath}");
	local canonFileName="${debFileName%%.*}";
	canonFileName="${canonFileName/[\-_]i386/}";
	canonFileName="${canonFileName/[\-_]amd64/}";

	local rawDependenciesList=$(dpkg -I "${debFilePath}"|grep Depends);
	#echo "rawDependenciesList: ${rawDependenciesList}";

	local cleanedDependenciesList=$(echo "${rawDependenciesList:10}"|sed -E 's/\([^\(\)]+\)|\||,//g' 2>/dev/null);
	#echo "cleanedDependenciesList[0]: ${cleanedDependenciesList}";

	# if the filename is a name only and something distinct (e.g. 8 characters or more)
	# then also filter out the unique name from any package requirements. this is not
	# always needed but can be required in some cases such as with teamviewer's deb file.
	if [[ "" != "${canonFileName}" && "${canonFileName}" != "${excludedPackagesRegex}" ]]; then
		if [[ "$canonFileName" && $canonFileName =~ ^[a-z][-a-z]*[a-z]$ ]]; then
			if (( ${#canonFileName} > 8 )); then
				cleanedDependenciesList=$(echo "${cleanedDependenciesList}"|perl -pe "s/[\\S]*${canonFileName}[\\S]*//g" 2>/dev/null);
			fi
		fi
	fi
	#echo "cleanedDependenciesList[1]: ${cleanedDependenciesList}";

	if [[ "" != "${excludedPackagesRegex}" ]]; then
		cleanedDependenciesList=$(echo "${cleanedDependenciesList}"|perl -pe "s/${excludedPackagesRegex}//g" 2>/dev/null);
	fi
	#echo "cleanedDependenciesList[2]: ${cleanedDependenciesList}";

	if [[ "" != "${cleanedDependenciesList}" ]]; then
		echo "Attempting to install dependencies for ${debFileName} ...";
		sudo apt-get install -y ${cleanedDependenciesList};
	else
		echo "No dependencies found for ${debFileName}";
	fi
}
