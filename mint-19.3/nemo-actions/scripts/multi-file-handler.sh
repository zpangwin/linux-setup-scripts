#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
#echo "SCRIPT_DIR is $SCRIPT_DIR";

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}");
#echo "SCRIPT_NAME is $SCRIPT_NAME";

enableDebugging="0";
if [[ "-d" == "$1" || "--debug" == "$1" ]]; then
	enableDebugging="1";
	shift 1;
fi

if [[ "" == "$1" || "" == "$2" ]]; then
	exit;
fi

ts=$(date +'%Y-%m-%d @ %H:%M:%S:');
sep='============================================================================================';
outfile="/home/$(getent passwd 1000 | cut -d: -f1)/Desktop/nemo-test.txt";

appPath=$(which "$1" || echo "$1");
if [[ ! -f "${appPath}" ]]; then
	if [[ "1" == "${enableDebugging}" ]]; then
		 printf '%s\n%s\n%s: Error - appPath "%s" does not exist\n' "${sep}" "${ts}" "${SCRIPT_NAME}" "${appPath}" >> "$outfile";
	fi
	exit;
fi

#==========================================================================================================================
# Note: If you are passing %F then this becomes an exercise in frustration.
# This is because while %F works just file for single-file selections, it
# is very problematic for multi-file selections:
#	* If passed as "%F", the individual files are not passed as separate quoted strings but rather as a single-string
#		that is SPACE-delimited (as opposed to newline-delimited) so accurate parsing of a list of files that 
#		each contain spaces in the path, while accounting for partial (mis-)matches, becomes a HUGE chore.
#	    This could have been avoided if newlines were used to delimit paths or there was an option to pass the list
#		as an ARRAY rather than as a string.
#
#	* If passed as %F (without quotes), it will work for files whose full paths contain no spaces but will break
#		horribly for paths containing spaces.
#
# Instead, it is better to use "%U" to obtain all the paths as a space-delimited list of file uris,
#	as spaces in the paths will have been URL-encoded and each path is prefixed with 'file://'.
#	This allows easier processing to split into individual paths and then perl can be used to
#	quickly convert the URI's back to file paths (as some applications can't handle URIs directly).
#==========================================================================================================================
rawUriList="$2";
if [[ ! $rawUriList =~ ^file://.*$ ]]; then
	if [[ "1" == "${enableDebugging}" ]]; then
		printf '%s\n%s\n%s: Error - second arg must be passed as URI ('%s')\n' "${sep}" "${ts}" "${SCRIPT_NAME}" "%U" >> "$outfile";
	fi
	exit;
fi

if [[ "1" == "${enableDebugging}" ]]; then
	printf '%s\n%s\n%s:\n' "${sep}" "${ts}" "${SCRIPT_NAME}" >> "$outfile";
	printf '\tSCRIPT_DIR is: "%s"\n' "${SCRIPT_DIR}" >> "$outfile";
	printf '\tSCRIPT_NAME is: "%s"\n' "${SCRIPT_NAME}" >> "$outfile";

	i=1
	for var in "$@"
	do
		printf '\targ $%s is: "%s"\n' "${i}" "${var}" >> "$outfile";
		i=$(( i + 1 ));
	done
fi

# convert rawUriList to array
aryFileList=(  );

for uri in $(echo "${rawUriList}"); do
	# strip "file://" prefix and decode URI to get filepath
	filePath=$(perl -MURI::Escape -e 'print uri_unescape($ARGV[0])' "${uri:7}");
	aryFileList+=("${filePath}");
	
	if [[ "1" == "${enableDebugging}" ]]; then
		printf '\t filePath: "%s"\n' "${filePath}" >> "$outfile";
	fi
done

if [[ "0" != "${#aryFileList[@]}" ]]; then
	"${appPath}" "${aryFileList[@]}" &
fi



