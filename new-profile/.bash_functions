WHICH_OPTS='';
if [[ 1 == $(/usr/bin/man which 2>/dev/null | /bin/grep '\-\-skip-alias' 2>/dev/null | /usr/bin/wc -l 2>/dev/null) ]]; then
	export WHICH_OPTS='--skip-alias --skip-functions';
fi

#==========================================================================
# Start Section: General Utility functions
#==========================================================================
function testPassedOptionsRegex() {
	# ex: use the following pattern to search for:
	#	any grouped options that begins with a single dash (e.g. match '-P' in '-P', '-Pi', or '-iP')
	#	any exact non-grouped option that begins with a double dash (e.g. match '--poop' in '--poop' but not in '--pooped' or '--pooper')
	#
	# sample pattern: '-\w*[h]\w*|--help'
	#

	local fnName='testPassedOptionsRegex';

	local pattern="$1";
	shift 1;

	# Note: a *different* dbg variable name is used here as otherwise it would cause functions that are dependent on this function
	# to fail (as they use output to determine true/pass vs false/fail).
	if [[ 1 == $BASH_ARG_FUNCTION_DBG ]]; then
		echo "${fnName}: pattern (initial): '${pattern}'";
	fi

	if [[ '' == "${pattern}" ]]; then
		if [[ 1 == $BASH_ARG_FUNCTION_DBG ]]; then
			echo "E: ${fnName}: no pattern";
		fi
		echo -1;
		return -1;
	fi
	if [[ '^' != "${pattern:0:1}" && '$' != "${pattern:${#pattern}-1:1}" ]]; then
		pattern="^(${pattern})\$";
	fi
	if [[ 1 == $BASH_ARG_FUNCTION_DBG ]]; then
		echo "${fnName}: pattern (final): '${pattern}'";
	fi

	if [[ 0 == ${#@} || '' == "$1" ]]; then
		if [[ 1 == $BASH_ARG_FUNCTION_DBG ]]; then
			echo "E: ${fnName}: no passed args";
		fi
		echo -1;
		return -1;
	fi

	# Can use "$@" or "$@"
	if [[ 1 == $BASH_ARG_FUNCTION_DBG ]]; then
		echo "${fnName}: found ${#@} passed args ...";
		echo "${fnName}: printing passed args ...";
		echo "";
	fi

	hasMatch=0;
	for (( i=1; i<=${#@}; i++ )); do
		if [[ 1 == $BASH_ARG_FUNCTION_DBG ]]; then
			echo -e "\${@:$i:1} \t ${@:$i:1}";
		fi
		if [[ 0 != $(echo "${@:$i:1}"|grep -Pc "${pattern}") ]]; then
			hasMatch=1;
			break;
		fi
	done
	if [[ 1 == ${hasMatch} ]]; then
		echo 0;
		return 0;
	fi
	echo -1;
	return -1;
}
export -f testPassedOptionsRegex;
function makeSymlinks() {
	local argcnt="${#@}";
	if (( ${argcnt} < 2 )); then
		# help maybe?
		/bin/ln "$@";
	else
		# get paths from last 2 args so opts are preserved
		local src="${@:${argcnt}-1:1}";
		local dst="${@:${argcnt}:1}";

		# handle being a windows tard
		if [[ -n "$src" && -n "$dst" ]]; then
			# check if dst exists and the src (e.g. new symlink)
			# OR both exist but src is a symlink and dst is not (e.g. replacing/updating existing symlink)
			if [[ ( ! -e "$src" && -e "$dst" ) || ( -L "$src" && ! -L "$dst" ) ]]; then
				local tmp="$src";
				src="$dst";
				dst="$tmp";
			fi
		fi

		# command with args then src then dst
		/bin/ln "${@:1:${#@}-2}" "$src" "$dst";
	fi
}
export -f makeSymlinks;
function getWhichCount() {
	which ${WHICH_OPTS} "${@}" 2>/dev/null|wc -l;
}
export -f getWhichCount;
function setGnomeTerminalTitle() {
	#
	# ===============================================================================================
	# Variable guide
	# ===============================================================================================
	# These are just common bash escape sequences which can be referenced here:
	#	https://tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html
	#	https://www.tecmint.com/customize-bash-colors-terminal-prompt-linux/
	#	https://www.cyberciti.biz/faq/bash-shell-change-the-color-of-my-shell-prompt-under-linux-or-unix/
	#
	#	\u: Display the current username
	#	\h: Display the hostname
	#	\H: Display FQDN (fully qualified domain name) hostname.
	#	\W: Print the base of current working directory.
	#	\$: Display # (indicates root user) if the effective UID is 0, otherwise display a $.
	#	\@: Display current time in 12-hour am/pm format (when prompt is displayed; does not update)
	#	\!: history number of the current command
	#	\e: start of ANSI escape sequence. See https://en.wikipedia.org/wiki/ANSI_escape_code
	#		 This will generally be either followed by '[' (Control Sequence Introducer - see below)
	#		 or by ']' (Operating System Command)
	#	\033: Same as \e (using octal code instead)
	#	\[: begin a sequence of non-printing characters, which could be used to embed a terminal
	#		 con­trol sequence into the prompt
	#	\]: end a sequence of non-printing characters
	#
	# Operating System Commands (used for things like setting window title)
	# -> use the format '\e]0; WINDOW_TITLE_TEXT \a' where:
	#
	#		\e    : Start the ascii escape sequence
	#		[     : Start of the Control Sequence Introducer (color scheme specification)
	#		\a    : an ASCII bell character (07). This character is used to close the ANSI escape sequence
	#
	# Control Sequence Introducers (used for text control such as colors, font effects, etc)
	# -> use the format '\e[n;n;nm TEXT \e[m' where:
	#
	#		\e    : Start the ANSI escape sequence
	#		[     : Start of the Control Sequence Introducer (color scheme specification)
	#		n;n;n : Text control codes - these are 0 or more numbers separated by semi-colons.
	#				Multiple formatting numbers can be stacked but numbers indicating background
	#				or foreground colors will use the last bg/fg color specified.
	#				If no numbers are specified, this indicates to reset any active colors back to
	#				the defaults.
	#		 m    : closes the ANSI escape sequence
	#		TEXT  : Since text appears immediately after the close of the first ANSI escape sequence,
	#				the effects specified from that sequence will be applied to the text.
	#		\e[m  : Second ANSI escape sequence with no numbers which indicates that any active effects
	#				should be reset to the defaults and not apply to any text that appears afterwards.
	#				Note that \e[0m and \e[00m are identical in function as all 3 forms indicate that
	#				there are not any non-zero options selected.
	#
	#	Examples:
	#		printf 'The little \e[31mred\e[m fox\n';      # the word 'red' is displayed in red text (31)
	#		printf 'The little \e[44;31mred\e[m fox\n';   # same as above but with a blue background (44)
	#		printf 'The little \e[4;44;31mred\e[m fox\n'; # same as above but underlined (4)
	#
	#		oldps1="${PS1}"                              # backup the current PS1 format first
	#		PS1="\e[0;31m\u\e[m@\h:\W \$";               # display username in red
	#
	# ===============================================================================================
	# ANSI Escape Control Sequence Introducers (Color Sequence Guide)
	# ===============================================================================================
	# The PS1 variable uses ANSI escape sequences. For a more complete list of colors, see:
	#	https://unix.stackexchange.com/questions/124407/what-color-codes-can-i-use-in-my-ps1-prompt
	#	https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
	#	-> but note that not all the colors listed on the wiki page will work in a linux terminal
	#
	# Effects:
	#	1 - bold (increased font weight)
	#	2 - faint  (decreased font weight)
	#	3 - italic
	#	4 - underline
	#	5 - slow blink
	#	6 - rapid blink
	#	9 - strikethrough
	#	21 - double underline
	#
	# Foreground colors (30–37, 38, 90–97):
	#	30 - black
	#	31 - red
	#	32 - green
	#	33 - yellow
	#	34 - blue
	#	35 - magenta
	#	36 - cyan
	#	37 - white
	#	90 - gray
	#	91 - bright red
	#	92 - bright green
	#	93 - bright yellow
	#	94 - bright blue
	#	95 - bright magenta
	#	96 - bright cyan
	#	97 - bright white
	#
	#	38 - set custom foreground color; Next arguments are 5;n or 2;r;g;b, see below
	#
	# Background colors (40–47, 100–107):
	#
	#	40 - black
	#	41 - red
	#	42 - green
	#	43 - yellow
	#	44 - blue
	#	45 - magenta
	#	46 - cyan
	#	47 - white
	#	100 - gray
	#	101 - bright red
	#	102 - bright green
	#	103 - bright yellow
	#	104 - bright blue
	#	105 - bright magenta
	#	106 - bright cyan
	#	107 - bright white
	#
	#	48 - set custom foreground color; Next arguments are 5;n or 2;r;g;b, see below
	#	58 - (not in standard) set custom underline color; Next arguments are 5;n or 2;r;g;b, see below
	#
	# Custom 8-bit colors:
	#	8-bit colors can be found by looking in the chart here:
	#		https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
	#
	#	And then entering the appropiate code after either '38;5;' or '48;5;'
	#
	#	Examples:
	#		Peach (208):      printf '\e[38;5;208mpeach\e[m\n'
	#		Pink  (207):      printf '\e[38;5;207mpink\e[m\n'
	#		Gold  (142):      printf '\e[38;5;142mgold\e[m\n'
	#		Sky Blue (51):    printf '\e[38;5;51msky blue\e[m\n'
	#		Purple (93):      printf '\e[38;5;93mpurple\e[m\n'
	#		Pink (207) with a Slow Blink Effect (5):        printf '\e[5;38;5;207mpink\e[m\n'
	#
	# Custom RGB (24-bit) colors:
	#	Using any RGB color chart online that displays separate values for red green and blue such as:
	#		https://www.rapidtables.com/web/color/RGB_Color.html
	#
	#	And then entering the appropiate code after either '38;5;' or '48;5;'
	#
	#	Examples:
	#		Red (255,0,0):                          printf '\e[38;2;255;0;0mtext\e[m\n'
	#		Green  (0,255,0):                       printf '\e[38;2;0;255;0mtext\e[m\n'
	#		Blue  (0,0,255):                        printf '\e[38;2;0;0;255mtext\e[m\n'
	#		Lavendar (230,230,250):                 printf '\e[38;2;230;230;250mtext\e[m\n'
	#		Aqua Marine (127,255,212):              printf '\e[38;2;127;255;212mtext\e[m\n'
	#		Dark Orange (255,165,0):                printf '\e[38;2;255;140;0mtext\e[m\n'
	# ===============================================================================================
	local fg_black=30;
	local fg_red=31;
	local fg_green=32;
	local fg_yellow=33;
	local fg_blue=34;
	local fg_magenta=35;
	local fg_cyan=36;
	local fg_white=37;
	local fg_gray=90;
	local fg_orange='38;2;255;140;0';

	local NEW_TITLE="$1";

	# old debian-based version
	#PS1="\[\e]0;${NEW_TITLE}\a\]\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\$\[\033[00m\] ";

	# distro-agnostic version
	#PS1="\[\e]0;${NEW_TITLE}\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\$\[\033[00m\] ";

	# distro-agnostic version using \e instead of octal version (\033)
	#PS1="\[\e]0;${NEW_TITLE}\a\]\[\e[01;32m\]\u@\h\[\e[00m\]:\[\e[01;36m\]\w\$\[\e[00m\] ";

	# \e distro-agnostic version using implicit 0 values instead of explicit ones
	#PS1="\[\e]0;${NEW_TITLE}\a\]\[\e[1;32m\]\u@\h\[\e[m\]:\[\e[1;36m\]\w\$\[\e[m\] ";

	# implicit \e distro-agnostic version without extra non-printable escapes
	#PS1="\e]0;${NEW_TITLE}\a\e[1;32m\u@\h\e[m:\e[1;36m\w\$\e[m ";

	# easier-to-read, distro-agnostic version with variables
	#PS1="\e]0;${NEW_TITLE}\a\e[1;${fg_green}m\u@\h\e[m:\e[1;${fg_cyan}m\w\$\e[m ";

	# easier-to-read, distro-agnostic version with variables and separate colors
	#PS1="\e]0;${NEW_TITLE}\a\e[1;${fg_cyan}m\u\e[m\e[${fg_green}m@\h\e[m:\e[1;${fg_orange}m\w\e[m\e[1;${fg_red}m\$\e[m ";

	# actual
	PS1="\e]0;${NEW_TITLE}\a\e[1;${fg_cyan}m\u\e[m\e[${fg_green}m@\h\e[m:\e[1;${fg_orange}m\w\e[m\e[1;${fg_red}m\$\e[m ";
}
function body() {
	# *************************************************************************************************************************
	# Prints the header (the first line of input) and then passes the body
	# (the rest of the input) back for processing on the terminal for use
	# in a piped command etc.
	#
	# Based on:
	#	https://unix.stackexchange.com/questions/11856/sort-but-keep-header-line-at-the-top
	#
	# Modifications:
	#	Updated to support help text and allowing first param to specify
	#	a user-defined number of lines as header instead of the default of 1.
	#	This behavior is useful when wanting to display a header line and
	#	a separator line before sortable/grepable rows
	# *************************************************************************************************************************
	if [[ '-h' == "$1" || '--help' == "$1" ]]; then
		echo "expected usage:";
		echo " (some command with output) | body [OPTIONS] PIPED_COMMAND";
		echo "";
		echo "Prints the initial line(s) out output as a header and then";
		echo "passes any remaining lines of output back to the terminal";
		echo "for processing by a command expecting piped output.";
		echo "";
		echo "OPTIONS";
		echo "  -n, --lines=[-]NUM   Print the first NUM lines as header text.";
		echo "                       If omitted, defaults to 1 so that only the";
		echo "                       the first line is printed as a header.";
		echo "";
		echo "Examples:";
		echo "  ps -o pid,comm | body sort -k2";
		echo "  ps -o pid,comm | body grep less";
		echo "";
		echo "  # defining long command with custom header and separator"
		echo "  alias x=\"printf 'HEADER\n=======\nless\nmore\nbash\n'\""
		echo "";
		echo "  # using body() to keep header and sep while using sort/grep on other lines:"
		echo "  x | body -n 2 grep less";
		echo "  x | body -n=2 grep bash";
		echo "  x | body -n2 sort";
		echo "  x | body -2 sort -n";
		return 0;
	fi
	local headerSize=1;
	local newHeaderSize=1;

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "body(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo "";
	fi

	# mutually-exclusive options
	# e.g. "body -2"
	if [[ $1 =~ ^\-[1-9][0-9]*$ ]]; then
		newHeaderSize="${1:1}";
		shift 1;

	# e.g. "body -n 2" or "body --line 2"
	elif [[ $2 =~ ^[1-9][0-9]*$ && ( '-n' == "$1" || '--line' == "$1" ) ]]; then
		newHeaderSize="${2:1}";
		shift 2;

	# e.g. "body -n=2" or "body --line=2"
	elif [[ $1 =~ ^\-n=[1-9][0-9]*$ || $1 =~ ^\-\-line=[1-9][0-9]*$ ]]; then
		newHeaderSize="$(echo "$1"|cut -d= -f2)";
		shift 1;

	# e.g. "body -n2" or "body --line2"
	elif [[ $1 =~ ^\-n=[1-9][0-9]*$ || $1 =~ ^\-\-line=[1-9][0-9]*$ ]]; then
		newHeaderSize="$(echo "$1"|cut -d= -f2)";
		shift 1;
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "newHeaderSize: '$newHeaderSize'"
		echo "size(newHeaderSize): ${#newHeaderSize}"
		echo "headerSize: $headerSize"
		echo "";
		echo "\$@: $@"
		echo "";
	fi

	if [[ $newHeaderSize =~ ^[1-9][0-9]*$ ]]; then
		headerSize=$newHeaderSize;
	fi

	OLDIFS="$IFS";
	for ((i = ${headerSize} ; i > 0; i--)); do
		IFS= read -r header
		printf '%s\n' "$header"
	done
	IFS="$OLDIFS";

	# put remaining lines back to terminal so they can be processed
	"$@"
}
function eatStdOutput() {
	# eats standard output; does not affect error output
	:
}
export -f eatStdOutput;
function eatStdOutputIfNotDebug() {
	# eats standard output except when debugging; does not affect error output
	# https://stackoverflow.com/questions/11454343/pipe-output-to-bash-function
	# another alternative (but I like the above better)
	#	https://unix.stackexchange.com/a/598943/379297
	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		while read -r data; do
			printf "%s\n" "$data"
		done
	fi
}
export -f eatStdOutputIfNotDebug;
function reformatTimestamp() {
	local fnName='reformatTimestamp';

	local suppressAllOutput=0;
	if [[ '-q' == "$1" || '--quiet' == "$1" ]]; then
		suppressAllOutput=1;
		shift;
	fi

	if [[ '' == "$1" || '-h' == "$1" || '--help' == "$1" || '' == "$2" || '' == "$3" ]]; then
		local rc=0;
		if [[ '-h' != "$1" && '--help' != "$1" ]]; then
			if [[ 1 == ${suppressAllOutput} ]]; then
				# missing one or more required args
				return -1;
			else
				echo "E: ${fnName}: Missing one or more required arguments.";
				echo "";
				rc=-1;
			fi
		fi
		echo "expected usage:";
		echo "  ${fnName} [OPTIONS] TIMESTAMP_STRING INPUT_FORMAT OUTPUT_FORMAT";
		echo "  ${fnName} TIMESTAMP_STRING INPUT_FORMAT OUTPUT_FORMAT [OPTIONS]";
		echo "";
		echo "This function takes a timestamp string created using the GNU date command";
		echo "and its format pattern reformats it according to a new format pattern.";
		echo "";
		echo "Options";
		echo "";
		echo " -h, --help   display help text";
		echo " -q, --quiet  suppress all output, even error messages.";
		echo "              return codes will still be set normally.";
		echo "";
		echo "Example:";
		echo "  ${fnName} '2016-05-06 16:40' '%Y-%m-%d %H:%M' '%d.%m.%y @ %I:%M%P'";
		echo " -> 06.05.2016 04:40pm";
		echo "";
		echo "If you need to use custom input strings that are not supported by GNU date";
		echo "then install the dateutils package and this function will automatically";
		echo "make use of it.";
		echo "";
		return ${rc};
	fi

	if [[ '-q' == "$4" || '--quiet' == "$4" ]]; then
		suppressAllOutput=1;
	fi

	local timestampStr="$1";
	local inputFormat="$2";
	local outputFormat="$3";

	local isDateUtilsInstalled=0;
	if [[ 1 == $(which $WHICH_OPTS dateconv 2>/dev/null|wc -l) ]]; then
		dateconv --input-format="${inputFormat}" --format="${outputFormat}" "${timestampStr}";
		return $?;

	else
		# validate input format to determine if we need additional dependencies (dateutils package)
		# or if the input format is an input supported by the GNU date command

		# per man date:
		# DATE STRING
		#       The --date=STRING is a mostly free format human readable date string such as "Sun, 29 Feb
		#       2004 16:21:42 -0800" or "2004-02-29 16:21:42" or even "next Thursday".  A date string may
		#       contain  items  indicating  calendar  date, time of day, time zone, day of week, relative
		#       time, relative date, and numbers.  An empty string indicates the beginning  of  the  day.
		#       The  date  string  format is more complex than is easily documented here but is fully de‐
		#       scribed in the info documentation.
		#

		local isSupportedByGnuDate=0

		# 1. Allow numeric epoch seconds
		if [[ ${timestampStr} =~ ^[0-9][0-9]*$ && ( '@' == "${inputFormat}" || '%s' == "${inputFormat}" ) ]]; then
			date -d @${timestampStr} +"${outputFormat}";
			return $?;

		# 2. Allow simple, common patterns
		elif [[ '%F' == "${inputFormat}" || '%c' == "${inputFormat}" || '%Y-%m-%d' == "${inputFormat}" || \
				'%Y-%m-%d %H:%M:%S' == "${inputFormat}" || '%Y-%m-%d %H:%M' == "${inputFormat}" || \
				'%Y-%m-%d %I:%M:%S %P' == "${inputFormat}" || '%Y-%m-%d %I:%M %P' == "${inputFormat}" || \
				'%Y-%m-%d %I:%M:%S %p' == "${inputFormat}" || '%Y-%m-%d %I:%M %p' == "${inputFormat}" \
		]]; then
			date -d "${timestampStr}" +"${outputFormat}";
			return $?;

		# 3. Allow documented sample #1 WITH and WITHOUT timezone: "Sun, 29 Feb 2004 16:21:42 -0800"
		#	-> includes many variations many confirmed in terminal
		elif [[ \
			${inputFormat} =~ ^(%[Aa],?\ )?%d[\-\ ]%[Bbh][\-\ ](%Y|%C%y|%y)(\ %T|\ %R|\ %H(:%M(:%S)?)?)?$ || \
			${inputFormat} =~ ^(%[Aa],?\ )?%d[\-\ ]%[Bbh][\-\ ](%Y|%C%y|%y)(\ %r|\ %I(:%M(:%S)?)?\ ?%[Pp])?$ || \
			${inputFormat} =~ ^(%[Aa],?\ )?%d[\-\ ]%[Bbh][\-\ ](%Y|%C%y|%y)(\ %T|\ %R|\ %H(:%M(:%S)?)?)?\ (%Z|%:*z)$ || \
			${inputFormat} =~ ^(%[Aa],?\ )?%d[\-\ ]%[Bbh][\-\ ](%Y|%C%y|%y)(\ %r|\ %I(:%M(:%S)?)?\ ?%[Pp])?\ (%Z|%:*z)$ \
		]]; then
			date -d "${timestampStr}" +"${outputFormat}";
			return $?;

		# 4. Allow documented sample #2 WITH and WITHOUT timezone: "2004-02-29 16:21:42"
		#	-> includes many variations many confirmed in terminal
		elif [[ \
			${inputFormat} =~ ^(%[Aa],?\ )?(%Y|%C%y)-%[Bbhm]-%d(\ %T|\ %R|\ %H(:%M(:%S)?)?)?$ || \
			${inputFormat} =~ ^(%[Aa],?\ )?(%Y|%C%y)-%[Bbhm]-%d(\ %r|\ %I(:%M(:%S)?)?\ ?%[Pp])?$ || \
			${inputFormat} =~ ^(%[Aa],?\ )?(%Y|%C%y)-%[Bbhm]-%d(\ %T|\ %R|\ %H(:%M(:%S)?)?)?\ (%Z|%:*z)$ || \
			${inputFormat} =~ ^(%[Aa],?\ )?(%Y|%C%y)-%[Bbhm]-%d(\ %r|\ %I(:%M(:%S)?)?\ ?%[Pp])?\ (%Z|%:*z)$ \
		]]; then
			date -d "${timestampStr}" +"${outputFormat}";
			return $?;

		else
			if [[ 1 != ${suppressAllOutput} ]]; then
				echo "E: Input format '${inputFormat}' is not supported by GNU date as an input format.";
				echo "Use another input format. Or install the package dateutils and try again.";
				echo "";
			fi
			return -2;
		fi

	fi
}
export -f reformatTimestamp;
function getTimeDifference() {
	local fnName='getTimeDifference';

	local suppressAllOutput=0;
	if [[ '-q' == "$1" || '--quiet' == "$1" ]]; then
		suppressAllOutput=1;
		shift;
	fi

	if [[ '' == "$1" || '-h' == "$1" || '--help' == "$1" || '' == "$2" || '' == "$3" || '' == "$4" ]]; then
		local rc=0;
		if [[ '-h' != "$1" && '--help' != "$1" ]]; then
			if [[ 1 == ${suppressAllOutput} ]]; then
				# missing one or more required args
				return -1;
			else
				echo "E: ${fnName}: Missing one or more required arguments.";
				echo "";
				rc=-1;
			fi
		fi
		echo "expected usage:";
		echo "  ${fnName} [OPTIONS] TIMESTAMP_1 TIMESTAMP_2 INPUT_FORMAT OUTPUT_FORMAT";
		echo "  ${fnName} TIMESTAMP_1 TIMESTAMP_2 INPUT_FORMAT OUTPUT_FORMAT [OPTIONS]";
		echo "";
		echo "This function takes two similarly formatted timestamp strings";
		echo "created using the GNU date command, their format pattern, and the pattern";
		echo "to display the difference in.";
		echo "";
		echo "Options";
		echo "";
		echo " -h, --help   display help text";
		echo " -q, --quiet  suppress all output, even error messages.";
		echo "              return codes will still be set normally.";
		echo "";
		echo "Example:";
		echo "  TS1='2019-07-04 23:29:40'";
		echo "  TS2='2019-07-05 01:15:52'";
		echo "";
		echo "  ${fnName} \"\$TS1\" \"\$TS2\" '%Y-%m-%d %H:%M:%S' 'time elapsed: %_H hr %_M min %_S sec'";
		echo " -> time elapsed:  1 hr 46 min 12 sec";
		echo "";
		echo "  ${fnName} \"\$TS1\" \"\$TS2\" '%Y-%m-%d %H:%M:%S' 'time elapsed: %_H h %_M m %_S s'";
		echo " -> time elapsed:  1 h 46 m 12 s";
		echo "";
		echo "  ${fnName} \"\$TS1\" \"\$TS2\" '%Y-%m-%d %H:%M:%S' \"time elapsed: %H'%M\\\"%S\"";
		echo " -> time elapsed: 01'46\\\"12";
		echo "";
		echo "  ${fnName} \"\$TS1\" \"\$TS2\" '%Y-%m-%d %H:%M:%S' 'time elapsed: %H:%M%S'";
		echo " -> time elapsed: 01:46:12";
		echo "";
		echo "If you need to use custom input strings that are not supported by GNU date";
		echo "then install the dateutils package and this function will automatically";
		echo "make use of it.";
		echo "";
		return ${rc};
	fi

	local tsOneStr="$1";
	local tsTwoStr="$2";
	local inputFormat="$3";
	local outputFormat="$4";

	if [[ '-q' == "$5" || '--quiet' == "$5" ]]; then
		suppressAllOutput=1;
	fi

	# try to validate that both timestamps are in the same format ..
	# this can be difficult to do when named timestamp zones (%Z) or space padded options (%h)
	# are used, so we'll do a lazy "best-case" validation and chicken out on more complex formats

	# timestamp strings should be the same if they meet the following:
	# 	1. no %Z option where you have variable things like 'America/New_York'
	# 	2. no %n or %t (newline or tab) - not sure if bash regex can handle them
	#	3. we remove all the all alphanumeric characters (from month/day names and all numbers)
	# 	4. if space padded values such as: %_d, %e, %_H, %_I, %k, %l, then compare without spaces
	#
	if [[ ! inputFormat =~ ^.*%_?[Znt].*$ ]]; then
		local strippedTsOne="${tsOneStr//[A-Za-z0-9]/}";
		local strippedTsTwo="${tsTwoStr//[A-Za-z0-9]/}";
		local sameStrippedLen=0

		if [[ ! inputFormat =~ ^.*%(_[A-Za-z]|[elk]).*$ ]]; then
			# shouldn't be any space padded stuff in the format
			if [[ "${#strippedTsOne}" == "${#strippedTsTwo}" && "${strippedTsOne}" == "${strippedTsTwo}" ]]; then
				sameStrippedLen=1;
			fi
		else
			# format contains space padded stuff
			local spaceStrippedTsOne="${strippedTsOne//[\ ]/}";
			local spaceStrippedTsTwo="${strippedTsTwo//[\ ]/}";
			if [[ "${#spaceStrippedTsOne}" == "${#spaceStrippedTsTwo}" && "${spaceStrippedTsOne}" == "${spaceStrippedTsTwo}" ]]; then
				sameStrippedLen=1;
			fi
		fi

		if [[ 1 != ${sameStrippedLen} ]]; then
			if [[ 1 != ${suppressAllOutput} ]]; then
				echo "E: ${fnName}: passed timestamps are not using the same format.";
			fi
			return -1;
		fi
	fi

	local tsOneEpochSeconds=$(reformatTimestamp -q "${tsOneStr}" "${inputFormat}" "%s");
	if [[ '0' != "$?" ]]; then
		if [[ 1 != ${suppressAllOutput} ]]; then
			echo "E: ${fnName}: failed to get epoch seconds for first timestamp.";
		fi
		return -2;

	elif [[ '' == "${tsOneEpochSeconds}" || ! ${tsOneEpochSeconds} =~ ^[1-9][0-9]*$ ]]; then
		if [[ 1 != ${suppressAllOutput} ]]; then
			echo "E: ${fnName}: invalid epoch seconds for first timestamp: '${tsOneEpochSeconds}'";
		fi
		return -3;
	fi

	local tsTwoEpochSeconds=$(reformatTimestamp -q "${tsTwoStr}" "${inputFormat}" "%s");
	if [[ '0' != "$?" ]]; then
		if [[ 1 != ${suppressAllOutput} ]]; then
			echo "E: ${fnName}: failed to get epoch seconds for second timestamp.";
		fi
		return -4;

	elif [[ '' == "${tsTwoEpochSeconds}" || ! ${tsTwoEpochSeconds} =~ ^[1-9][0-9]*$ ]]; then
		if [[ 1 != ${suppressAllOutput} ]]; then
			echo "E: ${fnName}: invalid epoch seconds for second timestamp: '${tsTwoEpochSeconds}'";
		fi
		return -5;
	fi
	local tsDiff=$((tsTwoEpochSeconds-tsOneEpochSeconds));
	TZ=UTC date -d @${tsDiff} +"${outputFormat}";
}
export -f getTimeDifference;
function printUserListHeaders() {
	# This is separate from the listUsers() function so that we can print
	# the headers as the first call in an alias and leave the actual user
	# list to be printed as a second command. Creating aliases in this
	# way allows the user list to be piped to other commands like grep/sort
	# etc without the header or separator lines being altered
	local nameFirst=0;
	for passedarg in "$@"; do
		if [[ $passedarg =~ ^\-\-*name\-?first$ ]]; then
			nameFirst=1;
		fi
	done

	# define column widths
	local aryColumnWidths=(5 25 30 35);
	if [[ '1' == "${nameFirst}" ]]; then
		aryColumnWidths=(25 5 30 35);
	fi

	# create printf pattern dynamically based on array
	local printfPattern="%-${aryColumnWidths[0]}s  %-${aryColumnWidths[1]}s %-${aryColumnWidths[2]}s %-${aryColumnWidths[3]}s\\n";

	# create separators matching dynamic column widths based on array
	local col0Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[0]} - 0))});
	local col1Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[1]} - 1))});
	local col2Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[2]} - 1))});
	local col3Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[3]} - 1))});

	# print dynamically sized header
	if [[ '1' == "${nameFirst}" ]]; then
		printf "${printfPattern}" "user name" "uid " "home folder" "shell";
	else
		printf "${printfPattern}" "uid " "user name" "home folder" "shell";
	fi
	printf "${printfPattern}" "${col0Sep}" "${col1Sep}" "${col2Sep}" "${col3Sep}";
}
function listUsers() {
	local printHeader=1;
	local showAll=0;
	local sortArgs='-n'
	local nameFirst=0;
	for passedarg in "$@"; do
		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "passedarg is $passedarg"
		fi
		if [[ $passedarg =~ ^\-\-*header$ ]]; then
			printHeader=1;

		elif [[ $passedarg =~ ^\-\-*no\-?header$ ]]; then
			printHeader=0;

		elif [[ $passedarg =~ ^\-\-*all$ ]]; then
			showAll=1;

		elif [[ $passedarg =~ ^\-\-*name\-?first$ ]]; then
			nameFirst=1;
			if [[ '-n' == "$sortArgs" ]]; then
				sortArgs='';
			fi

		elif [[ $passedarg =~ ^\-k[=]?[1-4]$ || $passedarg =~ ^\-\-key[=]?[1-4]$ ]]; then
			sortArgs="$passedarg"
		fi
	done

	# define column widths
	local aryColumnWidths=(5 25 30 35);
	if [[ '1' == "${nameFirst}" ]]; then
		aryColumnWidths=(25 5 30 35);
	fi

	# create printf and awk patterns dynamically based on array
	local printfPattern="%-${aryColumnWidths[0]}s  %-${aryColumnWidths[1]}s %-${aryColumnWidths[2]}s %-${aryColumnWidths[3]}s\\n";
	#local awkPattern="%-${aryColumnWidths[0]}s  %-${aryColumnWidths[1]}s %-${aryColumnWidths[2]}s %-${aryColumnWidths[3]}s\\n";
	local awkPattern="${printfPattern}";

	# create separators matching dynamic column widths based on array
	local col0Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[0]} - 0))});
	local col1Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[1]} - 1))});
	local col2Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[2]} - 1))});
	local col3Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[3]} - 1))});

	# if printHeade=0, we want to omit printing of header
	# this is useful to allow aliases to call printUserListHeaders()
	# and this function as separate calls so that this functions output
	# can be piped to other commands without disturbing the header
	if [[ '1' == "${printHeader}" ]]; then
		# print dynamically sized header
		if [[ '1' == "${nameFirst}" ]]; then
			printf "${printfPattern}" "user name" "uid " "home folder" "shell";
		else
			printf "${printfPattern}" "uid " "user name" "home folder" "shell";
		fi
		printf "${printfPattern}" "${col0Sep}" "${col1Sep}" "${col2Sep}" "${col3Sep}";
	fi

	# uid, uname, home dir, shell
	fieldDisplayOrder='$3, $1, $6, $7';
	if [[ '1' == "${nameFirst}" ]]; then
		# uname, uid, home dir, shell
		fieldDisplayOrder='$1, $3, $6, $7';
	fi

	if [[ '0' == "${showAll}" ]]; then
		# for aliases lsusers,listusers
		getent passwd|grep -v nobody|grep -P ":[1-9]\\d{3,}:"| \
		awk -F: "{printf \"${awkPattern}\", ${fieldDisplayOrder}}"| \
		sort ${sortArgs}
	else
		# for aliases lsallusers,listallusers
		getent passwd| \
		awk -F: "{printf \"${awkPattern}\", ${fieldDisplayOrder}}"| \
		sort ${sortArgs}
	fi
}
function printGroupListHeaders() {
	# This is separate from the listGroups() function so that we can print
	# the headers as the first call in an alias and leave the actual group
	# list to be printed as a second command. Creating aliases in this
	# way allows the group list to be piped to other commands like grep/sort
	# etc without the header or separator lines being altered
	local nameFirst=0;
	for passedarg in "$@"; do
		if [[ $passedarg =~ ^\-\-*name\-?first$ ]]; then
			nameFirst=1;
		fi
	done

	# define column widths
	local aryColumnWidths=(5 25 50);
	if [[ '1' == "${nameFirst}" ]]; then
		aryColumnWidths=(25 5 50);
	fi

	# create printf pattern dynamically based on array
	local printfPattern="%-${aryColumnWidths[0]}s  %-${aryColumnWidths[1]}s %-${aryColumnWidths[2]}s\\n";

	# create separators matching dynamic column widths based on array
	local col0Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[0]} - 0))});
	local col1Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[1]} - 1))});
	local col2Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[2]} - 1))});

	# print dynamically sized header
	if [[ '1' == "${nameFirst}" ]]; then
		printf "${printfPattern}" "group name" "gid" "members";
	else
		printf "${printfPattern}" "gid" "group name" "members";
	fi
	printf "${printfPattern}" "${col0Sep}" "${col1Sep}" "${col2Sep}";
}
function listGroups() {
	local printHeader=1;
	local showAll=0;
	local sortArgs='-n'
	local nameFirst=0;
	for passedarg in "$@"; do
		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "passedarg is $passedarg"
		fi
		if [[ $passedarg =~ ^\-\-*header$ ]]; then
			printHeader=1;

		elif [[ $passedarg =~ ^\-\-*no\-?header$ ]]; then
			printHeader=0;

		elif [[ $passedarg =~ ^\-\-*all$ ]]; then
			showAll=1;

		elif [[ $passedarg =~ ^\-\-*name\-?first$ ]]; then
			nameFirst=1;
			if [[ '-n' == "$sortArgs" ]]; then
				sortArgs='';
			fi

		elif [[ $passedarg =~ ^\-k[=]?[1-4]$ || $passedarg =~ ^\-\-key[=]?[1-4]$ ]]; then
			sortArgs="$passedarg"
		fi
	done

	# define column widths
	local aryColumnWidths=(5 25 50);
	if [[ '1' == "${nameFirst}" ]]; then
		aryColumnWidths=(25 5 50);
	fi

	# create printf and awk patterns dynamically based on array
	local printfPattern="%-${aryColumnWidths[0]}s  %-${aryColumnWidths[1]}s %-${aryColumnWidths[2]}s\\n";

	#local awkPattern="%-${aryColumnWidths[0]}s  %-${aryColumnWidths[1]}s %-${aryColumnWidths[2]}s\\n";
	local awkPattern="${printfPattern}";

	# create separators matching dynamic column widths based on array
	local col0Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[0]} - 0))});
	local col1Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[1]} - 1))});
	local col2Sep=$(eval printf "=%.0s" {1..$(( ${aryColumnWidths[2]} - 1))});

	# if printHeade=0, we want to omit printing of header
	# this is useful to allow aliases to call printGroupListHeaders()
	# and this function as separate calls so that this functions output
	# can be piped to other commands without disturbing the header
	if [[ '1' == "${printHeader}" ]]; then
		# print dynamically sized header
		if [[ '1' == "${nameFirst}" ]]; then
			printf "${printfPattern}" "group name" "gid" "members";
		else
			printf "${printfPattern}" "gid" "group name" "members";
		fi
		printf "${printfPattern}" "${col0Sep}" "${col1Sep}" "${col2Sep}";
	fi

	# uid, uname, home dir, shell
	fieldDisplayOrder='$3, $1';
	if [[ '1' == "${nameFirst}" ]]; then
		# uname, uid, home dir, shell
		fieldDisplayOrder='$1, $3';
	fi

	if [[ '0' == "${showAll}" ]]; then
		# for aliases lsgroups,listgroups
		getent group|grep -v nobody|grep -P ":[1-9]\\d{3,}:"| \
		awk -F: "{out=\$4;if(\$4==\"\"){out=\"<no members>\";};printf \"${awkPattern}\", ${fieldDisplayOrder}, out;}"| \
		sort ${sortArgs}
	else
		# for aliases lsallgroups,listallgroups
		getent group| \
		awk -F: "{out=\$4;if(\$4==\"\"){out=\"<no members>\";};printf \"${awkPattern}\", ${fieldDisplayOrder}, out;}"| \
		sort ${sortArgs}
	fi
}
function filePathToFileUri() {
	local filePath="$1";
	if [[ "" == "${filePath}" ]]; then
		return 500;
	fi
	local fileUri=$(echo "${filePath}" | perl -MURI::file -e 'print URI::file->new(<STDIN>)."\n"');
	printf '%s\n' "${fileUri}";
}
function fileUriToFilePath() {
	local fileUri="$1";
	if [[ "" == "${fileUri}" || 'file://' != "${fileUri:0:7}" ]]; then
		return 500;
	fi
	local filePath=$(perl -MURI::Escape -e 'print uri_unescape($ARGV[0])' "${fileUri:7}");
	printf '%s\n' "${filePath}";
}
function getUrlDecodedString() {
	# Based on:
	#	https://stackoverflow.com/questions/6250698/how-to-decode-url-encoded-string-in-shell

	# replace each + with a space
	local i="${*//+/ }";

	# then replace each % with \x so bash knows to interpret the escape sequences properly
	echo -e "${i//%/\\x}";
}
function getUrlEncodedString() {
	# encodes a string replacing any unsafe characters with their url-encoded counterparts
	local string="${1}"
	local strlen=${#string}
	local encoded=""

	for (( pos=0 ; pos<strlen ; pos++ )); do
		c=${string:$pos:1}
		case "$c" in
			[-_.~a-zA-Z0-9] ) o="${c}" ;;
			* )               printf -v o '%%%02x' "'$c"
		esac
		encoded+="${o}"
	done

	# You can either set a return variable (FASTER)
	# or echo the result (EASIER)... or both...
	echo "${encoded}";
	REPLY="${encoded}";
}
function getFullyUrlEncodedString() {
	# function that encodes a string replacing ALL characters with their url-encoded counterparts
	local string="${1}"
	local strlen=${#string}
	local encoded=""

	for (( pos=0 ; pos<strlen ; pos++ )); do
		c=${string:$pos:1}
		printf -v o '%%%02x' "'$c"
		encoded+="${o}"
	done

	# You can either set a return variable (FASTER)
	# or echo the result (EASIER)... or both...
	echo "${encoded}";
	REPLY="${encoded}";
}
function getAllChecksums() {
	local checksumType="$1";
	local showHelp="false";
	local checksumArgs='';
	local aryFileList=(  );

	if (( ${#@} < 2 )); then
		showHelp="true";
	else
		if [[ "md5" != "$1" && "sha1" != "$1" && "sha256" != "$1" && "sha512" != "$1" ]]; then
			checksumType='';
			showHelp="true";
		else
			# Precheck that are args correspond to valid paths
			for (( i=2; i<=${#@}; i++ )); do
				filePath="${@:$i:1}";
				#echo "Path[${i}]: '${filePath}'";

				# mutually-exclusive options
				if [[ "-h" == "${filePath}" || "--help" == "${filePath}" ]]; then
					showHelp="true";
					break;

				elif [[ "-b" == "${filePath}" || "--binary" == "${filePath}" ]]; then
					checksumArgs='--binary';
					continue;

				elif [[ "-t" == "${filePath}" || "--text" == "${filePath}" ]]; then
					checksumArgs='--text';
					continue;

				elif [[ ! -e "${filePath}" ]]; then
					echo "E: Path[${i}]: '${filePath}' does not exist.";
					return 404;

				elif [[ -f "${filePath}" ]]; then
					# non-argument, valid single-file path
					aryFileList+=($(realpath "${filePath}"));

				elif [[ -d "${filePath}" ]]; then
					# https://stackoverflow.com/questions/23356779/how-can-i-store-the-find-command-results-as-an-array-in-bash/54561526#54561526
					readarray -d '' aryFileList < <(find $(realpath "${filePath}") -type f -print0)
				fi
			done
		fi
	fi

	if [[ "true" == "${showHelp}" ]]; then
		echo 'Expected usage:';
		if [[ "md5" != "$1" && "sha1" != "$1" && "sha256" != "$1" && "sha512" != "$1" ]]; then
			echo '   getAllChecksums CHECKSUM_TYPE PATH1 [PATH2] [PATH3] [...]';
			echo '';
			echo '   CHECKSUM_TYPE   - Checksum algorithm to use: "md5", "sha1", "sha256", or "sha512"';
			echo '   PATH1/PATH2/etc - Paths to get checksums for';
		else
			echo "   getAll${checksumType^}Checksums PATH1 [PATH2] [PATH3] [...]";
			echo '';
			echo '   PATH1/PATH2/etc - Paths to get checksums for';
		fi
		echo '';
		echo 'This will generate a list of checksums sorted by path for all files under the passed paths. The checksums can be used for recursively comparing directories, single files, or any combination of the two are identical or have changed.';
		if [[ "md5" != "$1" && "sha1" != "$1" && "sha256" != "$1" && "sha512" != "$1" ]]; then
			echo "It behaves similarly to md5sum/sha256sum/etc except that it will automatically handle all recursive files under passed directories.";
		else
			echo "It behaves similarly to ${checksumType}sum except that it will automatically handle all recursive files under passed directories.";
		fi
		echo '';
		echo '  -b, --binary         read in binary mode'
		echo '  -t, --text           read in text mode (default)'
		echo '';
		return 500;
	fi

	# now collect checksums for the given paths, treating any directories recursively
	# To make sure that this is consistent regardless of where it is run from,
	# absolute path should always be used rather than relative paths
	declare -A fileChecksumMap;
	local fileChecksum='';
	for filePath in "${aryFileList[@]}"; do
		#echo "filePath: '${filePath}'";
		fileChecksum=$(${checksumType}sum ${checksumArgs} "${filePath}"| cut -d" " -f1);
		fileChecksumMap["${filePath}"]="${fileChecksum}";
	done

	local checksumLength=''
	if [[ "md5" == "${checksumType}" ]]; then
		checksumLength=32;
	elif [[ "sha1" == "${checksumType}" ]]; then
		checksumLength=40;
	elif [[ "sha256" == "${checksumType}" ]]; then
		checksumLength=64;
	elif [[ "sha512" == "${checksumType}" ]]; then
		checksumLength=128;
	fi

	# use another loop now that all values have been added to the map (and thus sorted)
	for filePath in "${!fileChecksumMap[@]}"; do
		fileChecksum="${fileChecksumMap[$filePath]}";
		#echo "key: $key";
		#echo "value: "${myMap[$key]}"";
		printf "%-${checksumLength}s  %s\n" "${fileChecksum}" "${filePath}";
	done
}
function getAllMd5Checksums() {
	getAllChecksums 'md5' "${@}";
}
function getAllSha1Checksums() {
	getAllChecksums 'sha1' "${@}";
}
function getAllSha256Checksums() {
	getAllChecksums 'sha256' "${@}";
}
function getAllSha512Checksums() {
	getAllChecksums 'sha512' "${@}";
}
function getCompositeChecksum() {
	local checksumType="$1";
	local showHelp="false";
	local checksumArgs='';
	local aryFileList=(  );

	if (( ${#@} < 2 )); then
		showHelp="true";
	else
		if [[ "md5" != "$1" && "sha1" != "$1" && "sha256" != "$1" && "sha512" != "$1" ]]; then
			checksumType='';
			showHelp="true";
		else
			# Precheck that are args correspond to valid paths
			for (( i=2; i<=${#@}; i++ )); do
				filePath="${@:$i:1}";
				#echo "Path[${i}]: '${filePath}'";

				# mutually-exclusive options
				if [[ "-h" == "${filePath}" || "--help" == "${filePath}" ]]; then
					showHelp="true";
					break;

				elif [[ "-b" == "${filePath}" || "--binary" == "${filePath}" ]]; then
					checksumArgs='--binary';
					continue;

				elif [[ "-t" == "${filePath}" || "--text" == "${filePath}" ]]; then
					checksumArgs='--text';
					continue;

				elif [[ ! -e "${filePath}" ]]; then
					echo "E: Path[${i}]: '${filePath}' does not exist.";
					return 404;

				elif [[ -f "${filePath}" ]]; then
					# non-argument, valid single-file path
					aryFileList+=($(realpath "${filePath}"));

				elif [[ -d "${filePath}" ]]; then
					# https://stackoverflow.com/questions/23356779/how-can-i-store-the-find-command-results-as-an-array-in-bash/54561526#54561526
					readarray -d '' aryFileList < <(find $(realpath "${filePath}") -type f -print0)
				fi
			done
		fi
	fi

	if [[ "true" == "${showHelp}" ]]; then
		echo 'Expected usage:';
		if [[ "md5" != "$1" && "sha1" != "$1" && "sha256" != "$1" && "sha512" != "$1" ]]; then
			echo '   getCompositeChecksum CHECKSUM_TYPE PATH1 [PATH2] [PATH3] [...]';
			echo '';
			echo '   CHECKSUM_TYPE   - Checksum algorithm to use: "md5", "sha1", "sha256", or "sha512"';
			echo '   PATH1/PATH2/etc - Paths to include in composite checksum';
		else
			echo "   getComposite${checksumType^} PATH1 [PATH2] [PATH3] [...]";
			echo '';
			echo '   PATH1/PATH2/etc - Paths to include in composite checksum';
		fi
		echo '';
		echo 'This will generate a cumulative checksum for the combination of all paths. The checksum can be used for recursively comparing if directories, single files, or any combination of the two are identical or have changed.';
		if [[ "md5" != "$1" && "sha1" != "$1" && "sha256" != "$1" && "sha512" != "$1" ]]; then
			echo "It behaves similarly to md5sum/sha256sum/etc except that it treats the list of files as an atomic unit and that directories are always compared recursively.";
		else
			echo "It behaves similarly to ${checksumType}sum except that it treats the list of files as an atomic unit and that directories are always compared recursively.";
		fi
		echo '';
		echo '  -b, --binary         read in binary mode'
		echo '  -t, --text           read in text mode (default)'
		echo '';
		return 500;
	fi

	# now collect checksums for the given paths, treating any directories recursively
	# To make sure that this is consistent regardless of where it is run from,
	# absolute path should always be used rather than relative paths
	declare -A fileChecksumMap;
	local fileChecksum='';
	for filePath in "${aryFileList[@]}"; do
		#echo "filePath: '${filePath}'";
		fileChecksum=$(${checksumType}sum ${checksumArgs} "${filePath}"| cut -d" " -f1);
		fileChecksumMap["${filePath}"]="${fileChecksum}";
	done

	local compositeChecksum=$(echo "${fileChecksumMap[@]}"|${checksumType}sum|cut -d" " -f1);

	printf '%s\n' "${compositeChecksum}";
}
function getCompositeMd5() {
	getCompositeChecksum 'md5' "${@}";
}
function getCompositeSha1() {
	getCompositeChecksum 'sha1' "${@}";
}
function getCompositeSha256() {
	getCompositeChecksum 'sha256' "${@}";
}
function getCompositeSha512() {
	getCompositeChecksum 'sha512' "${@}";
}
function findDuplicateLinesInFile() {
	local file="$1";
	if [[ "" == "$file" || ! -f "$file" ]]; then
		echo "E: No file passed or file does not exist.";
		return -1;
	fi

	IFS='';
	local dupeLinesArray=($(grep -Pv '^\W*$' "$file" | sort | uniq -c | grep -P '^\s+(\d{2,}|[2-9])\s+'|sed -E 's/^\s*([0-9][0-9]*)\s+(\S+)\s*$/\1\t\2/g'));
	if [[ "0" == "${#dupeLinesArray[@]}" ]]; then
		echo "No duplicate lines detected.";
		return -2;
	fi
	echo "Found ${#dupeLinesArray[@]} distinct lines that occur more than once.";
	echo "";
	echo "-----------------------------------------------------------";
	printf 'Count\tText\n';
	echo "-----------------------------------------------------------";

	local dupeTermsArray=(  );
	for ((i = 0; i < ${#dupeLinesArray[@]}; i++)); do
		echo "${dupeLinesArray[$i]}"
		dupeTerm=$(echo "${dupeLinesArray[$i]}"|sed -E 's/^\s*[0-9][0-9]*\s+(.*)$/\1/g');
		dupeTermsArray+=("${dupeTerm}");
	done
	unset dupeLinesArray;

	if [[ "0" != "${#dupeTermsArray[@]}" ]]; then
		echo "";
		echo "-----------------------------------------------------------";
		echo "Line Numbers:";
		echo "-----------------------------------------------------------";
		for ((i = 0; i < ${#dupeTermsArray[@]}; i++)); do
			dupeTerm="${dupeTermsArray[$i]}";
			if [[ "" == "${dupeTerm}" ]]; then
				continue;
			fi
			grep -Hn "${dupeTerm}" "${file}" 2>/dev/null;
		done
	fi
	unset dupeTermsArray;
}
function findWrapper() {
	# Default values
	local linkOption='';
	local searchPath='.';
	local startFromArg="0";
	local typeParam='';

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "findWrapper(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo "";
	fi

	# First arg = link options params (defaults to empty. can also use -P, -L, or -H; see man find for more info)
	local linkOption='';
	if [[ "" != "$1" ]]; then
		if [[ $1 =~ ^\-[HLP]$ ]]; then
			linkOption="$1";
			startFromArg="1";

		elif [[ "." == "$1" || "REL" == "$1" || "RELATIVE" == "$1" ]]; then
			searchPath=".";
			startFromArg="1";

		elif [[ "~" == "${1:0:1}" ]]; then
			searchPath="${HOME}${1:1}";
			startFromArg="1";

		elif [[ "/" == "${1:0:1}" ]]; then
			searchPath="$1";
			startFromArg="1";

		elif [[ "ABS" == "$1" || "PWD" == "$1" || "FULL" == "$1" || "ABSOLUTE" == "$1" ]]; then
			if [[ -d "$1" ]]; then
				searchPath="$1";
			else
				searchPath=$(pwd);
			fi
			startFromArg="1";

		elif [[ "-dir" == "$1" ]]; then
			typeParam="-type d";
			startFromArg="1";

		elif [[ "-file" == "$1" ]]; then
			typeParam="-type f";
			startFromArg="1";
		fi
	fi

	if [[ "1" == "${startFromArg}" && "" != "$2" ]]; then
		if [[ $2 =~ ^\-[HLP]$ ]]; then
			linkOption="$2";
			startFromArg="2";

		elif [[ "." == "$2" || "REL" == "$2" || "RELATIVE" == "$2" ]]; then
			searchPath=".";
			startFromArg="2";

		elif [[ "~" == "${2:0:1}" ]]; then
			searchPath="${HOME}${2:1}";
			startFromArg="2";

		elif [[ "/" == "${2:0:1}" ]]; then
			searchPath="$2";
			startFromArg="2";

		elif [[ "ABS" == "$2" || "PWD" == "$2" || "FULL" == "$2" || "ABSOLUTE" == "$2" ]]; then
			if [[ -d "$2" ]]; then
				searchPath="$2";
			else
				searchPath=$(pwd);
			fi
			startFromArg="2";

		elif [[ "-dir" == "$2" ]]; then
			typeParam="-type d";
			startFromArg="2";

		elif [[ "-file" == "$2" ]]; then
			typeParam="-type f";
			startFromArg="2";
		fi
	fi

	if [[ "2" == "${startFromArg}" && "" != "$3" ]]; then
		if [[ "-dir" == "$3" ]]; then
			typeParam="-type d";
			startFromArg="3";

		elif [[ "-file" == "$3" ]]; then
			typeParam="-type f";
			startFromArg="3";
		fi
	fi

	local hasArgs="true";
	if [[ "0" == "${startFromArg}" && "" == "$1" ]]; then
		hasArgs="false";
	elif [[ "1" == "${startFromArg}" && "" == "$2" ]]; then
		hasArgs="false";
	elif [[ "2" == "${startFromArg}" && "" == "$3" ]]; then
		hasArgs="false";
	elif [[ "3" == "${startFromArg}" && "" == "$4" ]]; then
		hasArgs="false";
	fi

	# increment by 1 (since the 0 arg will be ignored anyway - see comments below)
	startFromArg=$(( startFromArg + 1 ));

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "";
		echo "\$1: $1";
		echo "\$2: $2";
		echo "\$3: $3";
		echo "\$4: $4";
		echo "";
		echo "\${@}: ${@}";
		echo "\${@:0}: ${@:0}";
		echo "\${@:1}: ${@:1}";
		echo "\${@:2}: ${@:2}";
		echo "\${@:3}: ${@:3}";
		echo "\${@:4}: ${@:4}";
		echo "\${@:5}: ${@:5}";
		echo "\${@:6}: ${@:6}";
		echo "";
		echo "hasArgs: $hasArgs";
		echo "linkOption: $linkOption";
		echo "searchPath: $searchPath";
		echo "startFromArg: $startFromArg";
		echo "typeParam: $typeParam";
	fi

	if [[ "true" == "${hasArgs}" ]]; then
		# "${@}"   - all arguments (the zero arg, which is the function name, is omitted)
		# "${@:1}" - all arguments (the zero arg, which is the function name, is omitted)
		# "${@:2}" - all arguments except the first one
		# "${@:3}" - all arguments except the first and second ones
		find $linkOption "${searchPath}" $typeParam -not \( -wholename '*.git/*' -o -wholename '*.hg/*' -o -wholename '*.svn/*' \) "${@:${startFromArg}}" 2>/dev/null;
	else
		# There were no args besides possibly the ones for the linkOption / searchPath ...
		find $linkOption "${searchPath}" $typeParam -not \( -wholename '*.git/*' -o -wholename '*.hg/*' -o -wholename '*.svn/*' \) 2>/dev/null;
	fi
}
function findWrapperWithRelativePaths() {
	findWrapper REL "${@}";
}
function findWrapperWithAbsolutePaths() {
	findWrapper ABS "${@}";
}
function findLinkedFilesIgnoringStdErr() {
	if [[ "" == "$1" || "-" == "${1:0:1}" ]]; then
		findWrapper REL -L -file "${@}";
	else
		findWrapper REL -L -file -iname "${@}";
	fi
}
function findUnlinkedFilesIgnoringStdErr() {
	if [[ "" == "$1" || "-" == "${1:0:1}" ]]; then
		findWrapper REL -file "${@}";
	else
		findWrapper REL -file -iname "${@}";
	fi
}
function findLinkedDirsIgnoringStdErr() {
	if [[ "" == "$1" || "-" == "${1:0:1}" ]]; then
		findWrapper REL -L -dir "${@}";
	else
		findWrapper REL -L -dir -iname "${@}";
	fi
}
function findUnlinkedDirsIgnoringStdErr() {
	if [[ "" == "$1" || "-" == "${1:0:1}" ]]; then
		findWrapper REL -dir "${@}";
	else
		findWrapper REL -dir -iname "${@}";
	fi
}
function createArchive() {
	local fnName="createArchive";
	local compressionLevel="9";
	local displayHelp=0;
	local outputFileExt="";
	local isValidShortSuffix=0;
	local archivePath="";
	local useTimestampForAutoNaming=1;
	local useLongTarExtsForAutoNaming=1;

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "===============================================================";
		echo "${fnName}(): Debug";
		echo "===============================================================";
		echo "passed args: $@";
		echo "";
	fi

	# the following is a conveinence option for trying to find the lowest common parent dir
	# of multiple passed arguments. When calling the function with e.g.:
	#		${fnName} tar.xz somepath/* archive.tar.xz
	#	which bash will automatically map this to:
	#		${fnName} tar.xz somepath/file1 somepath/file2 somepath/file3 ...  archive.tar.xz
	#
	# the intention behind this option is to take somepath out of the call so that it does not
	# appear in the final archive; similarly to if the user had done the call as:
	#		outdir="$PWD";
	#		cd somepath/
	#		${fnName} tar.xz ./* "${outdir}/archive.tar.xz"
	#		cd "$outdir";
	#
	# This obviously only applies if all of the passed files are under some common parent.
	# NOTE: This function will enable this option by default for single-target arguments
	#
	local startingDir=$(pwd);
	local allowAutoDirTrim=1;
	local folderMode='relative';
	local avoidPackagingParentDirs=0;

	# Parse passed args for options e.g. ignore paths for now, except for
	# those following options that take a path
	local aryPassedOptions=(  );
	local aryPassedPaths=(  );
	if (( ${#@} > 0 )); then
		# this is for restoring the initial state of extglob when we're done.
		# we want it here for more advanced case statement handling but based on my
		# testing this setting persists from functions to the shell they were called on
		# so this captures the flag to use when we're done (s=set, u=unset)
		# setting and already enabled option back on is basically a no-op so
		# this more about turning it back off it that's how we started
		local initialExtglobFlag=$(shopt extglob|cut -f2|awk '{if($1=="on"){print "s"}else{print "u"}}');

		[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Found ${#@} passed args"
		local argsList
		local passedArg="";
		local nextArg='';
		local skipNext=0;
		local j=0;
		local i=0;

		# set extglob so we make use of patterns in the case statement
		# 	https://stackoverflow.com/questions/4554718/how-to-use-patterns-in-a-case-statement
		shopt -s extglob;

		for (( i=1; i<=${#@}; i++ )); do
			# if previous iteration has set the skipNext flag, unset it and skip this arg
			if [[ 1 == ${skipNext} ]]; then
				skipNext=0;
				[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "skipping value arg '${passedArg}'";
				continue;
			fi

			passedArg="${@:$i:1}";
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Found passed arg '${passedArg}'";

			if [[ '-' != "${passedArg:0:1}" ]]; then
				# PATH - note we don't want to validate paths at this stage
				# because we want to allow the archivePath (does not exist)
				# to be added to the final path location. will validate below
				[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Found path: '${passedArg}'";
				aryPassedPaths+=("${passedArg}");

			elif [[ '-' == "${passedArg:0:1}" ]]; then
				# OPTION
				[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Checking option '${passedArg}'";

				# some options are dependent on the next parameter; have it ready
				j=$(( i + 1 ));
				if (( j < ${#@} )); then
					nextArg="${@:$j:1}";
				else
					nextArg='';
				fi

				# Handle single-hyphen grouped args by breaking them out into an
				# argsList that we can loop over. e.g.:
				#	if passedArg = '--something' => argsList = '--something'
				#	or len(passedArg) = 2 aka passedArg = '-s' => argsList = '-s'
				#	but if
				#	passedArg = '-4zXM' => argsList = '-4 -z -X -M'
				# 	so that we can properly capture each one
				if [[ '2' == "${#passedArg}" || '--' == "${passedArg:0:2}" ]]; then
					argsList="${passedArg}";

				elif [[ ${passedArg} =~ ^\-[A-Zb-eg-np-z0-9]*[aof][A-Zb-eg-np-z0-9]*$ ]]; then
					echo "E: The options -o, -a, and -f cannot be grouped with other single-hyphen options";
					echo "as they require an additional argument.";
					displayHelp=1;
					continue;
				else
					argsList="$(echo "${passedArg}"|sed -E -e 's/(\w)(\w)/\1 -\2/g' -e 's/(\w)(\w)/\1 -\2/g')";
				fi

				for passedArg in $(echo "${argsList}"); do
					#echo "passedArg: $passedArg";

					#
					# case statement: to fall through use ";&" to break use ";;"
					#	see: https://stackoverflow.com/questions/12010686/case-statement-fallthrough
					#
					#	":" is a no-op (e.g. just to avoid errors from not defining an operation)
					#
					# For the patterns:
					#	?() - zero or one occurrences of pattern
					#	*() - zero or more occurrences of pattern
					#	+() - one or more occurrences of pattern
					#	@() - one occurrence of pattern
					#
					# Single-letters that are already in use:
					#	lower: abdfghjotxz
					#	upper: AFJMRSTWXZ
					case "${passedArg}" in

						# match -h or --help
						-h|--help  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							displayHelp=1;
							;;

						# match M, S, or any of the double-hyphened keywords
						-[MS]                                         )     : ;&
						--min|--minimal|--shortest                    )     : ;&
						--min-path|--minimal-path|--shortest-path     )     : ;&
						--min-paths|--minimal-paths|--shortest-paths  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set flag
							avoidPackagingParentDirs=1;
							folderMode='minimal';
							# store option
							aryPassedOptions+=("--minimal-paths");
							;;

						# match T, R, or any of the double-hyphened keywords
						-[TR]                                 )     : ;&
						--rel-path|relative-path|trim-path    )     : ;&
						--rel-paths|relative-paths|trim-paths )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set flag
							avoidPackagingParentDirs=1;
							folderMode='relative';
							# store option
							aryPassedOptions+=("--trim-paths");
							;;

						# match T, R, or any of the double-hyphened keywords
						-W|--pwd|--PWD|--cd|--wd                       )     : ;&
						--current-dir|--current-path|--current-paths   )     : ;&
						--working-dir|--working-path|--working-paths   )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set flag
							avoidPackagingParentDirs=1;
							folderMode='working';
							# store option
							aryPassedOptions+=("--working-dir");
							;;

						# match F, A, or any of the double-hyphened keywords
						-[FA]|--abs-path|--abs-patsh|--full-path       )     : ;&
						--full-paths|--absolute-path|--absolute-paths  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set flags
							folderMode='absolute';
							allowAutoDirTrim=0;
							avoidPackagingParentDirs=0;
							# store option
							aryPassedOptions+=("--explicit-paths");
							;;

						# match a, o, or any of the double-hyphened keywords
						-[ao]|--out|--outfile|--output|--outputfile   )     : ;&
						--archive|--archivefile|--archive-file        )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							if [[ '' == "${nextArg}" ]]; then
								echo "E: Found option '${passedArg}' but no file specified.";
								displayHelp=1;
							else
								# set local variable
								archivePath="${nextArg}";
								# store option
								aryPassedOptions+=("--archive ${nextArg}");
								skipNext=1;
							fi
							;;

						# match -d or --no-date or --no-timestamp
						-d|--no-date|--no-timestamp  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variable
							useTimestampForAutoNaming=0;
							# store option
							aryPassedOptions+=("--no-timestamp");
							;;

						# match -X or --tz or --short-exts
						-X|--tz|--short-exts  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variable
							useLongTarExtsForAutoNaming=0;
							# store option
							aryPassedOptions+=("--short-exts");
							;;

						# match -f or --format
						-f|--format  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							if [[ '' == "${nextArg}" ]]; then
								echo "E: Found option '${passedArg}' but no value specified.";
								displayHelp=1;
							elif [[ 'tar' != "${nextArg}" && ${nextArg} =~ ^tar\.[glx]z$ && \
									'tar.Z' != "${nextArg}" && 'tar.lzo' != "${nextArg}" && \
									'tar.lzma' != "${nextArg}" && 'tar.zst' != "${nextArg}" && \
									'tar.bz2' != "${nextArg}" && 'zip' != "${nextArg}" \
									&& '7z' != "${nextArg}" && 'zpaq' != "${nextArg}" \
								]]; then

								echo "E: Found option '${passedArg}' but value '${nextArg}' is invalid.";
								displayHelp=1;
							else
								# set local variable
								outputFileExt="${nextArg}";
								# store option
								aryPassedOptions+=("--format ${nextArg}");
								skipNext=1;
							fi
							;;

						# match -t or --tar
						-t|--tar  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variable
							outputFileExt="tar";
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match [-b, --bz, --bz2, --bzip, --tbz] or tar options of [-j, --bzip2]
						-[bj]|--bz|--bz2|--bzip|--bzip2|--tbz  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variables
							outputFileExt="tar.bz2";
							if [[ '--tbz' == "${passedArg}" ]]; then
								useLongTarExtsForAutoNaming=0;
							fi
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match [-g, --gz, --tgz] or tar options of [-z, --gzip, --gunzip]
						-[gz]|--gz|--gzip|--gunzip|--tgz  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variables
							outputFileExt="tar.gz";
							if [[ '--tgz' == "${passedArg}" ]]; then
								useLongTarExtsForAutoNaming=0;
							fi
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match [-x, --txz] or tar options of [-J, --xz]
						-[xJ]|--xz|--txz  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variables
							outputFileExt="tar.xz";
							if [[ '--txz' == "${passedArg}" ]]; then
								useLongTarExtsForAutoNaming=0;
							fi
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match [--tlz] or tar options [--lzma]
						--lzma|--tlz  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variables
							outputFileExt="tar.lzma";
							if [[ '--tlz' == "${passedArg}" ]]; then
								useLongTarExtsForAutoNaming=0;
							fi
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match [--tzst] or tar options [--zstd]
						--tzst|--zstd  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variables
							outputFileExt="tar.zst";
							if [[ '--tzst' == "${passedArg}" ]]; then
								useLongTarExtsForAutoNaming=0;
							fi
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match --7z or --7zip
						--7z|--7zip  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variable
							outputFileExt="7z";
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match -Z or --compress or --tZ
						-Z|--compress|--tZ  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variables
							outputFileExt="tar.Z";
							if [[ '--tZ' == "${passedArg}" ]]; then
								useLongTarExtsForAutoNaming=0;
							fi
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match --lzip
						--lzip  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variables
							outputFileExt="tar.lz";
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match --lzop
						--lzop  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variables
							outputFileExt="tar.lzo";
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match [--zip, --zpaq]
						--zip|--zpaq  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							# set local variable
							outputFileExt="${passedArg:2}"; # start from index 2 to remove '--' prefix
							# store option
							aryPassedOptions+=("--format ${outputFileExt}");
							;;

						# match -[1-9], --c[1-9], or any of the double-hyphened keywords
						-[1-9]|--c[1-9]|--compression|--compression-level  )
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting flags for option '${passedArg}'";
							if [[ ${passedArg} =~ ^.*[1-9]$ ]]; then
								# set local variable
								compressionLevel="${passedArg:${#passedArg}-1:1}";
								# store option
								aryPassedOptions+=("--compression-level ${compressionLevel}");

							elif [[ '' == "${nextArg}" ]]; then
								echo "E: Found option '${passedArg}' but no value specified.";
								displayHelp=1;

							elif [[ ! ${nextArg} =~ ^[1-9]$ ]]; then
								echo "E: Found option '${passedArg}' but value '${nextArg}' is invalid.";
								displayHelp=1;

							else
								# set local variable
								compressionLevel="${nextArg}";
								# store option
								aryPassedOptions+=("--compression-level ${nextArg}");
								skipNext=1;
							fi
							;;

						*)
							echo "E: Unknown option '${passedArg}'";
							displayHelp=1;
					esac
				done
				# end: for passedArg in $(echo "${argsList}"); do
			fi
			# end handling of If Path vs Option
		done
		# end: for (( i=1; i<=${#@}; i++ )); do

		# restore original extglob state, if it was different
		if [[ 'u' == "${initialExtglobFlag}" ]]; then
			shopt -u extglob;
		fi
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "";
		echo "----------------------------------------------------------------------";
		echo "After processing options";
		echo "----------------------------------------------------------------------";
		echo "displayHelp:                 '${displayHelp}'";
		echo "startingDir:                 '${startingDir}'";
		echo "outputFileExt:               '${outputFileExt}'";
		echo "archivePath:                 '${archivePath}'";
		echo "compressionLevel:            '${compressionLevel}'";
		echo "isValidShortSuffix:          '${isValidShortSuffix}'";
		echo "allowAutoDirTrim:            '${allowAutoDirTrim}'";
		echo "avoidPackagingParentDirs:    '${isValidShortSuffix}'";
		echo "folderMode:                  '${folderMode}'";
		echo "useTimestampForAutoNaming:   '${useTimestampForAutoNaming}'";
		echo "useLongTarExtsForAutoNaming: '${useLongTarExtsForAutoNaming}'";
		echo "";
		echo "aryPassedOptions size:       '${#aryPassedOptions[@]}'";
		echo "aryPassedOptions:            '${aryPassedOptions[@]}'";
		echo "";
		echo "aryPassedPaths size:         '${#aryPassedPaths[@]}'";
		echo "aryPassedPaths:              '${aryPassedPaths[@]}'";
		echo "";
	fi

	# ===========================================================================================
	# VALIDATIONS:
	#		checkIfOptionalValueExists(archivePath)
	#		requireValueExists(outputFileExt)
	# ===========================================================================================
	# if outputFileExt and/or archivePath were not set explicitly, then try to infer them
	# rules:
	#	1. archivePath is optional and can be omitted. But if present and not explicitly
	#		set via options, then it should ALWAYS appear as the LAST path argument.
	#
	#	2. outputFileExt can optionally be set based on archivePath (assuming archivePath
	#		is set to a known and supported format type).
	#
	#	3. If archivePath cannot be determined, this should be allowed without failure.
	#
	#	4. If outputFileExt cannot be determined, this should result in FAILURE.
	#
	#	5. There must always be at least ONE path that exists and is NOT archivePath
	#		or outputFileExt. Otherwise, this should result in FAILURE.
	# ===========================================================================================

	# we should check for archivePath first, as if it exists, it can be used to infer outputFileExt
	if [[ 1 != ${displayHelp} && ${#aryPassedPaths[@]} -ge 2 && "" == "${archivePath}" ]]; then
		local lastPath="${aryPassedPaths[-1]}";
		[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "lastPath:  '${lastPath}'";

		# if last path is not empty, doesn't end in a trailing slash (e.g. is for a dir)
		# AND does not exist, then we can safely assume it is the archivePath
		if [[ '' != "${lastPath}" && '/' != "${lastPath:${#lastPath}:1}" && ! -e "${lastPath}" ]]; then
			# set archivePath
			archivePath="${lastPath}";

			# remove the last element (-1) from the paths array
			unset aryPassedPaths[-1];

			if [[	'.tbz2' == "${archivePath:${#archivePath}-5}" 	|| \
					'.tZ' == "${archivePath:${#archivePath}-3}" 	|| \
					'.taZ' == "${archivePath:${#archivePath}-4}" 	|| \
					'.tzst' == "${archivePath:${#archivePath}-5}" 	|| \
					${archivePath:${#archivePath}-4} =~ ^\.t[bz]2$ 	|| \
					${archivePath:${#archivePath}-4} =~ ^\.t[ablgx]z$ \
				]]; then

				isValidShortSuffix=1;
			fi
		fi
		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "";
			echo "----------------------------------------------------------------------";
			echo "After checking the last path";
			echo "----------------------------------------------------------------------";
			echo "archivePath:                 '${archivePath}'";
			echo "isValidShortSuffix:          '${isValidShortSuffix}'";
			echo "";
			echo "aryPassedPaths size:         '${#aryPassedPaths[@]}'";
			echo "aryPassedPaths:              '${aryPassedPaths[@]}'";
			echo "";
		fi
	fi

	# now that archivePath should no longer exist in aryPassedPaths,
	# validate that we have at least one path (validation of existance will be later)
	if [[ 1 != ${displayHelp} && ${#aryPassedPaths[@]} -eq 0 ]]; then
		echo "E: Missing target/source path (nothing to add to archive)";
		displayHelp=1;
	fi

	# make sure outputFileExt is set and valid
	if [[ 1 != ${displayHelp} && "" == "${outputFileExt}" && '' != "${archivePath}" ]]; then
		#
		# If func args do NOT specify an explicit output format:
		#	-> then attempt to map by extension from passed output archive
		#
		local last2="${archivePath:${#archivePath}-2}";
		local last3="${archivePath:${#archivePath}-3}";
		local last4="${archivePath:${#archivePath}-4}";
		local last5="${archivePath:${#archivePath}-5}";
		local last6="${archivePath:${#archivePath}-6}";
		local last7="${archivePath:${#archivePath}-7}";
		local last8="${archivePath:${#archivePath}-8}";
		local last9="${archivePath:${#archivePath}-9}";

		# 2-char extensions: 7Z:
		if [[ '.7z' == "${last3}" ]]; then
			outputFileExt="${last2}"; # -1 to remove dot

		# 2-char "Short" suffixes:
		#	https://en.wikipedia.org/wiki/Tar_(computing)#Suffixes_for_compressed_files
		elif [[ '.tZ' == "${last3}" ]]; then
			isValidShortSuffix=1;
			outputFileExt='tar.Z';

		# 3-char extensions: TAR, ZIP
		elif [[ '.tar' == "${last4}" || '.zip' == "${last4}" ]]; then
			outputFileExt="${last3}"; # -1 to remove dot

		# 3-char "Short" suffixes:
		#	https://en.wikipedia.org/wiki/Tar_(computing)#Suffixes_for_compressed_files
		elif [[ ${last4} =~ ^\.t[bz]2$ || ${last4} =~ ^\.t[abglx]z$ || 'taZ' == "${last4}" ]]; then
			isValidShortSuffix=1;
			case "${last3}" in # -1 to remove dot
				tb2) outputFileExt='tar.bz2'; ;;
				tbz) outputFileExt='tar.bz2'; ;;
				tz2) outputFileExt='tar.bz2'; ;;
				taz) outputFileExt='tar.gz'; ;;
				tgz) outputFileExt='tar.gz'; ;;
				txz) outputFileExt='tar.xz'; ;;
				tlz) outputFileExt='tar.lzma'; ;;
				taZ) outputFileExt='tar.Z'; ;;
			esac

		# 4-char extensions: ZPAQ
		elif [[ '.zpaq' == "${last5}" ]]; then
			outputFileExt="${last4}"; # -1 to remove dot

		# 4-char "Short" suffixes:
		#	https://en.wikipedia.org/wiki/Tar_(computing)#Suffixes_for_compressed_files
		elif [[ '.tbz2' == "${last5}" || '.tzst' == "${last5}" ]]; then
			isValidShortSuffix=1;
			case "${last4}" in # -1 to remove dot
				tbz2) outputFileExt='tar.bz2'; ;;
				tzst) outputFileExt='tar.zst'; ;;
			esac

		# 6-char extensions: TAR.BZ, TAR.GZ, TAR.XZ, TAR.LZ
		elif [[ ${last7} =~ ^\.tar\.[gx]z$ || '.tar.lz' == "${last7}" ]]; then
			outputFileExt="${last6}"; # -1 to remove dot

		# 7-char extensions: TAR.ZST, TAR.LZO
		elif [[ '.tar.bz2' == "${last8}" || '.tar.zst' == "${last8}" || '.tar.lzo' == "${last8}" ]]; then
			outputFileExt="${last7}"; # -1 to remove dot

		# 8-char extensions: TAR.LZMA
		elif [[ '.tar.lzma' == "${last9}" ]]; then
			outputFileExt="${last8}"; # -1 to remove dot

		else
			if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
				echo "-> unkown archive type found on passed output archive.";
			fi
			echo "E: Invalid or unsupported archive type; see --format option.";
			displayHelp=1;
		fi

		if [[ 1 == $DEBUG_BASH_FUNCTIONS && 1 != ${displayHelp} && "" != "${outputFileExt}" ]]; then
			echo "-> supported output format set from passed output archive as '${outputFileExt}'.";
		fi
	fi
	# end if: outputFileExt not set, attempt to set from archivePath

	# if we still don't have output format, then report error
	if [[ 1 != ${displayHelp} ]]; then
		if [[ "" == "${outputFileExt}" ]]; then
			echo "E: No archive type specified; see --format option.";
			displayHelp=1;

		elif [[ ${outputFileExt} =~ ^tar.*$ && 1 != $(which $WHICH_OPTS tar 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but the tar package is not installed.";
			return -3;

		elif [[ "tar.bz2" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS bzip2 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but the bzip2 package is not installed.";
			return -3;

		elif [[ "tar.gz" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS gzip 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but the gzip package is not installed.";
			return -3;

		elif [[ "tar.lzma" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS lzma 2>/dev/null|wc -l) && 1 != $(which $WHICH_OPTS xz 2>/dev/null|wc -l) ]]; then
			# on most modern nixes, lzma is a symlink to xz
			# https://unix.stackexchange.com/questions/72037/difference-between-xz-and-lzma-in-gnu-tar
			echo "E: Archive type is '${outputFileExt}' but lzma/xz packages not installed.";
			return -3;

		elif [[ "tar.xz" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS xz 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but the xz package is not installed.";
			return -3;

		elif [[ "tar.lz" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS lz 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but lz/mtools package not installed.";
			return -3;

		elif [[ "tar.lzo" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS lzop 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but the lzop package not installed.";
			return -3;

		elif [[ "tar.zst" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS zstd 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but the zstd package is not installed.";
			return -3;

		elif [[ "tar.Z" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS compress 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but compress/ncompress package not installed.";
			return -3;

		elif [[ "7z" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS 7z 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but the 7z package is not installed.";
			return -3;

		elif [[ "zip" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS zip 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but the 7z package is not installed.";
			return -3;

		elif [[ "zpaq" == "${outputFileExt}" && 1 != $(which $WHICH_OPTS zpaq 2>/dev/null|wc -l) ]]; then
			echo "E: Archive type is '${outputFileExt}' but the zpaq package is not installed.";
			return -3;

		else
			case "${outputFileExt}" in
				# ignore valid types
				7z        )		: ;&
				zip       )		: ;&
				zpaq      )		: ;&
				tar       )		: ;&
				tar.bz2   )		: ;&
				tar.gz    )		: ;&
				tar.lz    )		: ;&
				tar.lzma  )		: ;&
				tar.lzo   )		: ;&
				tar.xz    )		: ;&
				tar.zst   )		: ;&
				tar.Z     )		: ;;

				*      )
					echo "E: Archive type '${outputFileExt}' is not supported; see --format option.";
					displayHelp=1;
				;;
			esac
		fi
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "";
		echo "----------------------------------------------------------------------";
		echo "After format validations";
		echo "----------------------------------------------------------------------";
		echo "displayHelp:                 '${displayHelp}'";
		echo "outputFileExt:               '${outputFileExt}'";
		echo "isValidShortSuffix:          '${isValidShortSuffix}'";
		echo "";
	fi

	if [[ 1 != ${displayHelp} && 1 == ${allowAutoDirTrim} && 'absolute' != "${folderMode}" ]]; then
		# For very simple cases such as:
		#	a) single argument target ('1' == "${#@}") with auto-generated output path
		#	b) single target with passed output path ('2' == "${#@}")
		#
		# automatically, avoid packaging the parent directories whenever possible
		#
		if [[ ${#aryPassedPaths[@]} -eq 2 || ( ${#aryPassedPaths[@]} -eq 1 && '' == "${archivePath}" ) ]]; then
			avoidPackagingParentDirs=1;
			if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
				echo "-> defaulting to avoidPackagingParentDirs=1 for single target archiving.";
			fi
		fi
	fi

	local commonTargetParent='';
	if [[ 1 != ${displayHelp} && ${#aryPassedPaths[@]} -ge 1 ]]; then
		#
		# Validate paths, remove trailing slashes, calculate common parent
		#
		[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Validating passed paths exist ...";
		local sourcePath="";
		local exitWithoutHelp=0;
		local hasMismatchedPaths=0;
		local sourcePathDir='';

		if [[ 1 == ${allowAutoDirTrim} && 'working' == "${folderMode}" ]]; then
			commonTargetParent="$(realpath "${startingDir}")";
		fi

		for (( i=0; i < ${#aryPassedPaths[@]}; i++ )); do
			sourcePath="${aryPassedPaths[$i]}";
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "---------------------------------------";
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Checking sourcePath '${sourcePath}' ...";

			if [[ ! -e "${sourcePath}" ]]; then
				echo "E: Source path '${sourcePath}' does not exist.";
				exitWithoutHelp=1;
				continue;
			fi

			# remove trailing slashes
			if [[ '/' == "${sourcePath:${#sourcePath}-1:1}" ]]; then
				aryPassedPaths[$i]="${sourcePath:0:${#sourcePath}-1}";
			fi

			# work on determining the longest shared path
			if [[ 1 != ${hasMismatchedPaths} ]]; then
				sourcePathDir="$(realpath "$(dirname "${sourcePath}")")";
				if [[ 1 == ${allowAutoDirTrim} && 'minimal' == "${folderMode}" && -d "${sourcePath}" ]]; then
					sourcePathDir="$(realpath "${sourcePath}")";
				fi
				[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "sourcePathDir '${sourcePathDir}' ...";

				if [[ '' == "${commonTargetParent}" ]]; then
					commonTargetParent="${sourcePathDir}";
					[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting initial commonTargetParent: '${commonTargetParent}' ...";

				# if current target is the same dir, then nothing to do ...
				elif [[ "${commonTargetParent}" == "${sourcePathDir}" ]]; then
					continue;

				# if two root dirs are different, then it's a bust
				elif [[ "$(echo "${sourcePathDir}"|cut -d/ -f1,2)" != "$(echo "${commonTargetParent}"|cut -d/ -f1,2)" ]]; then
					[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Found different root paths; setting hasMismatchedPaths=1";
					hasMismatchedPaths=1;

				# if current target is a parent-dir, then need to set commonTargetParent to it
				elif [[ "${#sourcePathDir}" -le "${#commonTargetParent}" && "${sourcePathDir}" == "${commonTargetParent:0:${#sourcePathDir}}" ]]; then
					commonTargetParent="${sourcePathDir}";
					[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Current path is parent. Updating commonTargetParent: '${commonTargetParent}' ...";

				# if current target is a sub-dir, then nothing to do ...
				elif [[ "${#commonTargetParent}" -le "${#sourcePathDir}" && "${commonTargetParent}" == "${sourcePathDir:0:${#commonTargetParent}}" ]]; then
					[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Current path is child. skipping ...";
					continue;

				else
					[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Paths are not direct Parent/Child. Analyzing ...";

					local arrComm=($(echo "${commonTargetParent}"|tr '/' '\n'|grep -Pv '^$'))
					local arrCurr=($(echo "${sourcePathDir}"|tr '/' '\n'|grep -Pv '^$'))

					[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "  -> arrComm: '${arrComm[@]}'";
					[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "  -> arrCurr: '${arrCurr[@]}'";

					local ceiling=${#arrComm[@]};
					if [[ ${#arrCurr} -lt ${#arrComm[@]} ]]; then
						ceiling=${#arrCurr[@]};
					fi
					[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "  -> ceiling: '${ceiling[@]}'";

					local sharedPath='';
					for (( j=0; j < ${ceiling}; j++ )); do
						local commDir="${arrComm[$j]}";
						local currDir="${arrCurr[$j]}";
						[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "  -> curr: '${currDir}', comm: '${commDir}'";
						if [[ "${currDir}" == "${commDir}" ]]; then
							sharedPath="${sharedPath}/${currDir}";
							[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "  -> sharedPath: '${sharedPath}'";
						else
							break;
						fi
					done

					if [[ '' == "${sharedPath}" ]]; then
						hasMismatchedPaths=1;
						[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "No common ancestor found. Setting hasMismatchedPaths=1";
					else
						commonTargetParent="${sharedPath}";
						[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Found common ancestor. Updating commonTargetParent: '${commonTargetParent}' ...";
					fi
				fi
			fi
		done;

		if [[ 1 != ${exitWithoutHelp} && ${#aryPassedPaths[@]} -eq 1 ]]; then
			if [[ 1 == ${allowAutoDirTrim} && ( 'relative' == "${folderMode}" || 'minimal' == "${folderMode}" ) ]]; then
				sourcePath="${aryPassedPaths[0]}";
				if [[ 'minimal' == "${folderMode}" && -d "${sourcePath}" ]]; then
					commonTargetParent="$(realpath "${aryPassedPaths[0]}")";
				else
					commonTargetParent="$(realpath "$(dirname "${aryPassedPaths[0]}")")";
				fi
				[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Setting solo commonTargetParent: '${commonTargetParent}' ...";
			fi
		fi

		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "";
			echo "----------------------------------------------------------------------";
			echo "After array validations";
			echo "----------------------------------------------------------------------";
			echo "displayHelp:                 '${displayHelp}'";
			echo "avoidPackagingParentDirs:    '${avoidPackagingParentDirs}'";
			echo "exitWithoutHelp:             '${exitWithoutHelp}'";
			echo "commonTargetParent:          '${commonTargetParent}'";
			echo "hasMismatchedPaths:          '${hasMismatchedPaths}'";
			echo "";
		fi

		if [[ 1 == ${exitWithoutHelp} ]]; then
			return -1;
		fi

		# second pass: handle trimming parent path from array entries
		if [[ 1 != ${hasMismatchedPaths} && 1 == ${allowAutoDirTrim} && 'absolute' != "${folderMode}" ]]; then
			if [[ '' != "${commonTargetParent}" && -d "${commonTargetParent}" ]]; then
				[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Canonicalizing passed paths ...";

				local realSourcePath='';
				local relativeSourcePath='';

				for (( i=0; i < ${#aryPassedPaths[@]}; i++ )); do
					sourcePath="${aryPassedPaths[$i]}";
					[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Checking sourcePath '${sourcePath}' ...";

					realSourcePath="$(realpath "${sourcePath}")";

					# +1 is to skip over folder seperators (e.g. '/')
					relativeSourcePath="${realSourcePath:${#commonTargetParent}+1}";

					if [[ ! ${#relativeSourcePath} -eq ${#sourcePath} ]]; then
						aryPassedPaths[$i]="${relativeSourcePath}";
					fi
				done;

				if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
					echo "";
					echo "----------------------------------------------------------------------";
					echo "After path canonicalization";
					echo "----------------------------------------------------------------------";
					echo "displayHelp:                 '${displayHelp}'";
					echo "commonTargetParent:          '${commonTargetParent}'";
					echo "";
					echo "aryPassedPaths size:         '${#aryPassedPaths[@]}'";
					echo "aryPassedPaths:              '${aryPassedPaths[@]}'";
					echo "";
				fi
			fi
		fi
	fi

	if [[ 1 == ${displayHelp} ]]; then
		echo "";
		echo "Expected usage:";
		echo "  ${fnName} PATH_TO_BE_ARCHIVED";
		echo "  ${fnName} PATH_TO_BE_ARCHIVED [PATH2 PATH3 etc]";
		echo "  ${fnName} [OPTIONS] PATH_TO_BE_ARCHIVED [PATH2 PATH3 etc]";
		echo "  ${fnName} [OPTIONS] PATH_TO_BE_ARCHIVED [PATH2 PATH3 etc] [OUTPUT_ARCHIVE]";
		echo "";
		echo "This function will generate a tar-based archive containing one or more paths";
		echo "as specified by the passed arguments.";
		echo "";
		echo "Note: OUTPUT_ARCHIVE can only be specified as the last parameter, if no file";
		echo "with the same path exists prior to calling the function. If overwritting an ";
		echo "existing file is desired, then OUTPUT_ARCHIVE should be set using the -o option";
		echo "as shown below.";
		echo "";
		echo "If OUTPUT_ARCHIVE is not provided then the function will default to using the";
		echo "path of the first file plus a timestamp and the proper archive extension:";
		echo "   e.g. '/path/to/be/archived.\$(date +'%Y-%m-%d@%H%M%S').\${ext}' ";
		echo "";
		echo "If OUTPUT_ARCHIVE is provided but the extension does not match the indicated";
		echo "format option, then the function will automatically correct it.";
		echo "";
		echo "OPTIONS:";
		echo "";
		echo "   -h, --help             display this help text";
		echo "";
		echo "   -d, --no-date,         Only applies when OUTPUT_ARCHIVE is not specified.";
		echo "   --no-timestamp         When used, the generated OUTPUT_ARCHIVE name will";
		echo "                          not include any timestamps in the archive name.";
		echo "";
		echo "   -X, --tz,              Only applies when OUTPUT_ARCHIVE is not specified";
		echo "   --short-exts           and one of the tar.xx formats is used. Makes the";
		echo "                          generated OUTPUT_ARCHIVE use the short form";
		echo "                          extensions instead of the long form ones that are";
		echo "                          used by default. In other words: .tar.bz2 => .tbz,";
		echo "                          .tar.gz => .tgz, and .tar.xz => .txz ";
		echo "";
		echo "   --format FORMAT,       use the specified archive format. valid values";
		echo "   -f FORMAT              are: tar, tar.bz2, tar.gz, tar.xz, tar.lzma, tar.Z,";
		echo "                          tar.lz, tar.lzo, tar.zst, 7z, zip, or zpaq";
		echo "";
		echo "   -t, --tar              use the tar format; same as -f 'tar'";
		echo "   -b, -j, --bz, --bz2,   use the tar.bz2 format; same as -f 'tar.bz2'";
		echo "   --bzip, --bzip2";
		echo "   -Z, --compress         use the tar's compress option; same as -f 'tar.Z'";
		echo "   -g, -z, --gz, --gzip,  use the tar.gz format; same as -f 'tar.gz'";
		echo "   --gunzip";
		echo "   -x, -J, --xz           use the tar.xz format (LZMA2); same as -f 'tar.xz'";
		echo "";
		echo "   --lzma                 use the tar.lzma format (LZMA1); same as -f 'tar.lzma'";
		echo "   --lzip                 use the tar.lz format; same as -f 'tar.lz'";
		echo "   --lzop                 use the tar.lzo format; same as -f 'tar.lzo'";
		echo "   --zstd                 use the tar.zst format; same as -f 'tar.zst'";
		echo "";
		echo "   --7z, --7zip           use the 7z format; same as -f '7z'. Requires 7z package.";
		echo "   --zip                  use the zip format; same as -f 'zip'. Requires zip package.";
		echo "   --zpaq                 use the zpaq format; same as -f 'zpaq'. Requires zpaq package.";
		echo "";
		echo "   --compression-level,   set compression-level so some value 0-9. 0 is the fastest but";
		echo "   -[0-9], --c[0-9]       does not compress. 9 is the slowest but has the best compression.";
		echo "";
		echo "   -a FILE, -o FILE,      use the filepath FILE to save the output archive to";
		echo "   --archive FILE,";
		echo "   --outfile FILE";
		echo "";
		echo "   -T, --trim-paths,      This is the default behavior is no options are";
		echo "   -R, --relative-paths   specified. The function will use trim any paths";
		echo "                          so that the archive starts relative to the passed";
		echo "                          target/source paths rather than relative to '/'";
		echo "                          as tar normally does. Also note that the relative path";
		echo "                          starts *at* the given path, not under it.";
		echo "                          To disable, see --full-paths. Also see the examples";
		echo "                          below for more details.";
		echo "";
		echo "   -F, --full-paths,      Opposite of --trim-paths; uses normal tar behavior of";
		echo "   -A, --absolute-paths   recreating the entire path structure from '/' in the";
		echo "                          created archive. See examples below for more details.";
		echo "";
		echo "   -M, --minimal-paths    Similar to --trim-paths but changes the behavior to";
		echo "                          start *under* the passed target/source paths meaning"
		echo "                          the passed folder's contents are included but not the";
		echo "                          passed folder itself. When used for archiving a file,";
		echo "                          path --trim-paths. In some cases, this can be similar";
		echo "                          to using --trim-paths with 'somedir/*' to archive the";
		echo "                          contents without the folder itself. See examples below";
		echo "                          for more details.";
		echo "";
		echo "   -W, --working-dir      Similar to --trim-paths but changes the behavior to";
		echo "                          be relative to the current/working directory, rather";
		echo "                          than relative to the passed source files. See examples";
		echo "                          below for more details.";
		echo "";
		echo "EXAMPLES:";
		echo "The --trim-paths is basically an option to prefer relative paths whenever possible."
		echo "In situations, where completely unrelated paths are archived, there will be no";
		echo "difference between using -trim-paths or --explicit-paths.";
		echo ""
		echo "However, unlike with most relative and absolute paths, --trim-paths is slightly"
		echo "more aggressive. If all paths being archived contain the same"
		echo ""
		echo "  cd /tmp";
		echo "  ${fnName} --xz --explicit-paths /etc/samba/smb.conf /usr/share/nemo/actions";
		echo "  ${fnName} --xz --trim-paths /etc/samba/smb.conf /usr/share/nemo/actions";
		echo "  ${fnName} --xz --working-dir /etc/samba/smb.conf /usr/share/nemo/actions";
		echo "  -> in all 3 cases:"
		echo "  -> new archive created at /tmp/smb.conf.\$(date +'%Y-%m-%d@%H%M%S').tar.xz";
		echo "  -> inside of the archive, the first folders are etc and usr with files at";
		echo "     ./etc/samba/smb.conf and ./usr/share/nemo/actions/*";
		echo "";
		echo "  cd ~";
		echo "  ${fnName} --xz --trim-paths ~/.mozilla/firefox/Crash\\ Reports/* -o crashes.tar.xz";
		echo "  -> new archive created at ~/crashes.tar.xz";
		echo "  -> inside of the archive, the first folder is Crash\\ Reports";
		echo "";
		echo "  cd ~";
		echo "  ${fnName} --xz --minimal-paths ~/.mozilla/firefox/Crash\\ Reports/* -o crashes.tar.xz";
		echo "  -> new archive created at ~/crashes.tar.xz";
		echo "  -> inside of the archive, the root of the archive has NO .mozilla ";
		echo "  -> or firefox or Crash\\ Reports. Instead it has the *contents* of";
		echo "  -> the original Crash\\ Reports folder immediately in the root of the archive.";
		cho "";
		echo "  cd ~";
		echo "  ${fnName} --xz --working-dir ~/.mozilla/firefox/Crash\\ Reports/* -o crashes.tar.xz";
		echo "  -> new archive created at ~/crashes.tar.xz";
		echo "  -> inside of the archive, the first folder is .mozilla since that was";
		echo "  -> the folder immediately relative to the working dir when it was run.";
		echo "  -> and Crash\\ Reports is located at ./.mozilla/firefox/\\Crash Reports";
		echo "";
		echo "  cd ~";
		echo "  ${fnName} --xz --explicit-paths ~/.mozilla/firefox/Crash\\ Reports/* -o crashes.tar.xz";
		echo "  -> new archive created at ~/crashes.tar.xz";
		echo "  -> inside of the archive, the first folder is home";
		echo "  -> and ~/Crash\\ Reports is located at ./home/$USER/.mozilla/firefox/Crash Reports";
		echo "";
		echo "------------------------------------------------------------------------";
		echo "Alternately, you can manually create the archive using:";
		echo "";
		echo "  # if relative paths inside archive are desired, first change to parent dir";
		echo "  cd PARENT_OF_TARGET_DIR";
		echo "";
		echo "  # then use one of the following depending on desired output format:";
		echo "  XZ_OPT=-${compressionLevel}e tar --create --xz --preserve-permissions --file=\"ARCHIVE.tar.xz\" \"PATH1\" [\"PATH2\" ...]";
		echo "  GZIP_OPT=-${compressionLevel} tar --create --gzip --preserve-permissions --file=\"ARCHIVE.tar.gz\" \"PATH1\" [\"PATH2\" ...]";
		echo "  BZIP2=-${compressionLevel} tar --create --bzip2 --preserve-permissions --file=\"ARCHIVE.tar.bz2\" \"PATH1\" [\"PATH2\" ...]";
		echo "";
		return -1;
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo ""
		echo "archivePath (initial):      '${archivePath}'";
		echo "compressionLevel:           '${compressionLevel}'";
		echo "outputFileExt:              '${outputFileExt}'";
		echo "isValidShortSuffix:         '${isValidShortSuffix}'";
		echo "avoidPackagingParentDirs:   '${avoidPackagingParentDirs}'";
	fi

	local compressionFlag="";
	case "${outputFileExt##*.}" in
		bz2) compressionFlag="--bzip2"; export BZIP2=-${compressionLevel}q; ;; # -q = quiet
		gz) compressionFlag="--gzip"; export GZIP_OPT=-${compressionLevel}q; ;;  # -q = quiet
		xz) compressionFlag="--xz"; export XZ_OPT=-${compressionLevel}eq; ;; # -e = slower, better compression
		lzo) compressionFlag="--lzop"; export LZOP=-${compressionLevel}; ;;
		lz) compressionFlag="--lzip"; export LZIP=-${compressionLevel}q; ;; # -q = quiet
		zst) compressionFlag="--zstd"; export ZSTD_CLEVEL=${compressionLevel}; ;;
		lzma)
			# on most modern linux systems, --lzma calls to lzma util
			# which will by symlinked to the newer xz binary so XZ_OPT
			# should still work
			compressionFlag="--lzma"; export XZ_OPT=-${compressionLevel}e;
			;;
		zip)
			if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
				export ZIPOPT=-${compressionLevel}v; # -v = verbose
			else
				export ZIPOPT=-${compressionLevel}q; # -q = quiet
			fi
			;;

		zpaq)
			# zpaq only has 5 levels rather than 9 (see man zpaq)
			if [[ ${compressionLevel} -gt 5 ]]; then
				compressionLevel=5;
			fi
			;;

		# some utilities such as tar.Z/compress (ncompress) don't support compression levels at all
		*) compressionFlag="" ;;
	esac

	# update to use actual extension name when generating filename template
	if [[ 1 != ${useLongTarExtsForAutoNaming} ]]; then
		case "${outputFileExt##*.}" in
			bz2) outputFileExt='tbz'; ;;
			gz) outputFileExt='tgz'; ;;
			xz) outputFileExt='txz'; ;;
			lzma) outputFileExt='tlz'; ;;
		esac
	fi

	if [[ "" != "${archivePath}" ]]; then
		# Using substitution doesn't work well for all scenarios here
		#	${archivePath#*.} / ${archivePath%%.*} => correctly handles foo.tar.gz but not my.foo.tar.gz
		#	${archivePath##*.} / ${archivePath%.*} => correctly handles foo.tar but not foo.tar.gz
		# Therefore a comprehensive approach is required so safe handle all possibilities ...
		local passedFileExt="${archivePath##*.}";
		local passedFileName="${archivePath%.*}";

		# this is just for preparing a search pattern to correctly match whatever
		# extension the passed archive name happens to have
		# the replacement value comes after this IF block and should just be outputFileExt
		if [[ $passedFileExt =~ ^[7bgx]z$ && $passedFileName =~ ^.*\.tar$ ]]; then
			passedFileExt="tar.${passedFileExt}";
			passedFileName="${passedFileName:0:${#passedFileName}-4}";
		fi

		# Now check if the passed extension is the same as the expected output extension and if not, then fix it
		if [[ 1 != ${isValidShortSuffix} && "${outputFileExt}" != "${passedFileExt}" ]]; then
			archivePath="${passedFileName}.${outputFileExt}";
			echo "W: Wrong archive extension '${passedFileExt}' passed; corrected to '${archivePath}' ..."|grep --color -E "${outputFileExt}";
		fi

		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "archivePath (by file):      '${archivePath}'";
			echo "passedFileExt:              '${passedFileExt}'";
			echo "passedFileName:             '${passedFileName}'";
		fi
	fi

	#echo "test: ${archivePath:${#archivePath}-${#outputFileExt}-1}"
	if [[ "" == "${archivePath}" || ( 1 != ${isValidShortSuffix} && \
			".${outputFileExt}" != "${archivePath:${#archivePath}-${#outputFileExt}-1}" ) \
		]]; then

		local firstTargetPath="${aryPassedPaths[0]}";

		if [[ 1 == ${useTimestampForAutoNaming} ]]; then
			local datestr=$(date +"%Y-%m-%d@%H%M%S");
			archivePath="${firstTargetPath}.${datestr}.${outputFileExt}";
		else
			archivePath="${firstTargetPath}.${outputFileExt}";
		fi

		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "archivePath (fallback):      '${archivePath}'";
		fi
	fi
	local absoluteArchivePath="$(realpath "${archivePath}")";

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "archivePath (final):        '${archivePath}'";
		echo "compressionFlag:            '${compressionFlag}'";
	fi

	local changedToCommonParent=0;
	if [[ 'relative' == "${folderMode}" || 'minimal' == "${folderMode}" ]]; then
		if [[ '' != "${commonTargetParent}" && '/' != "${commonTargetParent}" && -d "${commonTargetParent}" ]]; then
			cd "${commonTargetParent}";
			changedToCommonParent=1;
		fi
	fi

	local useWildcardInWorkingDir=0;
	if [[ 1 == ${changedToCommonParent} && 'absolute' != "${folderMode}" && "${#aryPassedPaths[@]}" -eq 1 && '' == "${aryPassedPaths[@]}" ]]; then
		useWildcardInWorkingDir=1;
	fi

	echo ""

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "Processing ${outputFileExt} target"
		echo "==============================================================="
	fi
	local startTime="$(date +'%Y-%m-%d @ %H:%M:%S')";
	if [[ 1 != ${supressOutput} || 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "Starting compression at: ${startTime}";
	fi

	[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Running command:"

	local returnCode=0;
	if [[ '7z' == "${outputFileExt}" ]]; then
		if [[ 1 == ${useWildcardInWorkingDir} ]]; then
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "7z a -t7z -m0=lzma2 -mx=${compressionLevel} -md=32m -ms=on \"${absoluteArchivePath}\" ./*"
			7z a -t7z -m0=lzma2 -mx=${compressionLevel} -md=32m -ms=on "${absoluteArchivePath}" ./* | eatStdOutputIfNotDebug;
		else
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "7z a -t7z -m0=lzma2 -mx=${compressionLevel} -md=32m -ms=on \"${absoluteArchivePath}\" \"${aryPassedPaths[@]}\""
			7z a -t7z -m0=lzma2 -mx=${compressionLevel} -md=32m -ms=on "${absoluteArchivePath}" "${aryPassedPaths[@]}" | eatStdOutputIfNotDebug;
		fi
		returnCode="$?";

	elif [[ 'zip' == "${outputFileExt}" ]]; then
		if [[ 1 == ${useWildcardInWorkingDir} ]]; then
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "zip -${compressionLevel} --recurse-paths --system-hidden --symlinks \"${absoluteArchivePath}\" ./*"
			zip -${compressionLevel} --recurse-paths --system-hidden --symlinks "${absoluteArchivePath}" ./* | eatStdOutput;
		else
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "zip -${compressionLevel} --recurse-paths --system-hidden --symlinks \"${absoluteArchivePath}\" \"${aryPassedPaths[@]}\""
			zip -${compressionLevel} --recurse-paths --system-hidden --symlinks "${absoluteArchivePath}" "${aryPassedPaths[@]}" | eatStdOutput;
		fi
		returnCode="$?";

	elif [[ 'zpaq' == "${outputFileExt}" ]]; then
		if [[ 1 == ${useWildcardInWorkingDir} ]]; then
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "zpaq a \"${absoluteArchivePath}\" ./* -m${compressionLevel}"
			zpaq a "${absoluteArchivePath}" ./* -m${compressionLevel} | eatStdOutput;
		else
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "zpaq a \"${absoluteArchivePath}\" \"${aryPassedPaths[@]}\" -m${compressionLevel}"
			zpaq a "${absoluteArchivePath}" "${aryPassedPaths[@]}" -m${compressionLevel} | eatStdOutput;
		fi
		returnCode="$?";

	elif [[ ${outputFileExt} =~ ^tar.*$ || ${outputFileExt} =~ ^t[bgx]z$ ]]; then
		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			compressionFlag="--verbose ${compressionFlag}";
			case "${outputFileExt##*.}" in
				tbz) : ;&
				bz2) echo "export BZIP2=\"${BZIP2}\""; ;;

				tgz) : ;&
				gz) echo "export GZIP_OPT=\"${GZIP_OPT}\""; ;;

				txz) : ;&
				tlz) : ;&
				lzma) : ;&
				xz) echo "export XZ_OPT=\"${XZ_OPT}\""; ;;

				zip) echo "export ZIPOPT=\"${ZIPOPT}\""; ;;
				lzo) echo "export LZOP=\"${LZOP}\""; ;;
				lz) echo "export LZIP=\"${LZIP}\""; ;;
				zst) echo "export ZSTD_CLEVEL=\"${ZSTD_CLEVEL}\""; ;;
			esac
		fi

		#
		# -C, --directory=DIR                               Change to DIR before performing any operations. This option is
		#                                                   order-sensitive, i.e. it affects all options that follow.
		#
		# 		-> possibly useful when using tar directly but tar's behavior is a bit annoying otherwise and
		#			since we're already handle paths for consistency; leave this out (if used it would force
		#			all passed paths to be relative as well ... which is more work)
		#
		# -c, --create                                      Create a new archive. Directoties are archived recursively
		# -p, --preserve-permissions, --same-permissions    Extract  information  about  file permissions (default for superuser)
		# --preserve                                        Same as both -p and -s.
		# -s, --preserve-order, --same-order                Sort names to extract to match archive
		# -f, --file=ARCHIVE                                Archive to create / extract from
		# --acls                                            Enable POSIX ACLs support.
		# --selinux                                         Enable SELinux context support.
		# --xattrs                                          Enable extended attributes support.
		# -M, --multi-volume                                Create/list/extract multi-volume archive.
		# -L, --tape-length=N                               Change  tape  after writing Nx1024 bytes. If N is followed by a
		#                                                   size suffix (see the subsection Size suffixes below), the suffix
		#                                                   specifies the multiplicative factor to be used instead of 1024.
		#                                                   This option implies -M.
		#
		# -j, --bzip2                                       Filter the archive through bzip2(1).
		# -J, --xz                                          Filter the archive through xz(1).
		# --lzip                                            Filter the archive through lzip(1).
		# --lzma                                            Filter the archive through lzma(1).
		# --lzop                                            Filter the archive through lzop(1).
		# -z, --gzip, --gunzip, --ungzip                    Filter the archive through gzip(1).
		# -Z, --compress, --uncompress                      Filter the archive through compress(1).
		# --zstd                                            Filter the archive through zstd(1).
		#
		# --add-file=FILE                                   Add FILE to the archive (useful if its name starts with a dash).
		# -h, --dereference                                 Follow symlinks; archive and dump the files they point to.
		# --hard-dereference                                Follow hard links; archive and dump the files they refer to.
		# --recursion                                       Recurse into directories (default).
		#
		if [[ 1 == ${useWildcardInWorkingDir} ]]; then
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "tar --create ${compressionFlag} --preserve-permissions --file=\"${absoluteArchivePath}\" ./*"
			tar --create ${compressionFlag} --preserve-permissions --file="${absoluteArchivePath}" ./* |eatStdOutput;
		else
			[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "tar --create ${compressionFlag} --preserve-permissions --file=\"${absoluteArchivePath}\" \"${aryPassedPaths[@]}\""
			tar --create ${compressionFlag} --preserve-permissions --file="${absoluteArchivePath}" "${aryPassedPaths[@]}" |eatStdOutput;
		fi
		returnCode="$?";
	else
		echo "E: No implementation for ${outputFileExt} archives.";
	fi
	if [[ 1 != ${supressOutput} || 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		local endTime="$(date +'%Y-%m-%d @ %H:%M:%S')";
		if [[ 0 == ${returnCode} ]]; then
			echo "Compression completed at: ${endTime}";
		else
			echo "Compression failed at: ${endTime}";
		fi
		getTimeDifference -q "${startTime}" "${endTime}" '%Y-%m-%d @ %H:%M:%S' "time elapsed: %_H h %_M m %_S s" 2>/dev/null;
	fi

	if [[ "$PWD" != "${startingDir}" ]]; then
		cd "${startingDir}";
	fi
	return ${returnCode};
}
function create7zArchive() {
	echo "=============================================================================="
	echo 'Note: The 7z format does not perserve Linux file permissions.';
	echo 'If this is desired, it is recommended to use the tar.xz format instead as';
	echo 'it also uses LZMA2 compression but is able to perserve existing permissions.';
	echo "=============================================================================="
	echo '';

	# use compression level 9 (slowest but best compression)
	createArchive --7z -9 "${@}";
}
function createZpaqArchive() {
	echo "=============================================================================="
	echo 'Note: The zpaq format does not perserve Linux file permissions.';
	echo 'If this is desired, it is recommended to use the tar.xz format instead as';
	echo 'it uses LZMA2 compression but is able to perserve existing permissions.';
	echo "=============================================================================="
	echo '';

	# use compression level 5 (slowest but best compression)
	# note: in zpaq, the max compression level is 5 as opposed to 9
	# as is used in many other compression programs
	createArchive --zpaq -5 "${@}";
}
function createTarArchive() {
	# wrapper for handling old function name
	createArchive "${@}";
}
function createUncompressedTarArchive() {
	# use compression level 3 (faster)
	createArchive --tar "${@}";
}
function createTarGzArchive() {
	echo "Note: The gz format is an older format with a worse compression ratio.";
	echo "It is recommended to use tar.xz if possible.";
	echo "";
	createArchive --gz -9 "${@}";
}
function createTarXzArchive() {
	# this should default to compression level 9 (slowest but best compression)
	createArchive --xz -9 "${@}";
}
function createTarXzArchive9() {
	# use compression level 9 (slowest but best compression)
	createArchive --xz -9 "${@}";
}
function createTarXzArchive6() {
	# use compression level 6 (default)
	createArchive --xz -6 "${@}";
}
function createTarXzArchive3() {
	# use compression level 3 (faster)
	createArchive --xz -3 "${@}";
}
function createTarBzArchive() {
	echo "Note: The bzip2 format is an older format with a worse compression ratio.";
	echo "It is recommended to use tar.xz if possible.";
	echo "";
	createArchive --bzip2 -9 "${@}";
}
function createZipArchive() {
	echo "Note: The zip format is an older format with a worse compression ratio.";
	echo "It is recommended to use tar.xz if possible.";
	echo "";
	createArchive --zip -9 "${@}";
}
function extractArchive() {
	local fnName="extractArchive";
	local displayHelp=0;
	local archivePath="$1";

	# if no args or explicitly passing help arguments
	if [[ "" == "${archivePath}" ]]; then
		echo "E: ${fnName}: No passed arguments";
		displayHelp=1;

	elif [[ "-h" == "${archivePath}" || ${archivePath} =~ ^\-\-*help$ ]]; then
		displayHelp=1;

	elif [[ ! -f "${archivePath}" ]]; then
		echo "E: Archive '$archivePath' not found";
		displayHelp=1;

	elif [[ ! ( $archivePath =~ ^.*\.tar(\.([bglx]z|Z|lzo|lzma|zst|bz2))?$ || \
				$archivePath =~ ^.*\.(7z|zip|zpaq)?$ ) ]]; then
		echo "E: Invalid archive format";
		displayHelp=1;
	fi

	if [[ 1 == ${displayHelp} ]]; then
		echo "";
		echo "Expected usage:";
		echo "  ${fnName} /path/to/archive [/path/to/new/extract.to]";
		echo "";
		echo "If the path to the new extraction folder is not provided then.";
		echo "function will extract to the current directory.";
		echo "";
		return -1;
	fi

	local extractWith='';
	if [[ $archivePath =~ ^.*\.tar(\.([bglx]z|Z|lzo|lzma|zst|bz2))?$ ]]; then
		extractWith='tar';

	elif [[ $archivePath =~ ^.*\.7z$ ]]; then
		extractWith='7z';

	elif [[ $archivePath =~ ^.*\.zip$ ]]; then
		extractWith='unzip';

	elif [[ $archivePath =~ ^.*\.zpaq$ ]]; then
		extractWith='zpaq';

	else
		echo "E: ${fnName}: unknown format:";
		return -1;
	fi

	# get the archive name and path without file extensions
	local archiveParentDir="$(dirname "${archivePath}")";
	local archiveFileName="$(basename "${archivePath}")";
	local archiveFileNameNoExt="${archiveFileName%.*}";
	if [[ $archiveFileNameNoExt =~ ^.*\.tar$ ]]; then
		archiveFileNameNoExt="${archiveFileNameNoExt%.*}";
	fi

	# get the last arg as archive path
	local destinationDirPath="$2";
	if [[ '' == "${destinationDirPath}" ]]; then
		destinationDirPath="${archiveParentDir}/${archiveFileNameNoExt}";
		echo "W: ${fnName}: output dir not set. Defaulting to '${destinationDirPath}'";

	elif [[ -f "${destinationDirPath}" ]]; then
		echo "E: Can only extract to a folder. The path '${destinationDirPath}' is a file. ";
		return -1;
	fi

	# make sure output folder exists
	if [[ ! -e "${destinationDirPath}" ]]; then
		mkdir -p "${destinationDirPath}";
	fi

	local startTime="$(date +'%Y-%m-%d @ %H:%M:%S')";
	if [[ 1 != ${supressOutput} || 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "Starting extract at: ${startTime}";
	fi
	[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "Running command:"

	local returnCode=0;
	if [[ 'tar' == "${extractWith}" ]]; then
		# check if the archive contains a folder with the same name as the archive file
		# if so then adjust our destination path to avoid having double container folders
		#	https://www.linux.org/threads/list-tar-contents-only-first-level-then-subdirectory-extract.10491/
		local hasInnerContainerDir="$(tar --list --no-recursion --file="${archivePath}" "${archiveFileNameNoExt}/" 2>/dev/null|wc -l)";
		local hasOtherRootFiles="$(tar --list --file="${archiveFileName}" 2>/dev/null|grep -Pvc "^${archiveFileNameNoExt}/")";

		local tarOptions='';
		if [[ 1 == ${hasInnerContainerDir} && 0 == ${hasOtherRootFiles} ]]; then
			#https://serverfault.com/questions/330127/tar-remove-leading-directory-components-on-extraction
			tarOptions='--strip-components=1'
		fi

		# https://linuxize.com/post/how-to-extract-unzip-tar-xz-file/

		# FROM man tar:
		#	-x, --extract, --get
		#		Extract files from an archive.  Arguments are optional.  When given, they specify  names
		#		of the archive members to be extracted.
		#
		#	-v, --verbose
		#		Verbosely list files processed.
		#
		#	-p, --preserve-permissions, --same-permissions
		#		extract information about file permissions (default for superuser)
		#
		#	--preserve
		#		Same as both -p and -s.
		#
		#	--same-owner
		#		Try extracting files with the same ownership as exists in the archive (default for supe‐
		#		ruser).
		#
		#	-s, --preserve-order, --same-order
		#		Sort names to extract to match archive
		#
		#	-f, --file=ARCHIVE
		#		Use archive file or device ARCHIVE.  [...]  If it is set, its value will be used  as  the  archive
		#		name. [...]
		#
		#	-C, --directory=DIR
		#		Change to DIR before performing any operations.  This option is order-sensitive, i.e. it
		#		affects all options that follow.
		#
		[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "tar --extract --file=\"${archivePath}\" --directory=\"${destinationDirPath}\" ${tarOptions}"
		tar --extract --file="${archivePath}" --directory="${destinationDirPath}" ${tarOptions}|eatStdOutputIfNotDebug;
		returnCode="$?";

	elif [[ '7z' == "${extractWith}" ]]; then
		echo "W: ${fnName}: ${extractWith} - EXPERIMENTAL";
		[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "7za x -o\"${destinationDirPath}\" \"${archivePath}\""
		7za x -o"${destinationDirPath}" "${archivePath}"|eatStdOutputIfNotDebug;
		returnCode="$?";

	elif [[ 'unzip' == "${extractWith}" ]]; then
		echo "W: ${fnName}: ${extractWith} - EXPERIMENTAL";
		[[ 1 == $DEBUG_BASH_FUNCTIONS ]] && echo "unzip \"${archivePath}\" -d\"${destinationDirPath}\""
		unzip "${archivePath}" -d"${destinationDirPath}"
		returnCode="$?";

	elif [[ 'zpaq' == "${extractWith}" ]]; then
		echo "E: ${fnName}: ${extractWith} NOT YET IMPLEMENTED.";
		return -1;
	else
		echo "E: ${fnName}: unknown format:";
		return -1;
	fi
	if [[ 1 != ${supressOutput} || 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		local endTime="$(date +'%Y-%m-%d @ %H:%M:%S')";
		if [[ 0 == ${returnCode} ]]; then
			echo "Extraction completed at: ${endTime}";
		else
			echo "Extraction failed at: ${endTime}";
		fi
		getTimeDifference -q "${startTime}" "${endTime}" '%Y-%m-%d @ %H:%M:%S' "time elapsed: %_H h %_M m %_S s" 2>/dev/null;
	fi
	return ${returnCode};
}
function extractTarArchive() {
	extractArchive "${@}";
}
function extract7zArchive() {
	extractArchive "${@}";
}
function extractZipArchive() {
	extractArchive "${@}";
}
function extractZpaqArchive() {
	extractArchive "${@}";
}
function extractExeAsArchive() {
	# https://wiki.archlinux.org/index.php/Nonfree_applications_package_guidelines#Unpacking
	local showHelp=0
	local exeFilePath='';
	# mutually-exclusive options
	if [[ '' == "$1" || '-h' == "$1" || '--help' == "$1" ]]; then
		showHelp=1;

	elif [[ '.exe' != "$(echo "${1: -4}"|tr '[:upper:]' '[:lower:]')" ]]; then
		showHelp=1;
		echo "E: extractExeAsArchive: '$1' is not an exe; expected a valid exe file.";
		echo "";

	elif [[ ! -f "$1" ]]; then
		showHelp=1;
		echo "E: extractExeAsArchive: '$1' does not exist; expected a valid exe file.";
		echo "";

	elif [[ ! -s "$1" ]]; then
		showHelp=1;
		echo "E: extractExeAsArchive: '$1' is an empty file; expected a valid exe file.";
		echo "";
	fi

	if [[ '1' == "${showHelp}" ]]; then
		echo "Expected usage:";
		echo "   extractExeAsArchive: /path/to/somefile.exe [/path/to/extract/to]";
		echo "";
		echo "If the output dir is not specified, it will be either ";
		echo "the name of the exe file minus the extension, or if that path";
		echo "already exists then it will be a similar path with timestamp.";
		echo "";
		echo "e.g.";
		echo "   # /tmp/foo/bar does not exist:";
		echo "   extractExeAsArchive /tmp/foo/bar.exe";
		echo "   -> contents will be extracted to /tmp/foo/bar";
		echo "";
		echo "   # /tmp/foo/bar already exists:";
		echo "   extractExeAsArchive /tmp/foo/bar.exe";
		echo "   -> contents will be extracted to /tmp/foo/bar-2021-01-01-151920";
		echo "";
		return -1;
	fi
	local requiredPackages='p7zip exiftool innoextract'
	if [[ '' == "$(which $WHICH_OPTS 7za 2>/dev/null)" || '' == "$(which $WHICH_OPTS exiftool 2>/dev/null)" || '' == "$(which $WHICH_OPTS innoextract 2>/dev/null)" ]]; then
		echo "E: extractExeAsArchive: Missing required packages.";
		local installCommand='';
		if [[ -f /usr/bin/dnf ]]; then
			installCommand="Please run: sudo dnf install -y ${requiredPackages}";
		elif [[ -f /usr/bin/apt-get ]]; then
			installCommand="Please run: sudo apt-get install -y ${requiredPackages}";
		else
			installCommand="Please install the following packages: ${requiredPackages}";
		fi
		return -2;
	fi

	local exeFilePath="$(realpath "${1}")";
	local outputDirPath="$2";
	if [[ ! -z "${outputDirPath}" ]]; then
		outputDirPath="$(realpath "${2}")";
	else
		outputDirPath="${exeFilePath:0: -4}";
	fi

	if [[ -e "${outputDirPath}" ]]; then
		outputDirPath="${outputDirPath}-$(date +'%Y-%m-%d-%H%M%S')";
	fi
	local isInnoSetupExe=0;
	if [[ '0' != "$(exiftool "${exeFilePath}" 2>/dev/null|grep -Pci '\bInno\b')" ]]; then
		isInnoSetupExe=1;
	fi
	echo "exeFilePath: ${exeFilePath}";
	echo "outputDirPath: ${outputDirPath}";
	echo "isInnoSetupExe: ${isInnoSetupExe}";

	if [[ '1' == "${isInnoSetupExe}" ]]; then
		local isGogInstaller=0;
		if [[ '0' != "$(exiftool "${exeFilePath}" 2>/dev/null|grep -Pci '\bGOG\b')" ]]; then
			isGogInstaller=1;
		fi

		if [[ '1' == "${isGogInstaller}" ]]; then
			innoextract "${exeFilePath}" -g -d "${outputDirPath}"
		else
			innoextract "${exeFilePath}" -d "${outputDirPath}"
		fi
		return $?;
	fi

	# TODO - handle other use-cases such as self-extracting archives, etc
	echo "";
	echo "Attempting poorly tested functionality using 7za ..."
	echo "Running: 7za x -o\"${outputDirPath}\" \"${exeFilePath}\""
	7za x -o"${outputDirPath}" "${exeFilePath}" 2>/dev/null;
	local exitCode="$?";
	echo "7za exit code: $exitCode"
	if [[ 0 != $exitCode ]]; then
		echo "Try the following commands for more info:";
		echo "  file \"${exeFilePath}\"";
		echo "  exiftool \"${exeFilePath}\"";
	fi
}
function changeDir() {
	if [[ '' == "$1" ]]; then
		return;
	fi

	local previousPath="$OLDPWD";
	local currentPath="$(pwd)";

	# get the last value to avoid parameters that might have been passed to 'cd'
	local newPath="$(realpath --no-symlinks "${@:${#@}:1}")";
	if [[ 1 == ${BASH_DEBUG_CD_FUNC} ]]; then
		echo "==============================================================="
		echo "changeDir(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo ""
		echo "previousPath (OLDPWD):     '${previousPath}'"
		echo "currentPath (PWD before):    '${currentPath}'"
		echo "newPath:                    '${newPath}'"
	fi
	# avoid aliases by using keyword builtin
	builtin cd "${@}"
	local rc="$?";
	local newPwd="$(pwd)";
	if [[ 1 == ${BASH_DEBUG_CD_FUNC} ]]; then
		echo "rc:                         '${rc}'";
		echo "newPwd:                     '${newPwd}'";
		echo "";
	fi

	if [[ '0' == "${rc}" && "${currentPath}" != "${newPwd}" ]]; then


		# approach:
		#	1. out all OLDPWD[0-9] into an array
		# 	2. Loop through array
		#		if previous stored OLDPWD value exists, ignore
		#		else shift array and add value to array
		#	3. set OLDPWD[0-9] values from array
		local aryOldPathsList=(  );

		# don't compare #9 - since that's what would be replaced anyway, this allows it to change positions
		#aryOldPathsList+=("OLDPWD9");
		aryOldPathsList+=("OLDPWD8");
		aryOldPathsList+=("OLDPWD7");
		aryOldPathsList+=("OLDPWD6");
		aryOldPathsList+=("OLDPWD5");
		aryOldPathsList+=("OLDPWD4");
		aryOldPathsList+=("OLDPWD3");
		aryOldPathsList+=("OLDPWD2");
		aryOldPathsList+=("OLDPWD1");
		aryOldPathsList+=("OLDPWD0");

		local pathExists=0;
		for path in $(echo "${aryOldPathsList[@]}"); do
			if [[ "${newPwd}" == "${path}" ]]; then
				pathExists=1;
				break;
			fi
		done

		if [[ 0 == ${pathExists} ]]; then
			OLDPWD9="$OLDPWD8";
			OLDPWD8="$OLDPWD7";
			OLDPWD7="$OLDPWD6";
			OLDPWD6="$OLDPWD5";
			OLDPWD5="$OLDPWD4";
			OLDPWD4="$OLDPWD3";
			OLDPWD3="$OLDPWD2";
			OLDPWD2="$OLDPWD1";
			OLDPWD1="$OLDPWD0";
			OLDPWD0="$previousPath";

			if [[ 1 == ${BASH_DEBUG_CD_FUNC} ]]; then
				echo ""
				echo "==============================================================="
				echo "OLDPWD0:                    '${OLDPWD0}'"
				echo "OLDPWD1:                    '${OLDPWD1}'"
				echo "OLDPWD2:                    '${OLDPWD2}'"
				echo "OLDPWD3:                    '${OLDPWD3}'"
				echo "OLDPWD4:                    '${OLDPWD4}'"
				echo "OLDPWD5:                    '${OLDPWD5}'"
				echo "OLDPWD6:                    '${OLDPWD6}'"
				echo "OLDPWD7:                    '${OLDPWD7}'"
				echo "OLDPWD8:                    '${OLDPWD8}'"
				echo "OLDPWD9:                    '${OLDPWD9}'"
				echo ""
			fi

		elif [[ 1 == ${BASH_DEBUG_CD_FUNC} ]]; then
			echo "W: Path already stored; skipping...";
			return;
		fi
	elif [[ 1 == ${BASH_DEBUG_CD_FUNC} ]]; then
		if [[ "${currentPath}" == "${newPwd}" ]]; then
			echo "W: No path changel skipping...";
		else
			echo "E: Failed to cd to '$@'. Return code: ${rc}";
		fi
	fi
}
function makeThenChangeDir() {
	local NEW_DIR="$1";
	mkdir -p "${NEW_DIR}";
	changeDir "${NEW_DIR}";
}
function makeNewDirBasedOnExistingDir() {
	local fnName="makeNewDirBasedOnExistingDir";
	local dirToCreate="";
	local existingDir="";
	local showUsage="false";
	local showError="false";
	local parentOfNewDir="";
	local status=0;
	local isRecursed="false";

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "makeNewDirBasedOnExistingDir(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo ""
		echo "makeNewDirBasedOnExistingDir ${@}"
	fi

	# baseParentsOn must be either:
	#	"existingChild"   - base new parent dirs off existing child dir
	#	e.g. /my/new/dir => my, new, dir all have same
	#	 perms/owners as as /home/myuser/existingdir
	#	 even if /home or /home/myuser have different perms/owners
	#
	#	"existingParents" - base new parent dirs off existing parent dirs
	#	e.g. /my/new/dir => /my has same owner/perms as /home,
	#		 /my/new has same owner/perms as /home/myuser,
	#		 /my/new/dir same owner/perms as /home/myuser/existingdir
	#
	local baseParentsOn="existingParents";

	for passedarg in "$@"; do
		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "passedarg is $passedarg"
		fi

		# mutually-exclusive options
		if [[ "" == "${passedarg}" ]]; then
			continue;

		elif [[ "-h" == "${passedarg}" || "--help" == "${passedarg}" ]]; then
			showUsage="true";
			continue;

		elif [[ "-C" == "${passedarg}" || "--use-existing-child" == "${passedarg}" ]]; then
			baseParentsOn="existingChild";
			continue;

		elif [[ "-P" == "${passedarg}" || "--use-existing-hier" == "${passedarg}" || "--use-existing-hierarchy" == "${passedarg}" ]]; then
			baseParentsOn="existingParents";
			continue;

		elif [[ "--recursion-flag=true" == "${passedarg}" ]]; then
			isRecursed="true";
			continue;
		fi

		if [[ $passedarg =~ ^[\.~]*\/.*$ || $passedarg =~ ^[^/\n\r]*$ ]]; then
			# If path starts with ~, then expand to $HOME
			if [[ $passedarg =~ ^~\/.*$ ]]; then
				passedarg="${HOME}${passedarg:1}";
			fi

			# if path contains a trailing space, then strip it out
			if [[ $passedarg =~ ^.*\/$ ]]; then
				passedarg="${passedarg:0:${#passedarg}-1}";
			fi

			# convert any relative paths to absolute
			# not strictly necessary in all scenarios
			# but it greatly simplifies error handling
			if [[ $passedarg =~ ^\.\/.*$ ]]; then
				passedarg="$(pwd)${passedarg:1}";

			elif [[ $passedarg =~ ^[^/\n\r]*$ ]]; then
				passedarg="$(pwd)/${passedarg}";
			fi

			# check if it exists or not and set appropriate var
			if [[ -d "${passedarg}" ]]; then
				if [[ "" == "${existingDir}" ]]; then
					existingDir="${passedarg}";
					if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
						echo "Found existing dir as '${existingDir}' ";
					fi
				else
					if [[ "false" == "${isRecursed}" || 1 == $DEBUG_BASH_FUNCTIONS ]]; then
						echo "E: Found 2nd existing dir '${passedarg}' ";
					fi
					showUsage="true";
					status=501;
				fi
			else
				if [[ "" == "${dirToCreate}" ]]; then
					dirToCreate="${passedarg}";
					if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
						echo "Found dir to create as '${dirToCreate}' ";
					fi
				else
					if [[ "false" == "${isRecursed}" || 1 == $DEBUG_BASH_FUNCTIONS ]]; then
						echo "E: Found 2nd non-existing dir '${passedarg}' ";
					fi
					showUsage="true";
					status=502;
				fi
			fi
			continue;
		fi
		echo "E: Found unrecognized argument '${passedarg}' ";
		showUsage="true";
		status=503;
	done

	if [[ "true" == "${showUsage}" ]]; then
		echo "";
		echo "Expected usage:";
		echo "   ${fnName} [options] EXISTING_DIR NEW_DIR";
		echo "or ${fnName} [options] NEW_DIR EXISTING_DIR";
		echo "";
		echo "Creates a new directory using an existing directory's ownership/permissions as a template for the new directory. The order of EXISTING_DIR/NEW_DIR is not important but this function REQUIRES that exactly ONE folder already exists and exactly ONE folder does not yet exist.";
		echo "";
		echo "If the folder being created also has one or more parent dirs that do not already exist, then the parents can either mirror the existing folder's parent hierarchy (-P or --use-existing-hierarchy) or can model all of the new parent folders after the existing child folder (-C or --use-existing-child).";
		echo "In the event of the new parents are to be based off the existing parent hierarchy (default); then the new and existing folders must be at the same folder depth from root or the function will fail with an error.";
		echo "";
		echo "==============================================";
		echo "";
		echo "EXISTING_DIR - A directory that already exists.";
		echo "NEW_DIR      - A directory that does not exist yet but will be created.";
		echo "";
		echo "-h, --help                   - Display this help page.";
		echo "-P, --use-existing-hierarchy - Permissions and ownership for new parent folders are based off the existing folder's parent folders at the same depth. Note that this requires both folders to be the same depth from root (/).";
		echo "                               This option is the default if neither -P or -C are specified.";
		echo "-C, --use-existing-child     - Permissions and ownership for new parent folders are based off the existing folder's path directly (e.g. the deepest node/child in the existing folder's path). Note that this option can be used with folders of different depths.";
		echo "";
		echo "==============================================";
		echo "EXAMPLES:";
		echo "  Suppose that you have the path /home/testuser/foo";
		echo "  that you would like to use as a pattern.";
		echo "";
		echo "  Assume perms/owner for the existing path are as follows:";
		echo "  drwxr-xr-x  root     root      /home";
		echo "  drwxr-xr-x  testuser testuser  /home/testuser";
		echo "  drwxrwx---  testuser sharedgrp /home/testuser/foo";
		echo "";
		echo "  # simple 1-level example";
		echo "  ${fnName} /home/testuser/foo /tmp/newfolder";
		echo "  => drwxrwx---  testuser sharedgrp /tmp/newfolder";
		echo "";
		echo "  # duplicate nested structure/perms/owners";
		echo "  ${fnName} -P /home/testuser/foo /home2/testuser/foo";
		echo "  => drwxr-xr-x  root     root     /home2";
		echo "  => drwxr-xr-x  testuser testuser /home2/testuser";
		echo "  => drwxrwx---  testuser sharedgrp /home2/testuser/foo";
		echo "";
		echo "  # duplicate nested structure but keep child perms/owners";
		echo "  ${fnName} -C /home/testuser/foo /home2/testuser/foo";
		echo "  => drwxrwx---  testuser sharedgrp /home2";
		echo "  => drwxrwx---  testuser sharedgrp /home2/testuser";
		echo "  => drwxrwx---  testuser sharedgrp /home2/testuser/foo";
		echo "";
		echo "  # BAD: Since the destination has a depth of 2 and the source";
		echo "  # has a depth of 3, the last two subdirs (testuser and foo)";
		echo "  # will be used for the permissions template. e.g.:"
		echo "  ${fnName} -P /home/testuser/foo /home2/foo";
		echo "  => drwxr-xr-x  testuser testuser  /home2";
		echo "  => drwxrwx---  testuser sharedgrp /home2/foo";
		echo "";
		echo "  # GOOD: To use the first and last dirs as permissions template:";
		echo "  ${fnName} -C /home /home2";
		echo "  => drwxr-xr-x  root     root     /home2";
		echo "  ${fnName} -C /home/testuser/foo /home2/foo";
		echo "  => drwxrwx---  testuser sharedgrp /home2/foo";
		echo "";
		echo "  # create the 3 new folders patterned off of 3 existing folders ";
		echo "  # under a different existing folder (/tmp)";
		echo "  ${fnName} -P /home/testuser/foo /tmp/home2/testuser/foo";
		echo "  => no change to /tmp, e.g:";
		echo "";
		echo "  => drwxr-xr-x  root     root      /tmp/home2";
		echo "  => drwxr-xr-x  testuser testuser  /tmp/home2/testuser";
		echo "  => drwxrwx---  testuser sharedgrp /tmp/home2/testuser/foo";
		echo "";
		return $status;
	fi

	#do additional validations
	if [[ "" == "${existingDir}" ]]; then
		echo "E: Missing EXISTING_DIR";
		showError="true";
		status=504;
	fi
	if [[ "" == "${dirToCreate}" ]]; then
		echo "E: Missing NEW_DIR";
		showError="true";
		status=505;
	fi
	if [[ "false" == "${showError}" ]]; then
		# get immediate parent of new dir
		parentOfNewDir=$(dirname "${dirToCreate}");
		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "parentOfNewDir: is $parentOfNewDir"
		fi

		# check if new parent already exists or not
		if [[ ! -d "${parentOfNewDir}" ]]; then
			if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
				echo "parentOfNewDir does not exist ..."
			fi

			# if parent doesn't exist, attempt to create it
			if [[ "existingChild" == "${baseParentsOn}" ]]; then
				# make recursive call to handle parent
				makeNewDirBasedOnExistingDir -C "${existingDir}" "${parentOfNewDir}";

			else
				# get immediate parent of existing dir
				local parentOfExistingDir=$(dirname "${existingDir}");
				local parentOfExistingSlashes="${parentOfExistingDir//[^\/]}";
				local parentOfNewDirSlashes="${parentOfNewDir//[^\/]}";

				if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
					echo "parentOfExistingDir: is $parentOfExistingDir"
					echo "parentOfExistingSlashes: is $parentOfExistingSlashes"
					echo "parentOfNewDirSlashes: is $parentOfNewDirSlashes"
					echo "length(parentOfExistingSlashes): is ${#parentOfExistingSlashes}"
					echo "length(parentOfNewDirSlashes): is ${#parentOfNewDirSlashes}"
				fi

				if (( ${#parentOfExistingSlashes} > ${#parentOfNewDirSlashes} )); then
					echo "E: Unable to duplicate nested folder permissions/owners due to different folder depths.";
					echo "Please check paths, resolve manually, or use the -C option."
					showError="true";
					status=508;
				else
					# make recursive call to handle parent
					makeNewDirBasedOnExistingDir -P "${parentOfExistingDir}" "${parentOfNewDir}";
				fi
			fi
			# end ${baseParentsOn} conditional handling

			# if we made a recursive call, confirm it was successful
			if [[ "false" == "${showUsage}" ]]; then
				local recursiveStatus="$?";
				if [[ "0" != "${recursiveStatus}" || ! -d "{parentOfNewDir}" ]]; then
					return ${recursiveStatus};
				fi
			fi
		fi
		# end [[ -d "${parentOfNewDir}" ]] conditional handling
	fi
	# end additional validations

	if [[ "false" == "${showError}" ]]; then
		if [[ ! -d "${existingDir}" ]]; then
			echo "E: Failed assertion: existing dir '${existingDir}' does not exist.";
			showError="true";
			status=515;
		elif [[ "" == "${parentOfNewDir}" ]]; then
			echo "E: Failed assertion: parent dir for '${dirToCreate}' not defined.";
			showError="true";
			status=516;
		elif [[ ! -d "${parentOfNewDir}" ]]; then
			echo "E: Failed assertion: parent dir for '${dirToCreate}' was not created.";
			showError="true";
			status=517;
		fi
	fi

	if [[ "true" == "${showError}" ]]; then
		echo "";
		echo "Expected usage:";
		echo "   ${fnName} [options] EXISTING_DIR NEW_DIR";
		echo "or ${fnName} [options] NEW_DIR EXISTING_DIR";
		echo "";
		echo "Run ${fnName} --help for more info.";
		echo "";
		return $status;
	fi

	local doSudo="";
	if [[ "root" != "${SUDO_USER:-$USER}" ]]; then
		if [[ ! -O "${existingDir}" ]]; then
			if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
				echo "existingDir '${existingDir}' not owned by '${SUDO_USER:-$USER}'; prompt for sudo ..."
			fi
			doSudo='sudo';
		elif [[ ! -w "${parentOfNewDir}" ]]; then
			if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
				echo "parentOfNewDir '${parentOfNewDir}' not writable by '${SUDO_USER:-$USER}'; prompt for sudo ..."
			fi
			doSudo='sudo';
		fi
	fi
	${doSudo} mkdir "${dirToCreate}";
	${doSudo} chown --reference="${existingDir}" "${dirToCreate}";
	${doSudo} chmod --reference="${existingDir}" "${dirToCreate}";
}
#==========================================================================
# End Section: General Utility functions
#==========================================================================

#==========================================================================
# Start Section: Binary/Hex/Octal functions
#==========================================================================
function compareBinaries() {
	if [[ "" == "$1" || "" == "$2" ]]; then
		echo "E: Requires two arguments.";
		echo "";
		echo "expected usage:";
		echo "  compareBinaries binary1 binary2";
		echo "";
		return -1;
	fi
	if [[ '' == "$(which $WHICH_OPTS cmp 2>/dev/null)" ]]; then
		echo "E: compareBinaries requires cmp to work; please install and try again.";
		return -2;
	fi
	cmp -l "$1" "$2" | gawk '{printf "%08X %02X %02X\n", $1, strtonum(0$2), strtonum(0$3)}';
}
function diffBinaries() {
	if [[ "" == "$1" || "" == "$2" ]]; then
		echo "E: Requires two arguments.";
		echo "";
		echo "expected usage:";
		echo "  diffBinaries binary1 binary2";
		echo "";
		return -1;
	fi
	if [[ '' == "$(which $WHICH_OPTS xxd 2>/dev/null)" || '' == "$(which $WHICH_OPTS diff 2>/dev/null)" ]]; then
		echo "E: diffBinaries requires xxd and diff to work; please install and try again.";
		return -2;
	fi
	local tmpDir="/tmp/diffBinaries-$(date +'%Y%m%d%H%M%S')";
	mkdir -p "${tmpDir}";
	if [[ -d "${tmpDir}" ]]; then
		echo "E: diffBinaries encountered an error while creating temp dir '${tmpDir}'";
		return -3;
	fi
	xxd "$1" > "${tmpDir}/xxd1.hex" 2>/dev/null;
	xxd "$2" > "${tmpDir}/xxd2.hex" 2>/dev/null;
	echo '';
	diff "${tmpDir}/xxd1.hex" "${tmpDir}/xxd2.hex";
}
function getStringBlobFromBinary() {
	local file="$1";
	if [[ "" == "$file" || ! -f "$file" ]]; then
		echo "E: No file passed or file does not exist.";
		return -1;
	fi
	local fileSizeInBytes=$(du --bytes "${file}"|cut -f1);
	hexdump -e "${fileSizeInBytes} \"%_p\" \"\\n\"" "${file}";
}
function getHexBlobWithNoSpacing() {
	local file="$1";
	if [[ "" == "$file" || ! -f "$file" ]]; then
		echo "E: No file passed or file does not exist.";
		return -1;
	fi
	local fileSizeInBytes=$(du --bytes "${file}"|cut -f1);
	hexdump -e "${fileSizeInBytes}/1 \"%02x\" \"\\n\"" "${file}"
}
function getHexBlobWithSingleByteSpacing() {
	local file="$1";
	if [[ "" == "$file" || ! -f "$file" ]]; then
		echo "E: No file passed or file does not exist.";
		return -1;
	fi
	local fileSizeInBytes=$(du --bytes "${file}"|cut -f1);
	hexdump -e "${fileSizeInBytes}/1 \"%02x \" \"\\n\"" "${file}"
}
#==========================================================================
# End Section: Binary/Hex/Octal functions
#==========================================================================

#==========================================================================
# Start Section: Git functions
#==========================================================================
function gitCloneWithFormattedDir() {
	local formatPattern="$1";
	local cloneUrl="$2";
	if [[ "" == "$1" || "" == "$2" || "-h" == "$1" || "--help" == "$1" || $formatPattern =~ ^ssh:.*$ || $formatPattern =~ ^git[@:].*$ || $formatPattern =~ ^[fh]t?tps?:.*$ || ! ( 'git@github.com:' == "${cloneUrl}" || 'git@gitlab.com:' == "${cloneUrl}" || $cloneUrl =~ ^[a-zA-Z][a-zA-Z0-9]*@.*:.*/.*$ || $cloneUrl =~ ^[fh]t?tps?://.*$ || $cloneUrl =~ ^[gs][is][th]://.*$ ) ]]; then
		if [[ "" == "$1" || "" == "$2" ]]; then
			echo 'E: Missing one or more arguments.';
			echo '';
		elif [[ $formatPattern =~ ^ssh:.*$ || $formatPattern =~ ^git[@:].*$ || $formatPattern =~ ^[fh]t?tps?:.*$ ]]; then
			echo 'E: Invalid format pattern / incorrect argument order. The first argument should be FORMAT_PATTERN.';
			echo '';
		elif [[ ! ( 'git@github.com:' == "${cloneUrl}" || 'git@gitlab.com:' == "${cloneUrl}" || $cloneUrl =~ ^[a-zA-Z][a-zA-Z0-9]*@.*:.*/.*$ || $cloneUrl =~ ^[fh]t?tps?://.*$ || $cloneUrl =~ ^[gs][is][th]://.*$ ) ]]; then
			echo 'E: Invalid clone url / incorrect argument order. The second argument should be a valid CLONE_URL.';
			echo "Note: this function does not support LOCAL clone urls";
			echo "Found: ${cloneUrl}";
			echo '';
		fi
		echo 'Expected usage:';
		echo '  gitCloneWithFormattedDir FORMAT_PATTERN CLONE_URL [OPTIONAL_ARGS]';
		echo '';
		echo 'Allows you to clone a git repository using a format pattern for the generated directory.';
		echo 'Currently only supports REMOTE clone urls (github/gitlab/bitbucket/http/https/ssh/ftp/ftps).';
		echo '';
		echo 'ARGUMENTS:';
		echo '  FORMAT_PATTERN    A format pattern to be used for the output folder that will be created.';
		echo '                    This can be relative to the current directory or prefixed with a path.';
		echo '                    See below for formatting options.';
		echo '  CLONE_URL         The clone url that will be passed to git clone';
		echo '  OPTIONAL_ARGS     Optional/arbitrary values that can be passed and referenced in the format string as %1, %2, etc';
		echo '                    Up to 9 OPTIONAL_ARGS may be passed after the clone url.';
		echo '';
		echo 'FORMATTING OPTIONS:';
		echo 'For literal percent signs, simply double them up (e.g. "This produces a literal %% symbol")';
		echo '';
		echo '  %o                Owner Name; this is taken from the clone url (e.g. https://github.com/OwnerName/RepoName)';
		echo '  %n                Repo Name; this is taken from the clone url (e.g. https://github.com/OwnerName/RepoName)';
		echo '  %1                First OPTIONAL_ARGS argument';
		echo '  %2                Second OPTIONAL_ARGS argument';
		echo '  %3                Third OPTIONAL_ARGS argument';
		echo '  %4                Fourth OPTIONAL_ARGS argument';
		echo '  %5                Fifth OPTIONAL_ARGS argument';
		echo '  %6                Sixth OPTIONAL_ARGS argument';
		echo '  %7                Seventh OPTIONAL_ARGS argument';
		echo '  %8                Eigthth OPTIONAL_ARGS argument';
		echo '  %9                Nineth OPTIONAL_ARGS argument';
		echo '';
		echo 'Examples:';
		echo $'  gitCloneWithFormattedDir \'%o_%n\' https://github.com/OwnerName/RepoName';
		echo '';
		return 0;
	fi
	shift 2;

	# note that sed does not have a non-greedy match equivalent to perl's .*?
	# there are workarounds such as https://0x2a.at/blog/2008/07/sed--non-greedy-matching/
	# but nothing simple/elegant like perl's solution
	# for max portability, we *could* cheat and just use 2 sed calls; one to trim off the .git if it exists
	# and another to work backwards from the right
	local repoName=$(echo "${cloneUrl}"|sed -E 's|^(.*)\.git$|\1|g'|sed -E 's|.*/([^/]+)$|\1|g');
	local ownerName=$(echo "${cloneUrl}"|sed -E 's|^(.*)\.git$|\1|g'|sed -E 's|.*[:/]([^:/]+)/[^/]+$|\1|g');

	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%n/\\1${repoName}/g");
	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%o/\\1${ownerName}/g");
	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%1/\\1${1}/g");
	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%2/\\1${2}/g");
	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%3/\\1${3}/g");
	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%4/\\1${4}/g");
	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%5/\\1${5}/g");
	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%6/\\1${6}/g");
	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%7/\\1${7}/g");
	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%8/\\1${8}/g");
	formatPattern=$(echo "${formatPattern}"|sed -E "s/(^|[^%])%9/\\1${9}/g");

	# Replace any doubled up percent signs with a literal percent sign
	formatPattern=$(echo "${formatPattern}"|sed -E "s/%%/%/g");

	git clone "${cloneUrl}" "${formatPattern}";
}
function gitCloneListWithFormattedDir() {
	local formatPattern="$1";
	# check remaining paths
	if (( ${#@} > 2 )); then
		local cloneUrl="";
		for (( i=2; i<${#@}; i++ )); do
			cloneUrl="${@:$i:1}";
			gitCloneWithFormattedDir "${formatPattern}" "${cloneUrl}";
		done
	fi
}
function gitArchiveLastCommit() {
	local currDir=$(pwd);
	if [[ ! -d "${currDir}/.git" ]]; then
		echo "E: Must be in top-level dir of a git repository.";
		return -1;
	fi
	local repoName="${currDir##*/}";
	local timeStamp=$(date +"%Y%m%d%H%M%S");
	local outFilePath="../${repoName}_${SUDO_USER:-$USER}_${timeStamp}_lastcommit.zip";
	echo "   -> outFilePath: '${outFilePath}'";
	git diff --diff-filter=CRAMX -z --name-only HEAD~1 HEAD | xargs -0 git archive HEAD -o "${outFilePath}" --;
}
function gitArchiveLastCommitBackout() {
	local currDir=$(pwd);
	if [[ ! -d "${currDir}/.git" ]]; then
		echo "E: Must be in top-level dir of a git repository.";
		return -1;
	fi
	local repoName="${currDir##*/}";
	local timeStamp=$(date +"%Y%m%d%H%M%S");
	local outFilePath="../${repoName}_${SUDO_USER:-$USER}_${timeStamp}_lastcommit.zip";
	echo "   -> outFilePath: '${outFilePath}'";
	git diff --diff-filter=CRAMX -z --name-only HEAD~1 HEAD | xargs -0 git archive HEAD~1 -o "${outFilePath}" --;
}
function gitArchiveAllCommitsSince() {
	local currDir=$(pwd);
	if [[ ! -d "${currDir}/.git" ]]; then
		echo "E: Must be in top-level dir of a git repository.";
		return -1;
	fi

	local commitOrBranchName="$1";
	if [[ "" == "${commitOrBranchName}" ]]; then
		echo "E: Must provide the name or hash value for either a commit or a branch to use as a base.";
		return -1;
	fi

	local displayName="${commitOrBranchName##*/}";
	displayName="${displayName//[![:alnum:]]/-}";

	local repoName="${currDir##*/}";
	local timeStamp=$(date +"%Y%m%d%H%M%S");
	local outFilePath="../${repoName}_${SUDO_USER:-$USER}_${timeStamp}_since_${displayName}.zip";
	echo "   -> outFilePath: '${outFilePath}'";
	git diff --diff-filter=CRAMX -z --name-only HEAD~1 HEAD | xargs -0 git archive HEAD -o "${outFilePath}" --;
}
function gitGrepHistoricalFileContents() {
	if [[ "" == "$1" ]]; then
		echo "gitGrepHistoricalFileContents(): No passed args.";
		echo "  Expected gitGrepHistoricalFileContents filename regex";
		return 0;
	fi
	if [[ "" == "$2" ]]; then
		echo "E: gitGrepHistoricalFileContents(): No passed search pattern.";
		echo "  Expected gitGrepHistoricalFileContents filename regex";
		return -1;
	fi

	git rev-list --all "$1" | (
		while read revision; do
			git grep -F "$2" $revision "$1"
		done
	)
}
function gitUpdateAllReposUnderDir() {
	local parentDir="$1";
	local startingDir=$(pwd);
	if [[ "" == "${parentDir}" ]]; then
		parentDir="${startingDir}";
	fi

	# print header - this gets printed from all logic paths so doing it once as a header up top saves space per output line
	echo "gitUpdateAllReposUnderDir():";

	# git commands must be performed relative to repo base folder
	cd "${parentDir}";

	local repoName='';
	local remoteName='';
	local remoteUrl='';

	# check if we are somewhere under a working directory in a git repo
	local repoTopLevelDir=$(git rev-parse --show-toplevel 2>/dev/null);
	if [[ "" != "${repoTopLevelDir}" ]]; then
		remoteName=$(git remote);
		if [[ "" != "${remoteName}" ]]; then
			remoteUrl=$(git remote get-url --push "${remoteName}");
		fi
		if [[ "" == "${remoteUrl}" ]]; then
			echo "E:  No remote fetch url found.";
			echo "  Skipping git repo: '${repoTopLevelDir}'";
			return -1;
		fi

		# If so, then update this single repo and exit back to terminal
		echo "  Updating git repo: '${repoTopLevelDir}'";
		echo "";

		cd "${repoTopLevelDir}";
		git fetch --all --quiet --progress;
		git pull --no-edit --all --quiet --progress;

		# then change back to starting dir and return (we're all done)
		cd "${startingDir}";
		return 0;
	fi

	# check for permission errors
	local permErrorCount=$(find "${parentDir}" -type d -name '.git' 2>&1|grep 'Permission denied'|wc -l);
	if [[ "0" != "${permErrorCount}" ]]; then
		echo "  W: Permission issues were detected for ${permErrorCount} subdirs. These subdirs will be ignored.";
		echo "  To view a list of subdirs with permission issues run:";
		echo "    find \"${parentDir}\" -type d -name '.git' >/dev/null";
	fi

	# otherwise, check if subfolders contain repos. if not then exit
	local totalRepos=$(find "${parentDir}" -type d -name '.git' 2>/dev/null|wc -l);
	if [[ "0" == "" ]]; then
		echo "E: No git repos found for '${parentDir}'";
		echo "";
		return -2;
	fi

	echo "  Found ${totalRepos} git repos under:";
	echo "    '${parentDir}'";
	echo "";

	# otherwise (if there are subfolders that contain repos) then update each of the subfolder repos
	local gitdir='';
	local subdir='';
	local displaysubdir='';
	local repoCounter=0;
	local padcount=0;
	find "${parentDir}" -type d -name '.git' 2>/dev/null | while IFS='' read gitdir; do
		subdir=$(dirname "$gitdir");
		cd "${subdir}";

		repoName=$(dirname "$subdir");
		displaysubdir="$subdir";
		if [[ "${subdir:0:${#HOME}}" == "${HOME}" ]]; then
			displaysubdir="~${subdir:${#HOME}}";
		fi

		#padcount is the total number of digits to display (so it must be at least one)
		padcount=$(( 1 + ${#totalRepos} - ${#repoCounter} ));

		repoCounter=$(( 1 + repoCounter ));

		# print formatted progress info
		printf "  ==============================================================================\\n";
		remoteUrl='';
		remoteName=$(git remote);
		if [[ "" != "${remoteName}" ]]; then
			remoteUrl=$(git remote get-url --push "${remoteName}");
		fi
		#printf "  subdir=%s remoteName=%s remoteUrl=%s\\n" "${subdir}" "${remoteName}" "${remoteUrl}";
		if [[ "" == "${remoteUrl}" ]]; then
			printf "  No remote fetch url found.\\n";
			printf "  Skipping repo %0${padcount}d of %d: %s (no remote fetch url)\\n" "${repoCounter}" "${totalRepos}" "${displaysubdir}";
			continue;
		fi
		printf "  Updating repo %0${padcount}d of %d: %s\\n" "${repoCounter}" "${totalRepos}" "${displaysubdir}";
		echo "";

		# call git pull in the targeted subdir
		git fetch --all --quiet --progress;
		git pull --no-edit --all --quiet --progress;
	done
}
function gitListRemotesForAllReposUnderDir() {
	local parentDir="$1";
	local startingDir=$(pwd);
	if [[ "" == "${parentDir}" ]]; then
		parentDir="${startingDir}";
	fi

	# print header - this gets printed from all logic paths so doing it once as a header up top saves space per output line
	echo "gitListRemotesForAllReposUnderDir():";

	# git commands must be performed relative to repo base folder
	cd "${parentDir}";

	local repoName='';
	local remoteName='';
	local remoteUrl='';

	# check if we are somewhere under a working directory in a git repo
	local repoTopLevelDir=$(git rev-parse --show-toplevel 2>/dev/null);
	if [[ "" != "${repoTopLevelDir}" ]]; then
		printf '%-60s\t%s\n' "${repoTopLevelDir}" $(git config --get remote.origin.url);

		# then change back to starting dir and return (we're all done)
		cd "${startingDir}";
		return 0;
	fi

	# check for permission errors
	local permErrorCount=$(find "${parentDir}" -type d -name '.git' 2>&1|grep 'Permission denied'|wc -l);
	if [[ "0" != "${permErrorCount}" ]]; then
		echo "  W: Permission issues were detected for ${permErrorCount} subdirs. These subdirs will be ignored.";
		echo "  To view a list of subdirs with permission issues run:";
		echo "    find \"${parentDir}\" -type d -name '.git' >/dev/null";
	fi

	# otherwise, check if subfolders contain repos. if not then exit
	local totalRepos=$(find "${parentDir}" -type d -name '.git' 2>/dev/null|wc -l);
	if [[ "0" == "" ]]; then
		echo "E: No git repos found for '${parentDir}'";
		echo "";
		return -3;
	fi

	echo "  Found ${totalRepos} git repos under:";
	echo "    '${parentDir}'";
	echo "";

	# otherwise (if there are subfolders that contain repos) then update each of the subfolder repos
	local gitdir='';
	local subdir='';
	local displaysubdir='';
	find "${parentDir}" -type d -name '.git' 2>/dev/null | while IFS='' read gitdir; do
		subdir=$(dirname "$gitdir");
		cd "${subdir}";

		repoName=$(dirname "$subdir");
		displaysubdir="$subdir";
		if [[ "${subdir:0:${#HOME}}" == "${HOME}" ]]; then
			displaysubdir="~${subdir:${#HOME}}";
		elif [[ "${subdir:0:${#startingDir}}" == "${startingDir}" ]]; then
			displaysubdir=".${subdir:${#startingDir}}";
		fi

		printf '%-60s\t%s\n' "${displaysubdir}" $(git config --get remote.origin.url);
	done
}
#==========================================================================
# End Section: Git functions
#==========================================================================

#==========================================================================
# Start Section: Office file functions
#==========================================================================
function convertPdfToText() {
	local pdfFile="$1";
	if [[ ! -e "${pdfFile}" ]]; then
		echo "E: Missing or bad input file path '$pdfFile' ";
		return -1;
	fi
	echo "Note: This conversion is an imperfect process. It is strongly recommended to review the file and make manual revisions when complete.";

	local textFile="";
	if [[ "$2" != "" ]]; then
		textFile="$2";
	else
		textFile="${pdfFile%.*}.txt"
	fi

	pdftotext "${pdfFile}" "${textFile}";
	if [[ -e "${textFile}" ]]; then
		#1) Remove trailing spaces
		perl -pi -e 's/[ \t]+$//g' "${textFile}";

		#2) Remove non-ascii characters
		perl -pi -e 's/[^[:ascii:]]//g' "${textFile}";

		#3) Convert tabs in paragraphs to spaces (perserve leading indents though)
		perl -pi -e 's/([\S])[ \t]+/$1 /g' "${textFile}";

		#4) Convert leading spaces to tabs (paragraph indents)
		perl -pi -e 's/^[ \t]+/\t/g' "${textFile}";

		#7) Convert 'form feed, new page' characters to 5x newlines
		perl -pi -e 's/^\x0c/\n\n\n\n\n/g' "${textFile}";
	fi
}
function convertPdfToMarkdown() {
	local pdfFile="$1";
	if [[ ! -e "${pdfFile}" ]]; then
		echo "E: Missing or bad input file path '$pdfFile' ";
		return -1;
	fi
	echo "Note: This conversion is an imperfect process. It is strongly recommended to review the file and make manual revisions when complete.";

	local textFile="";
	if [[ "$2" != "" ]]; then
		textFile="$2";
	else
		textFile="${pdfFile%.*}.md"
	fi

	pdftotext "${pdfFile}" "${textFile}";
	if [[ -e "${textFile}" ]]; then
		#1) Remove trailing spaces
		perl -pi -e 's/[ \t]+$//g' "${textFile}";

		#2) Remove non-ascii characters
		#this was stripping out apostrophes, list bullets, and lots of other stuff...
		#probably need to specifiy exact characters that should be removed
		#perl -pi -e 's/[^[:ascii:]]//g' "${textFile}";

		#3) Convert tabs in paragraphs to spaces (perserve leading indents though)
		perl -pi -e 's/([\S])[ \t]+/$1 /g' "${textFile}";

		#4) Convert leading spaces to tabs (paragraph indents)
		perl -pi -e 's/^[ \t]+/\n\t/g' "${textFile}";

		#5) Escape literal characters that would be treated as markup
		perl -0pi -e 's/\\/\\\\/smg' "${textFile}";
		perl -0pi -e 's/([#*><\[\]\(\)`|])/\\$1/smg' "${textFile}";

		#6) Convert 'form feed, new page' characters to markdown 'page break' syntax
		perl -pi -e 's/^\x0c/\\page\n/g' "${textFile}";

		#7) Assume non-indented mixed-text, less than 35 characters is a title/heading...
		perl -pi -e 's/^([A-Z][^\r\n]{5,34})$/##$1/g' "${textFile}";

		#8) Assume any non-title, non-indented mixed-text is an insert line break and remove it
		perl -0pi -e 's/(\n[^\s#\\][^\r\n]{40,})\n([^\s#\\][^\r\n]{40,})\n([^\s#\\])/$1 $2 $3/smg' "${textFile}";
		perl -0pi -e 's/(\n[^\s#\\][^\r\n]{40,})\n([^\s#\\][^\r\n]{40,})\n([^\s#\\])/$1 $2 $3/smg' "${textFile}";
		perl -0pi -e 's/(\n[^\s#\\][^\r\n]{40,})\n([^\s#\\])/$1 $2/smg' "${textFile}";
		perl -0pi -e 's/(\n[^\s#\\][^\r\n]{40,})\n([^\s#\\])/$1 $2/smg' "${textFile}";

		#9) Same thing but for an indented line to a non-indented line
		perl -0pi -e 's/(\n\t+[^\s#\\][^\r\n]{40,})\n([^\s#\\])/$1 $2/smg' "${textFile}";
	fi
}
function compressPdf() {
	local inputfile="$1";
	local arg2="$2";
	local arg3="$3";

	local outfile="${inputfile%.pdf}-compressed.pdf";
	local rvalue=150;
	if [[ "$arg2" != "" ]]; then
		outfile="$arg2";
	fi

	if [[ "$arg3" != "" ]]; then
		rvalue="$arg3";
	fi

	gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default \
	-dNOPAUSE -dQUIET -dBATCH -dDetectDuplicateImages \
	-dCompressFonts=true -r${rvalue} -sOutputFile="${outfile}" "${inputfile}" 2>/dev/null;
}
#==========================================================================
# End Section: Office file functions
#==========================================================================

#==========================================================================
# Start Section: Media file functions
#==========================================================================
function imageToBase64DataUri(){
	local mimetype=$(file -bN --mime-type "$1")
	local content=$(base64 -w0 < "$1")
	echo "url('data:$mimetype;base64,$content')"
}
function extractMp3AudioFromVideoFile() {
	local videofile="$1";
	local bitrate="$2";
	local defbitrate="160k";
	if [[ "" == "$2" || ! $bitrate =~ ^[1-9][0-9]{1,2}k$ ]]; then
		bitrate="$defbitrate";
	fi
	local filenameonly="${videofile%.*}"
	ffmpeg -i "${videofile}" -vn -acodec libmp3lame -ac 2 -ab $bitrate -ar 48000 "${filenameonly}.mp3"
}
function extractOggAudioFromVideoFile() {
	local videofile="$1";
	local filenameonly="${videofile%.*}"
	ffmpeg -i "${videofile}" -vn -acodec libvorbis "${filenameonly}.ogg"
}
function extractMp3AudioFromAllVideosInCurrentDir() {
	local bitrate="$1";
	local defbitrate="160k";
	if [[ "" == "$1" || ! $bitrate =~ ^[1-9][0-9]{1,2}k$ ]]; then
		bitrate="$defbitrate";
	fi

	for file in *.{3gp,arf,asf,avi,f4v,flv,h264,m1v,m2v,m4v,mkv,mov,mp4,mp4v,mpg,mpeg,ogm,ogv,ogx,qt,rm,rv,wmv} ; do
		if [[ "*" == "${file:0:1}" ]]; then
			continue;
		fi
		#no clobber; skip any that already exist
		file_without_ext="${file%.*}";
		if [[ ! -f "${file_without_ext}.mp3" ]]; then
			ffmpeg -i "$file" -vn -acodec libmp3lame -ac 2 -ab $bitrate -ar 48000 "${file_without_ext}.mp3"
		fi
	done
}
function extractMp3AudioFromAllMp4InCurrentDir() {
	local bitrate="$1";
	local defbitrate="160k";
	if [[ "" == "$1" || ! $bitrate =~ ^[1-9][0-9]{1,2}k$ ]]; then
		bitrate="$defbitrate";
	fi

	for vid in *.mp4; do
		echo "vid is: $vid"
		#skip any that already exist
		if [[ ! -f "${vid%.mp4}.mp3" ]]; then
			ffmpeg -i "$vid" -vn -acodec libmp3lame -ac 2 -ab $bitrate -ar 48000 "${vid%.mp4}.mp3"
		fi
	done
}
function extractMp3AudioFromAllFlvInCurrentDir() {
	local bitrate="$1";
	local defbitrate="160k";
	if [[ "" == "$1" || ! $bitrate =~ ^[1-9][0-9]{1,2}k$ ]]; then
		bitrate="$defbitrate";
	fi

	for vid in *.flv; do
		#skip any that already exist
		if [[ ! -f "${vid%.flv}.mp3" ]]; then
			ffmpeg -i "$vid" -vn -acodec libmp3lame -ac 2 -ab $bitrate -ar 48000 "${vid%.flv}.mp3"
		fi
	done
}
function extractOggAudioFromAllMp4InCurrentDir() {
	for vid in *.mp4; do
		#skip any that already exist
		if [[ ! -f "${vid%.mp4}.ogg" ]]; then
			ffmpeg -i "$vid" -vn -acodec libvorbis "${vid%.mp4}.ogg";
		fi
	done
}
function normalizeAllOggInCurrentDir() {
	for audio_file in *.ogg; do
		normalize-ogg "${audio_file}";
	done
}
function normalizeAllMp3InCurrentDir() {
	for audio_file in *.mp3; do
		normalize-mp3 "${audio_file}";
	done
}
function getMkvAllTrackIds() {
	local filePath="$1";
	if [[ "" == "$filePath" ]]; then
		echo "Expected usage:";
		echo "   getMkvAllTrackIds /path/to/mkvfile";
		return 501;
	elif [[ ! -f "$filePath" ]]; then
		echo "File '$filePath' does not exist.";
		return 502;
	fi
	mkvmerge --identify "${filePath}" | grep --color=never -i Track;
}
function getMkvAudioTrackIds() {
	local filePath="$1";
	if [[ "" == "$filePath" ]]; then
		echo "Expected usage:";
		echo "   getMkvAudioTrackIds /path/to/mkvfile";
		return 501;
	elif [[ ! -f "$filePath" ]]; then
		echo "File '$filePath' does not exist.";
		return 502;
	fi
	mkvmerge --identify "${filePath}" | grep --color=never -i Audio;
}
function getMkvSubtitleTrackIds() {
	local filePath="$1";
	if [[ "" == "$filePath" ]]; then
		echo "Expected usage:";
		echo "   getMkvSubtitleTrackIds /path/to/mkvfile";
		return 501;
	elif [[ ! -f "$filePath" ]]; then
		echo "File '$filePath' does not exist.";
		return 502;
	fi
	mkvmerge --identify "${filePath}" | grep --color=never -i subtitle;
}
function getMkvSubtitleTrackInfo() {
	local filePath="$1";
	if [[ "" == "$filePath" ]]; then
		echo "Expected usage:";
		echo "   getMkvSubtitleTrackInfo /path/to/mkvfile";
		return 501;
	elif [[ ! -f "$filePath" ]]; then
		echo "File '$filePath' does not exist.";
		return 502;
	fi
	local rawsubinfo=$(mkvinfo --track-info "${filePath}" | grep -A 6 -B 3 "Track type: subtitles");
	if [[ "" == "$rawsubinfo" ]]; then
		return 503;
	fi
	local cleansubinfo=$(echo "$rawsubinfo" | grep -E "(Track number|Name)" | perl -0pe "s/(^|\n)[\s\|\+]+/\$1/g" | perl -0pe "s/(^|\n)Track number.*track ID for mkvmerge\D+?(\d+)[^\s\d]+/\$1TrackID: \$2/gi" | perl -0pe "s/\n(Name:[^\n\r]+)/ \$1/gi");
	echo "${cleansubinfo}";
}
function getMkvAudioTrackInfo() {
	local mkvFilePath="$1";
	if [[ "" == "$mkvFilePath" ]]; then
		echo "Expected usage:";
		echo "   getMkvAudioTrackInfo /path/to/mkvfile";
		return 501;
	elif [[ ! -f "$mkvFilePath" ]]; then
		echo "File '$mkvFilePath' does not exist.";
		return 502;
	fi
	local rawAudioInfo=$(mkvinfo --track-info "${mkvFilePath}"|grep -Pv 'Default flag|Codec|Lacing|UID|Name'|grep -B 2 "Track type: audio");
	if [[ "" == "$rawAudioInfo" ]]; then
		return 503;
	fi
	local cleanedAudioInfo=$(echo "${rawAudioInfo}" | grep -E "(Track number|Lang)" | perl -0pe "s/(^|\n)[\s\|\+]+/\$1/g" | perl -0pe "s/(^|\n)Track number.*track ID for mkvmerge\D+?(\d+)[^\s\d]+/\$1TrackID: \$2/gi" | perl -0pe "s/\n(Language:[^\n\r]+)/ \$1/gi");
	echo "${cleanedAudioInfo}";
}
function removeMkvSubtitleTracksById() {
	local makeChangesInplace="$1";
	if [[ "-i" == "${makeChangesInplace}" || $makeChangesInplace =~ ^\-\-*inplace$ ]]; then
		makeChangesInplace="true";
		# shift remaining args once to the left
		shift;
	else
		makeChangesInplace="false";
	fi

	local filePath="$1";
	if [[ "" == "$filePath" ]]; then
		echo "Expected usage:";
		echo "   removeMkvSubtitleTracksById /path/to/mkvfile id1,id2,etc";
		return 501;
	elif [[ ! -f "$filePath" ]]; then
		echo "File '$filePath' does not exist.";
		return 502;
	fi

	local trackIds="$2";
	if [[ "" == "${trackIds}" || ! $trackIds =~ ^[1-9][0-9,]*$ ]]; then
		echo "E: removeMkvSubtitleTracksById(): empty or invalid track ids";
		echo "";
		echo "expected usage: ";
		echo "#get list of subtitle track ids";
		echo 'getMkvSubtitleTrackInfo';
		echo '';
		echo "#call this method to remove one or more subtitle track ids";
		echo 'removeMkvSubtitleTracksById /path/to/file.mkv id1,id2,etc';
		return -1;
	fi

	local bakFile="${filePath}.bak";
	if [[ -e "${bakFile}" ]]; then
		echo "E: removeMkvSubtitleTracksById(): *.bak file already exists.";
		return -2;
	fi
	mv "${filePath}" "${bakFile}";
	mkvmerge -o "${filePath}" --subtitle-tracks !${trackIds} "${bakFile}";

	# mkvmerge doesn't actually provide an option for making changes inpace;
	# this flag just tells whether or not to keep the backup file
	if [[ "true" == "${makeChangesInplace}" ]]; then
		rm "${bakFile}" 2>/dev/null;
	fi
}
function keepMkvSubtitleTracksById() {
	local makeChangesInplace="$1";
	if [[ "-i" == "${makeChangesInplace}" || $makeChangesInplace =~ ^\-\-*inplace$ ]]; then
		makeChangesInplace="true";
		# shift remaining args once to the left
		shift;
	else
		makeChangesInplace="false";
	fi

	local filePath="$1";
	if [[ "" == "$filePath" ]]; then
		echo "Expected usage:";
		echo "   keepMkvSubtitleTracksById /path/to/mkvfile id1,id2,etc";
		return 501;
	elif [[ ! -f "$filePath" ]]; then
		echo "File '$filePath' does not exist.";
		return 502;
	fi

	local trackIds="$2";
	if [[ "" == "${trackIds}" || ! $trackIds =~ ^[1-9][0-9,]*$ ]]; then
		echo "E: keepMkvSubtitleTracksById(): empty or invalid track ids";
		echo "";
		echo "expected usage: ";
		echo "#get list of subtitle track ids";
		echo 'getMkvSubtitleTrackInfo';
		echo '';
		echo "#call this method to keep one or more subtitle track ids";
		echo 'keepMkvSubtitleTracksById /path/to/file.mkv id1,id2,etc';
		return -1;
	fi

	local bakFile="${filePath}.bak";
	if [[ -e "${bakFile}" ]]; then
		echo "E: keepMkvSubtitleTracksById(): *.bak file already exists.";
		return -2;
	fi
	mv "${filePath}" "${bakFile}";
	mkvmerge -o "${filePath}" --subtitle-tracks ${trackIds} "${bakFile}";

	# mkvmerge doesn't actually provide an option for making changes inpace;
	# this flag just tells whether or not to keep the backup file
	if [[ "true" == "${makeChangesInplace}" ]]; then
		rm "${bakFile}" 2>/dev/null;
	fi
}
function setMkvDefaultTrackId() {
	local makeChangesInplace="$1";
	if [[ "-i" == "${makeChangesInplace}" || $makeChangesInplace =~ ^\-\-*inplace$ ]]; then
		makeChangesInplace="true";
		# shift remaining args once to the left
		shift;
	else
		makeChangesInplace="false";
	fi

	local filePath="$1";
	if [[ "" == "$filePath" ]]; then
		echo "Expected usage:";
		echo "   setMkvDefaultTrackId /path/to/mkvfile id";
		return 501;
	elif [[ ! -f "$filePath" ]]; then
		echo "File '$filePath' does not exist.";
		return 502;
	fi

	local defTrackId="$2";
	if [[ "" == "${defTrackId}" || ! $defTrackId =~ ^[1-9][0-9]*$ ]]; then
		echo "E: setMkvDefaultTrackId(): empty or invalid track id";
		echo "";
		echo "expected usage: ";
		echo "#get list of subtitle track ids";
		echo 'getMkvSubtitleTrackInfo';
		echo '';
		echo "# call this method to set exactly one track per track type (e.g. audio/subtitle/etc)";
		echo "# as the default track. the same method can be used to set either audio or subtitle tracks.";
		echo 'setMkvDefaultTrackId /path/to/file.mkv audioTrackId';
		echo 'setMkvDefaultTrackId /path/to/file.mkv subtitleTrackId';
		return -1;
	fi

	local bakFile="${filePath}.bak";
	if [[ -e "${bakFile}" ]]; then
		echo "E: setMkvDefaultTrackId(): *.bak file already exists.";
		return -2;
	fi
	mv "${filePath}" "${bakFile}";
	mkvmerge -o "${filePath}" --default-track ${defTrackId} "${bakFile}";

	# mkvmerge doesn't actually provide an option for making changes inpace;
	# this flag just tells whether or not to keep the backup file
	if [[ "true" == "${makeChangesInplace}" ]]; then
		rm "${bakFile}" 2>/dev/null;
	fi
}
function extractMkvSubtitleTextById() {
	local mkvFilePath="$1";
	if [[ "" == "$mkvFilePath" ]]; then
		echo "Expected usage:";
		echo "   extractMkvSubtitleTextById /path/to/mkvfile [trackId]";
		echo "";
		echo "If no subtitle tracj id is provided, then the first subtitle track will be used automatically.";
		return 501;
	elif [[ ! -f "$mkvFilePath" ]]; then
		echo "File '$mkvFilePath' does not exist.";
		return 502;
	fi

	local trackId="$2";
	if [[ "" == "${trackId}" ]]; then
		echo 'W: No subtitle trackId provided; looking up first subtitle track...';
		local firstSubtitleTrackId=$(mkvmerge -i "${mkvFilePath}"|grep -P '^Track ID.*subtitle'|sed -E 's/^Track ID ([1-9][0-9]*): .*subtitle.*$/\1/g'|head -1);

		if [[ $firstSubtitleTrackId =~ ^[1-9][0-9]*$ ]]; then
			echo "W: Set subtitle trackId as track ${firstSubtitleTrackId}";
			trackId="${firstSubtitleTrackId}";
		fi
	fi

	if [[ "" == "${trackId}" || ! $trackId =~ ^[1-9][0-9]*$ ]]; then
		echo "E: extractMkvSubtitleTextById(): empty or invalid track id";
		echo "";
		echo "expected usage: ";
		echo "#get list of subtitle track ids";
		echo 'getMkvSubtitleTrackInfo';
		echo '';
		echo "#call this method to remove one or more subtitle track ids";
		echo 'extractMkvSubtitleTextById /path/to/file.mkv subtitleTrackId';
		return -1;
	fi

	#local tmpSrt=$(date +"/tmp/%Y%m%d%H%M%S%N_$RANDOM.srt");
	#mkvextract "${mkvFilePath}" tracks "${trackId}:${tmpSrt}";
	#mv "${tmpSrt}" "${mkvFilePath%.*}.srt";
	mkvextract "${mkvFilePath}" tracks "${trackId}:${mkvFilePath%.*}.srt";
}
function addMkvSubtitleText() {
	local makeChangesInplace="$1";
	if [[ "-i" == "${makeChangesInplace}" || $makeChangesInplace =~ ^\-\-*inplace$ ]]; then
		makeChangesInplace="true";
		# shift remaining args once to the left
		shift;
	else
		makeChangesInplace="false";
	fi

	local mkvFilePath="$1";
	if [[ "" == "$mkvFilePath" ]]; then
		echo "Expected usage:";
		echo "   addMkvSubtitleText [-i]  /path/to/file.mkv /path/to/subtitle.srt [/path/to/output-file] [subtitle track name]";
		echo "";
		echo "  -i, --inplace   makes the changes in place (e.g. in the same file without creating a backup)";
		return 501;
	elif [[ ! -f "$mkvFilePath" ]]; then
		echo "File '${mkvFilePath}' does not exist.";
		return 502;
	fi

	local srtFilePath="$2";
	if [[ "" == "$srtFilePath" ]]; then
		echo "Expected usage:";
		echo "   addMkvSubtitleText [-i] /path/to/file.mkv /path/to/subtitle.srt [/path/to/output-file]";
		return 501;
	elif [[ ! -f "$srtFilePath" ]]; then
		echo "File '${srtFilePath}' does not exist.";
		return 502;
	fi

	mkvFilePath=$(realpath "$mkvFilePath");
	srtFilePath=$(realpath "$srtFilePath");

	local outputFilePath="$3";

	local subtitleTrackName="$4";
	if [[ "" == "$subtitleTrackName" ]]; then
		subtitleTrackName="English";
	fi

	if [[ "" != "$outputFilePath" && "$outputFilePath" != "$mkvFilePath" ]]; then
		mkvmerge -o "$outputFilePath" "$mkvFilePath" --language 0:eng --track-name 0:"$subtitleTrackName" "$srtFilePath";
	else
		local bakFile="${mkvFilePath}.bak";
		if [[ -e "${bakFile}" ]]; then
			echo "E: addMkvSubtitleText(): *.bak file already exists.";
			return -1;
		fi
		mv "${mkvFilePath}" "${bakFile}";
		mkvmerge -o "$mkvFilePath" "$bakFile" --language 0:eng --track-name 0:"$subtitleTrackName" "$srtFilePath";

		# mkvmerge doesn't actually provide an option for making changes inpace;
		# this flag just tells whether or not to keep the backup file
		if [[ "true" == "${makeChangesInplace}" ]]; then
			rm "${bakFile}" 2>/dev/null;
		fi
	fi
}
function perlReplaceMkvSubtitleTextById() {
	if [[ ! '1' == "${MKV_FUNC_DEUG}" ]]; then
		echo 'perlReplaceMkvSubtitleTextById - WIP; uncomment or set MKV_FUNC_DEUG=1 to test';
		echo 'at last checkpoint on 6/14/20 @ 3:11pm, the regex replace was not working correctly';
		return -1;
	fi

	local defPerlArgs='-pie';
	local mkvFilePath="$1";
	if [[ "" == "$mkvFilePath" || "-h" == "$mkvFilePath" || $mkvFilePath =~ ^\-\-*help$ ]]; then
		echo "Expected usage:";
		echo "   perlReplaceMkvSubtitleTextById /path/to/file.mkv subtitleTrackId [PERL_OPT] PERL5_EXPR";
		echo "";
		echo "subtitleTrackId       the integer id of specific subtitle track to perform perl replace against.";
		echo "PERL_OPT              any command-line arguments to pass to perl (defaults to ${defPerlArgs}; -i is required)";
		echo "PERL5_EXPR            the regex replace express to pass to perl (ex: 's/\\b(enrol)\\b/enroll/gi' )";
		echo "";
		echo "";
		echo "Examples";
		echo "  # Fix a typo";
		echo "  perlReplaceMkvSubtitleTextById /path/to/file.mkv subtitleTrackId 's/\\b(enrol)\\b/enroll/gi' ";
		echo "";
		echo "  # Censor/Uncensor language";
		echo "  perlReplaceMkvSubtitleTextById /path/to/file.mkv subtitleTrackId 's/\\b(F[*]{3})\\b/Fuck/gi' ";
		echo "  perlReplaceMkvSubtitleTextById /path/to/file.mkv subtitleTrackId 's/\\b(Fuck)\\b/F***/gi' ";
		echo "";
		echo "  # Remove non-dialog tagging";
		echo "  perlReplaceMkvSubtitleTextById /path/to/file.mkv subtitleTrackId 's/\\b(Subs by [-+.:\\w]+)\\b//gi' ";
		echo "";
		return 501;
	elif [[ ! -f "$mkvFilePath" ]]; then
		echo "File '$mkvFilePath' does not exist.";
		return 502;
	fi

	local trackId="$2";
	if [[ "" == "${trackId}" || ! $trackId =~ ^[1-9][0-9]*$ ]]; then
		echo "E: perlReplaceMkvSubtitleTextById(): empty or invalid track id";
		echo "";
		echo "expected usage: ";
		echo "#get list of subtitle track ids";
		echo 'getMkvSubtitleTrackInfo';
		echo '';
		echo "#call this method to edit a single subtitle track's text";
		echo "#this can be used to e.g. fix typos, un/censor profanity, remove non-dialog, etc";
		echo "perlReplaceMkvSubtitleTextById /path/to/file.mkv subtitleTrackId 's/\\b(enrol)\\b/enroll/gi' ";
		return -1;
	fi

	local perlOptions="$3";
	if [[ "" == "${perlOptions}" || ! $perlOptions =~ ^\-[a-z0-9]*i[a-z0-9]*$ ]]; then
		perlOptions="${defPerlArgs}";
	else
		# if we have legit perl options, then do a argument shift 1 to the left
		# this is because generally perl options won't be specified and arg3 will
		# be the PERL5_EXPR instead
		shift;
	fi

	local perlExpr="$3";
	if [[ "" == "${perlExpr}" || ! $perlExpr =~ ^[s][^A-Za-z0-9].*[^A-Za-z0-9][gims]*$ ]]; then
		echo "Invalid perl5 substitution expression '$perlExpr'.";
		echo "Please see --help";
		return 503;
	fi

	local bakFile="${mkvFilePath}.bak";
	if [[ -e "${bakFile}" ]]; then
		echo "E: *.bak file already exists.";
		return -1;
	fi

	local tmpFile="${mkvFilePath}.tmp";
	if [[ -e "${tmpFile}" ]]; then
		echo "E: *.tmp file already exists.";
		return -2;
	fi

	# 1. Extract subs
	local tmpSrt=$(date +"/tmp/%Y%m%d%H%M%S%N_$RANDOM.srt");
	mkvextract "${mkvFilePath}" tracks "${trackId}:${tmpSrt}";
	if [[ ! -f "${tmpSrt}" ]]; then
		echo "E: Failed to extract subtitles.";
		return 504;
	fi

	# 2. Remove all old subtitle tracks
	local tracksToRemove=$(mkvmerge -i "${mkvFilePath}"|grep -P '^Track ID.*subtitle'|sed -E 's/^Track ID ([1-9][0-9]*): .*subtitle.*$/\1/g'|tr '\n' ','|sed 's/,$//g');
	mv "${mkvFilePath}" "${bakFile}";
	mkvmerge -o "${mkvFilePath}" --subtitle-tracks !${tracksToRemove} "${bakFile}";

	# 3. Call Perl to edit subs
	perl ${perlOptions} "${perlExpr}" "${tmpSrt}";

	# 4. Add only the new subtitle tracks back in
	mv "${mkvFilePath}" "${tmpFile}";
	mkvmerge -o "$mkvFilePath" "$tmpFile" --language 0:eng --track-name 0:"English" "$tmpSrt";

	# mkvmerge doesn't actually provide an option for making changes inpace;
	# this flag just tells whether or not to keep the backup file
	if [[ "true" == "${makeChangesInplace}" ]]; then
		rm "${bakFile}" 2>/dev/null;
	fi
}
function batchRemoveMkvSubtitleTracksById() {
	local folderPath="$1";
	local trackIds="$2";

	if [[ "" == "${trackIds}" && "" != "${folderPath}" && $folderPath =~ ^[0-9][0-9,]*$ ]]; then
		trackIds="${folderPath}";
		folderPath=$(pwd);
	fi

	if [[ "" == "${folderPath}" || "" == "${trackIds}" || ! $trackIds =~ ^[0-9][0-9,]*$ ]]; then
		echo "E: batchRemoveMkvSubtitleTracksById(): empty or invalid track ids";
		echo "";
		echo "expected usage: ";
		echo "#get list of subtitle track ids";
		echo 'getMkvSubtitleTrackInfo';
		echo '';
		echo "#call this method to remove one or more subtitle track ids";
		echo 'batchRemoveMkvSubtitleTracksById /dir/with/mkvs id1,id2,etc';
		return -1;
	fi
	if [[ ! -e "${folderPath}" ]]; then
		echo "E: batchRemoveMkvSubtitleTracksById(): mkv parent folder does not exist.";
		return -2;
	fi
	local options="";
	local originalLocation=$(pwd);
	cd "${folderPath}";
	for file in *mkv; do
		mv "$file" "${file}.bak";
		mkvmerge -o "$file" --subtitle-tracks !${trackIds} "${file}.bak";
		if [[ -e "${file}" ]]; then
			rm "${file}.bak";
		fi
	done
	cd "${originalLocation}";
}
function batchKeepMkvSubtitleTracksById() {
	local folderPath="$1";
	local trackIds="$2";

	if [[ "" == "${trackIds}" && "" != "${folderPath}" && $folderPath =~ ^[0-9][0-9,]*$ ]]; then
		trackIds="${folderPath}";
		folderPath=$(pwd);
	fi

	if [[ "" == "${folderPath}" || "" == "${trackIds}" || ! $trackIds =~ ^[0-9][0-9,]*$ ]]; then
		echo "E: batchKeepMkvSubtitleTracksById(): empty or invalid track ids";
		echo "";
		echo "expected usage: ";
		echo "#get list of subtitle track ids";
		echo 'getMkvSubtitleTrackInfo';
		echo '';
		echo "#call this method to keep one or more subtitle track ids";
		echo 'batchKeepMkvSubtitleTracksById /dir/with/mkvs id1,id2,etc';
		return -1;
	fi
	if [[ ! -e "${folderPath}" ]]; then
		echo "E: batchKeepMkvSubtitleTracksById(): mkv parent folder does not exist.";
		return -2;
	fi
	local originalLocation=$(pwd);
	cd "${folderPath}";
	for file in *mkv; do
		mv "$file" "${file}.bak";
		mkvmerge -o "$file" --subtitle-tracks ${trackIds} "${file}.bak";
		if [[ -e "${file}" ]]; then
			rm "${file}.bak";
		fi
	done
	cd "${originalLocation}";
}
function batchExtractMkvSubtitleTextById() {
	local folderPath="$1";
	local trackId="$2";

	if [[ "" == "${trackId}" && "" != "${folderPath}" && $folderPath =~ ^[0-9][0-9]*$ ]]; then
		trackId="${folderPath}";
		folderPath=$(pwd);
	fi

	if [[ "" == "${folderPath}" || "" == "${trackId}" || ! $trackId =~ ^[0-9][0-9]*$ ]]; then
		echo "E: batchExtractMkvSubtitleTextById(): empty or invalid track id";
		echo "";
		echo "expected usage: ";
		echo "#get list of subtitle track ids";
		echo 'getMkvSubtitleTrackInfo';
		echo '';
		echo "#call this function to extract the given subtitle track from the mkv as text (srt)";
		echo 'batchExtractMkvSubtitleTextById /dir/with/mkvs id';
		return -1;
	fi
	if [[ ! -e "${folderPath}" ]]; then
		echo "E: batchExtractMkvSubtitleTextById(): mkv parent folder does not exist.";
		return -2;
	fi
	local originalLocation=$(pwd);
	cd "${folderPath}";
	for file in *mkv; do
		mkvextract "${file}" tracks "${trackId}:${file%.*}.srt";
	done
	cd "${originalLocation}";
}
function batchAddMkvSubtitleText() {
	local replaceExisting="$1";
	if [[ "-r" == "${replaceExisting}" || $replaceExisting =~ ^\-\-*replace-existing$ ]]; then
		replaceExisting="true";
		# shift remaining args once to the left
		shift;
	else
		replaceExisting="false";
	fi

	local folderPath="$1";

	if [[ "" == "${folderPath}" || "-h" == "${folderPath}" || "--help" == "${folderPath}" ]]; then
		echo "expected usage: ";
		echo '';
		echo "# call this function to add subtitle track to the mkv";
		echo "# expects one srt per mkv and all mkv/srt pairs should have matching names"
		echo 'batchAddMkvSubtitleText /dir/with/mkvs';
		echo '';
		echo '# same as above but replace existing tracks and only keep the track being added'
		echo 'batchAddMkvSubtitleText -r /dir/with/mkvs';
		echo 'batchAddMkvSubtitleText --replace-existing /dir/with/mkvs';
		return 0;
	fi
	if [[ ! -e "${folderPath}" ]]; then
		echo "E: batchAddMkvSubtitleText(): mkv parent folder does not exist.";
		return -2;
	fi
	local originalLocation=$(pwd);
	cd "${folderPath}";

	local tracksToRemove='';
	for file in *mkv; do
		# make sure the paired srt file exists, if not then skip this file
		if [[ ! -f "${file%.*}.srt" ]]; then
			continue;
		fi

		mv "$file" "${file%.*}.tmp";
		if [[ "true" == "${replaceExisting}" ]]; then
			# remove existing subtitle tracks
			tracksToRemove=$(mkvmerge -i "${file%.*}.tmp"|grep -P '^Track ID.*subtitle'|sed -E 's/^Track ID ([1-9][0-9]*): .*subtitle.*$/\1/g'|tr '\n' ','|sed 's/,$//g');
			mkvmerge -o "$file" --subtitle-tracks !${tracksToRemove} "${file%.*}.tmp";
			mv "$file" "${file%.*}.tmp";
		fi
		#add the srt file
		mkvmerge -o "$file" "${file%.*}.tmp" --language 0:eng --track-name 0:English "${file%.*}.srt";
		if [[ -e "${file}" ]]; then
			rm "${file}.tmp";
		fi
	done
	cd "${originalLocation}";
}
function batchSetMkvDefaultTrackId() {
	local folderPath="$1";
	local defTrackId="$2";

	if [[ "" == "${defTrackId}" && "" != "${folderPath}" && $folderPath =~ ^[0-9][0-9]*$ ]]; then
		defTrackId="${folderPath}";
		folderPath=$(pwd);
	fi

	if [[ "" == "${defTrackId}" || ! $defTrackId =~ ^[1-9][0-9]*$ ]]; then
		echo "E: batchSetMkvDefaultTrackId(): empty or invalid track ids";
		echo "";
		echo "expected usage: ";
		echo "#get list of subtitle track ids";
		echo 'getMkvSubtitleTrackInfo';
		echo '';
		echo "# call this method to set exactly one track per track type (e.g. audio/subtitle/etc)";
		echo "# as the default track. the same method can be used to set either audio or subtitle tracks.";
		echo 'batchSetMkvDefaultTrackId /path/to/folder audioTrackId';
		echo 'batchSetMkvDefaultTrackId /path/to/folder subtitleTrackId';
		return -1;
	fi

	if [[ ! -e "${folderPath}" ]]; then
		echo "E: batchSetMkvDefaultTrackId(): mkv parent folder does not exist.";
		return -2;
	fi
	local originalLocation=$(pwd);
	cd "${folderPath}";
	for file in *mkv; do
		mv "$file" "${file}.bak";
		mkvmerge -o "${file}" --default-track ${defTrackId} "${file}.bak";
		if [[ -e "${file}" ]]; then
			rm "${file}.bak";
		fi
	done
	cd "${originalLocation}";
}
function batchLogMkvSubtitleTrackInfo() {
	local outputFileName="SUBTITLES_INFO.txt";
	local folderPath="$1";

	if [[ "" == "${folderPath}" ]]; then
		folderPath=$(pwd);

	elif [[ "-h" == "${folderPath}" || $folderPath =~ ^\-\-*help$ ]]; then
		echo "E: batchLogMkvSubtitleTrackInfo(): empty dir";
		echo "";
		echo "expected usage: ";
		echo "#output a list of subtitle track ids to ${outputFileName}";
		echo 'batchLogMkvSubtitleTrackInfo /dir/with/mkvs';
		return -1;
	fi
	if [[ ! -e "${folderPath}" ]]; then
		echo "E: batchLogMkvSubtitleTrackInfo(): mkv parent folder does not exist.";
		return -2;
	fi
	local originalLocation=$(pwd);
	local SEPARATOR="------------------------------------";
	cd "${folderPath}";
	for file in *mkv; do
		printf '\n%s\n%s\n%s\n\n' "${SEPARATOR}" "${file}" "${SEPARATOR}" >> "${outputFileName}";

		local rawsubinfo=$(mkvinfo --track-info "${file}" | grep -A 6 -B 3 "Track type: subtitles");
		if [[ "" == "$rawsubinfo" ]]; then
			echo "  -> No subs detected." >> "${outputFileName}";
			continue;
		fi
		local cleansubinfo=$(echo "$rawsubinfo" | grep -E "(Track number|Name)" | perl -0pe "s/(^|\n)[\s\|\+]+/\$1/g" | perl -0pe "s/(^|\n)Track number.*track ID for mkvmerge\D+?(\d+)[^\s\d]+/\$1TrackID: \$2/gi" | perl -0pe "s/\n(Name:[^\n\r]+)/ \$1/gi");

		echo "${cleansubinfo}" >> "${outputFileName}";
	done
	cd "${originalLocation}";
}
function convertAlleBooksInDirToMobi() {
	local targetDir="$1";
	local startingDir="$(pwd)";
	if [[ '' == "${targetDir}" ]]; then
		targetDir="${startingDir}";

	elif [[ ! -d "${targetDir}" ]]; then
		echo "E: targetDir '${targetDir}' does not exist.";
		return -1;
	fi
	cd "${targetDir}";

	local ebook='';
	for ebook in *.{epub,pdf}; do
		echo "ebook is: $ebook"
		#skip any that already exist
		if [[ ! -f "${ebook%.*}.mobi" ]]; then
			ebook-convert "${ebook}" "${ebook%.*}.mobi";
		fi
	done
	if [[ "${targetDir}" != "${startingDir}" ]]; then
		cd "${startingDir}";
	fi
}
function recursivelyCleanDuplicateNonMobieBooksInDir() {
	local targetDir="$1";
	local startingDir="$(pwd)";
	if [[ '' == "${targetDir}" ]]; then
		targetDir="${startingDir}";

	elif [[ ! -d "${targetDir}" ]]; then
		echo "E: targetDir '${targetDir}' does not exist.";
		return -1;
	fi
	cd "${targetDir}";

	# extensions to remove (in alphabetic order)
	local removableExtsList="azw azw3 bmp doc fb2 htm html htmlz lit opf pdb rar rtf txt zip";

	local filename='';
	local ext='';
	local dupe='';
	while IFS= read -d $'\0' -r file ; do
		#printf 'File found: %s\n' "$file"

		# remove mobi extension
		filename="${file%.*}";
		#echo "filename: $filename";

		# delete unwanted dupes in other formats...
		for ext in ${removableExtsList}; do
			dupe="${filename}.${ext}";
			#echo "looking for $dupe";

			if [[ -f "${dupe}" ]]; then
				echo "removing duplicate: ${dupe}"
				rm "${dupe}";
			fi
		done

	done < <(find . -type f -not -iwholename '*.git/*' -iname '*.mobi' -print0)
	if [[ "${targetDir}" != "${startingDir}" ]]; then
		cd "${startingDir}";
	fi
}
#==========================================================================
# End Section: Media file functions
#==========================================================================

#==========================================================================
# Start Section: Wine functions
#==========================================================================
function createNewWine32Prefix() {
	if [[ "" == "$1" ]]; then
		echo "E: Requires argument.";
		echo "";
		echo "expected usage:";
		echo "  createNewWine32Prefix folder-to-be-created";
		echo "";
		echo "  Note:  the new prefix folder must not exist yet.";
		return -1;
	elif [[ -e "$1" ]]; then
		echo "E: Path already exists; wine will not create a new prefix at an existing location.";
		echo "";
		echo "expected usage:";
		echo "  createNewWine32Prefix folder-to-be-created";
		echo "";
		echo "  Note:  the new prefix folder must not exist yet.";
		return -2;
	fi
	local newWinePrefixPath="$1";
	# note: realpath does not check/care if the far right node exists
	newWinePrefixPath="$(realpath "${newWinePrefixPath}")";

	env WINEDEBUG="fixme-all" WINEPREFIX="${newWinePrefixPath}" WINEARCH=win32 wine wineboot
	retCode="$?"

	if [[ 0 == ${retCode} ]]; then
		wineApplyBug50867Workaround "${newWinePrefixPath}";
		wineSandboxUserDir "${newWinePrefixPath}";
		wineRemoveRootDriveSymlink "${newWinePrefixPath}";
	fi
	return ${retCode};
}
function createNewWine64Prefix() {
	if [[ "" == "$1" ]]; then
		echo "E: Requires argument.";
		echo "";
		echo "expected usage:";
		echo "  createNewWine64Prefix folder-to-be-created";
		echo "";
		echo "  Note:  the new prefix folder must not exist yet.";
		return -1;
	elif [[ -e "$1" ]]; then
		echo "E: Path already exists; wine will not create a new prefix at an existing location.";
		echo "";
		echo "expected usage:";
		echo "createNewWine64Prefix folder-to-be-created";
		echo "";
		echo "Note:  the new prefix folder must not exist yet.";
		return -2;
	fi
	local newWinePrefixPath="$1";
	# note: realpath does not check/care if the far right node exists
	newWinePrefixPath="$(realpath "${newWinePrefixPath}")";

	env WINEDEBUG="fixme-all" WINEPREFIX="${newWinePrefixPath}" WINEARCH=win64 wine wineboot
	retCode="$?"

	if [[ 0 == ${retCode} ]]; then
		wineApplyBug50867Workaround "${newWinePrefixPath}";
		wineSandboxUserDir "${newWinePrefixPath}";
		wineRemoveRootDriveSymlink "${newWinePrefixPath}";
	fi
	return ${retCode};
}
function wineApplyBug50867Workaround() {
	local foundValidWinePrefix='false';
	local startingDir=$(pwd);
	local winePrefixDir="${startingDir}";
	if [[ '' != "$1" && -d "${1}/dosdevices" ]]; then
		winePrefixDir="$1";
	fi

	if [[ -d  "${winePrefixDir}/drive_c" ]]; then
		foundValidWinePrefix='true';
	else
		while [[ "false" == "${foundValidWinePrefix}" ]]; do
			if [[ -d  "${winePrefixDir}/drive_c" ]]; then
				foundValidWinePrefix='true';
				break;
			fi
			winePrefixDir=$(dirname "${winePrefixDir}");
			if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
				break;
			fi
		done;
	fi
	if [[ "false" == "${foundValidWinePrefix}" ]]; then
		echo "E: wineApplyBug50867Workaround - Not under a valid WINEPREFIX folder.";
		return -1;
	fi

	# fix for wine bug #50867 which affects wine staging 6.5
	# https://bugs.winehq.org/show_bug.cgi?id=50867
	# this creates a hard-linked copy of 'start.exe' if it
	# doesn't exist on the windows PATH as seen by wine 6.5
	if [[ ! -f "${winePrefixDir}/drive_c/windows/start.exe" ]]; then
		if [[ -f "${winePrefixDir}/drive_c/windows/command/start.exe" ]]; then
			ln "${winePrefixDir}/drive_c/windows/command/start.exe" "${winePrefixDir}/drive_c/windows/start.exe"
		fi
	fi
}
function wineRemoveRootDriveSymlink() {
	local foundValidWinePrefix='false';
	local startingDir=$(pwd);
	local winePrefixDir="${startingDir}";
	if [[ '' != "$1" && -d "${1}/dosdevices" ]]; then
		winePrefixDir="$1";
	fi

	if [[ -d  "${winePrefixDir}/drive_c" ]]; then
		foundValidWinePrefix='true';
	else
		while [[ "false" == "${foundValidWinePrefix}" ]]; do
			if [[ -d  "${winePrefixDir}/drive_c" ]]; then
				foundValidWinePrefix='true';
				break;
			fi
			winePrefixDir=$(dirname "${winePrefixDir}");
			if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
				break;
			fi
		done;
	fi
	if [[ "false" == "${foundValidWinePrefix}" ]]; then
		echo "E: wineRemoveRootDriveSymlink - Not under a valid WINEPREFIX folder.";
		return -1;
	fi

	# remove default "Z:" drive mapping, if it exists; no sense making system-wide access easy
	# this does NOT make it secure - programs CAN still access any folders that the linux user
	# account running the process can access. All this does is maybe make it very slightly more
	# difficult for a windows app to access the linux filesystem without intentionally trying to do so.
	#
	# https://forums.linuxmint.com/viewtopic.php?t=197097
	#
	if [[ -e "${winePrefixDir}/dosdevices/z:" ]]; then
		rm "${winePrefixDir}/dosdevices/z:";
	fi

	# https://bugs.winehq.org/attachment.cgi?id=65706
	# https://bugs.winehq.org/show_bug.cgi?id=48114
	# Disable unixfs
	# Unfortunately, when you run with a different version of Wine, Wine will recreate this key.
	# See https://bugs.winehq.org/show_bug.cgi?id=22450
	env WINEDEBUG="fixme-all" WINEPREFIX="${winePrefixDir}" wine regedit /D 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' 2>&1 >/dev/null;

	if [[ 1 == $(which $WHICH_OPTS winetricks 2>/dev/null|wc -l) ]]; then
		env WINEDEBUG="fixme-all" WINEPREFIX="${winePrefixDir}" winetricks sandbox >/dev/null;
	fi
}
function wineSandboxUserDir() {
	local foundValidWinePrefix='false';
	local startingDir=$(pwd);
	local winePrefixDir="${startingDir}";
	if [[ '' != "$1" && -d "${1}/dosdevices" ]]; then
		winePrefixDir="$1";
	fi

	if [[ -d  "${winePrefixDir}/drive_c" ]]; then
		foundValidWinePrefix='true';
	else
		while [[ "false" == "${foundValidWinePrefix}" ]]; do
			if [[ -d  "${winePrefixDir}/drive_c" ]]; then
				foundValidWinePrefix='true';
				break;
			fi
			winePrefixDir=$(dirname "${winePrefixDir}");
			if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
				break;
			fi
		done;
	fi
	if [[ "false" == "${foundValidWinePrefix}" ]]; then
		echo "E: wineSandboxUserDir - Not under a valid WINEPREFIX folder.";
		return -1;
	fi

	if [[ -d "${winePrefixDir}" ]]; then
		local wineSysDrive="${newWinePrefixPath}/drive_c";
		local wineAllUsersDir="${newWinePrefixPath}/drive_c/users";
		local wineUserDir="${newWinePrefixPath}/drive_c/users/wineuser";

		# setup users dir generically so that it is less important which linux user is used to access
		# this is particularly useful for multiboot and multiuser systems where a single install is shared
		mkdir -p "${wineAllUsersDir}" 2>/dev/null;
		if [[ -d "${wineAllUsersDir}/${USER}" ]]; then
			mv "${wineAllUsersDir}/${USER}" "${wineUserDir}";
		else
			mkdir -p "${wineUserDir}" 2>/dev/null;
		fi
		ln -s "${wineUserDir}" "${wineAllUsersDir}/${USER}";

		# create symlinks for each of the other users under /home with uid=$UID
		# (this is mostly intended for multiboot setups)
		AU_DIR="${wineAllUsersDir}" \
		WU_DIR="${wineUserDir}" \
		find /home -mindepth 1 -maxdepth 1 -user "$USER" -not -iname "$USER" -exec bash -c \
			"d=\"{}\";u=\"\$(echo \"\$d\"|cut -d/ -f3)\"; ln -s \"\${WU_DIR}\" \"\${AU_DIR}/\${u}\";" \; \
			2>/dev/null

		if [[ -d "${wineUserDir}" ]]; then
			# remove default symlinks which link to actual linux user folders
			rm "${wineUserDir}/Desktop" 2>/dev/null;
			rm "${wineUserDir}/Documents" 2>/dev/null;
			rm "${wineUserDir}/Downloads" 2>/dev/null;
			rm "${wineUserDir}/My Documents" 2>/dev/null;
			rm "${wineUserDir}/My Music" 2>/dev/null;
			rm "${wineUserDir}/My Pictures" 2>/dev/null;
			rm "${wineUserDir}/My Videos" 2>/dev/null;
			rm "${wineUserDir}/Music" 2>/dev/null;
			rm "${wineUserDir}/Pictures" 2>/dev/null;
			rm "${wineUserDir}/Videos" 2>/dev/null;
			rm "${wineUserDir}/Templates" 2>/dev/null;

			# create empty folders for the "wineuser" personal folders
			mkdir -p "${wineUserDir}/Desktop" 2>/dev/null;
			mkdir -p "${wineUserDir}/Documents" 2>/dev/null;
			mkdir -p "${wineUserDir}/Downloads" 2>/dev/null;
			mkdir -p "${wineUserDir}/Music" 2>/dev/null;
			mkdir -p "${wineUserDir}/Pictures" 2>/dev/null;
			mkdir -p "${wineUserDir}/Videos" 2>/dev/null;
			mkdir -p "${wineUserDir}/Templates" 2>/dev/null;

			# create symlinks to the windows "pretty" versions of the "wineuser" personal folders
			ln -s "${wineUserDir}/Documents" "${wineUserDir}/My Documents";
			ln -s "${wineUserDir}/Music" "${wineUserDir}/My Music";
			ln -s "${wineUserDir}/Pictures" "${wineUserDir}/My Pictures";
			ln -s "${wineUserDir}/Videos" "${wineUserDir}/My Videos";

			if [[ -d "${wineUserDir}/Saved Games" ]]; then
				mv "${wineUserDir}/Saved Games" "${wineUserDir}/Games"
			else
				mkdir -p "${wineUserDir}/Games";
			fi
			ln -s "${wineUserDir}/Games" "${wineUserDir}/Saved Games";
			ln -s "${wineUserDir}/Games" "${wineUserDir}/Documents/Games";
			ln -s "${wineUserDir}/Games" "${wineUserDir}/Documents/My Games";
			ln -s "${wineUserDir}/Games" "${wineUserDir}/Documents/Saved Games";

			if [[ -d "${wineUserDir}/AppData" ]]; then
				if [[ -d "${wineUserDir}/Application Data" ]]; then
					mv "${wineUserDir}/Application Data" "${wineUserDir}/AppData/Roaming";
					ln -s "${wineUserDir}/AppData/Roaming" "${wineUserDir}/Application Data";
				fi

				if [[ -d "${wineUserDir}/Local Settings" ]]; then
					mv "${wineUserDir}/Local Settings" "${wineUserDir}/AppData/Local";
					ln -s "${wineUserDir}/AppData/Local" "${wineUserDir}/Local Settings";
				fi
			fi
		fi

		isSymlinksPackageInstalled=$(which $WHICH_OPTS symlinks 2>/dev/null|wc -l);
		if [[ 1 == ${isSymlinksPackageInstalled} ]]; then
			symlinks -cs "${wineSysDrive}/windows/system32" 2>&1 >/dev/null;
			if [[ -d "${wineSysDrive}/windows/syswow64" ]]; then
				symlinks -cs "${wineSysDrive}/windows/syswow64" 2>&1 >/dev/null;
			fi
			symlinks -cs "${wineAllUsersDir}" 2>&1 >/dev/null;
			symlinks -cs "${wineUserDir}" 2>&1 >/dev/null;
			symlinks -cs "${wineUserDir}/Documents" 2>&1 >/dev/null;
		fi

		# remove default "Z:" drive mapping, if it exists; no sense making system-wide access easy
		# this does NOT make it secure - programs CAN still access any folders that the linux user
		# account running the process can access. All this does is maybe make it very slightly more
		# difficult for a windows app to access the linux filesystem without intentionally trying to do so.
		#
		# https://forums.linuxmint.com/viewtopic.php?t=197097
		#
	#	if [[ -e "${newWinePrefixPath}/dosdevices/z:" ]]; then
	#		rm "${newWinePrefixPath}/dosdevices/z:";
	#	fi
		# https://bugs.winehq.org/attachment.cgi?id=65706
		# https://bugs.winehq.org/show_bug.cgi?id=48114
		# Disable unixfs
		# Unfortunately, when you run with a different version of Wine, Wine will recreate this key.
		# See https://bugs.winehq.org/show_bug.cgi?id=22450
	#	env WINEPREFIX="${newWinePrefixPath}" WINEARCH=win32 wine regedit /D 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace\{9D20AAE8-0625-44B0-9CA7-71889C2254D9}' 2>/dev/null;
	fi
}
function winetricksHere() {
	local foundValidWinePrefix='false';
	local startingDir=$(pwd);
	local winePrefixDir="${startingDir}";
	if [[ -d  "${winePrefixDir}/drive_c" ]]; then
		foundValidWinePrefix='true';
	else
		while [[ "false" == "${foundValidWinePrefix}" ]]; do
			if [[ -d  "${winePrefixDir}/drive_c" ]]; then
				foundValidWinePrefix='true';
				break;
			fi
			winePrefixDir=$(dirname "${winePrefixDir}");
			if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
				break;
			fi
		done;
	fi
	if [[ "false" == "${foundValidWinePrefix}" ]]; then
		echo "E: winetricksHere - Not under a valid WINEPREFIX folder.";
		return -1;
	fi
	env WINEDEBUG="fixme-all" WINEPREFIX="${winePrefixDir}" winetricks $1 $2 $3 $4 $5 $6 $7 $8 $9
}
function runWineCommandHere() {
	local wineCommand="$1";
	local fnName="runWineCommandHere";
	if [[ "" == "${wineCommand}" ]]; then
		echo "E: runWineCommandHere - no args";
		return -1;
	fi
	if [[ "" != "$2" ]]; then
		fnName="$2";
	fi

	local foundValidWinePrefix='false';
	local startingDir=$(pwd);
	local winePrefixDir="${startingDir}";
	if [[ -d  "${winePrefixDir}/drive_c" ]]; then
		foundValidWinePrefix='true';
	else
		while [[ "false" == "${foundValidWinePrefix}" ]]; do
			if [[ -d  "${winePrefixDir}/drive_c" ]]; then
				foundValidWinePrefix='true';
				break;
			fi
			winePrefixDir=$(dirname "${winePrefixDir}");
			if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
				break;
			fi
		done;
	fi
	if [[ "false" == "${foundValidWinePrefix}" ]]; then
		echo "E: ${fnName} - Not under a valid WINEPREFIX folder.";
		return -1;
	fi
	env WINEDEBUG="fixme-all" WINEPREFIX="${winePrefixDir}" wine ${wineCommand};
}
function wineCmdHere() {
	runWineCommandHere 'cmd' 'wineCmdHere'
}
function wineConfigHere() {
	runWineCommandHere 'winecfg' 'wineConfigHere'
}
function wineRegeditHere() {
	runWineCommandHere 'regedit' 'wineRegeditHere'
}
function goToWinePrefix() {
	local foundValidWinePrefix='false';
	local startingDir=$(pwd);
	local winePrefixDir="${startingDir}";
	if [[ -d  "${winePrefixDir}/drive_c" ]]; then
		foundValidWinePrefix='true';
	else
		while [[ "false" == "${foundValidWinePrefix}" ]]; do
			if [[ -d  "${winePrefixDir}/drive_c" ]]; then
				foundValidWinePrefix='true';
				break;
			fi
			winePrefixDir=$(dirname "${winePrefixDir}");
			if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
				break;
			fi
		done;
	fi
	if [[ "false" == "${foundValidWinePrefix}" ]]; then
		echo "E: goToWinePrefix - Not under a valid WINEPREFIX folder.";
		return -1;
	fi
	cd "${winePrefixDir}";
}
function printWinePrefix() {
	local foundValidWinePrefix='false';
	local startingDir=$(pwd);
	local winePrefixDir="${startingDir}";
	if [[ -d  "${winePrefixDir}/drive_c" ]]; then
		foundValidWinePrefix='true';
	else
		while [[ "false" == "${foundValidWinePrefix}" ]]; do
			if [[ -d  "${winePrefixDir}/drive_c" ]]; then
				foundValidWinePrefix='true';
				break;
			fi
			winePrefixDir=$(dirname "${winePrefixDir}");
			if [[ "/" == "${winePrefixDir}" || "" == "${winePrefixDir}" ]]; then
				break;
			fi
		done;
	fi
	if [[ "false" == "${foundValidWinePrefix}" ]]; then
		echo "E: printWinePrefix - Not under a valid WINEPREFIX folder.";
		return -1;
	fi
	echo "${winePrefixDir}";
}
#==========================================================================
# End Section: Wine functions
#==========================================================================

#==========================================================================
# Start Section: Administration functions
#==========================================================================
function fixSystemPermissions() {
	# This script is for fixing annoying permissions issues under
	# common system folders such as /etc, /opt, /usr, and /var
	# that might impact non-root uses ability to run things that they should
	# normally be able to run, even as non-root users

	local target='all';
	if [[ '' != "$1" && ( '--pip' == "$1" || '--dnf' == "$1" ) ]]; then
		target="$1";
	fi

	if [[ 'all' == "${target}" || 'pip' == "${target}" ]]; then
		# make sure sub-folders are readable to user + group + other
		sudo find /usr/lib/python* -type d -not -perm -ugo+rx -exec chmod ugo+rx "{}" \; 2>/dev/null

		# make sure all files are readable to user + group + other
		sudo find /usr/lib/python* -type f -not -perm -ugo+r -exec chmod ugo+r "{}" \; 2>/dev/null

		# make sure regular files are not executable - good security practice
		sudo find /usr/lib/python* -type f -perm /ugo+x -not \( -iname '*.sh' -o -iname '*.py' \) -exec chmod ugo-x "{}" \; 2>/dev/null

		# make sure scrip files *are* executable - bc pip is fucking retarded when it come to handling system installs
		sudo find /usr/lib/python* -type f -perm -ugo+x \( -iname '*.sh' -o -iname '*.py' \) -exec chmod ugo+x "{}" \; 2>/dev/null

		# fix broken / abandoned pip search function
		#	https://github.com/pypa/pip/issues/9312
		#	https://stackoverflow.com/questions/66375972/getting-error-with-pip-search-and-pip-install
		#
		# workaround:
		#	https://github.com/jeffmm/pypi-simple-search
		#
		#	or manually search at https://pypi.org/
		#
		if [[ 0 == $(getWhichCount pypi-simple-search) ]]; then
			local startingDir="$(pwd)";
			local tmpDir="$(mktemp -d /tmp/XXXX)";
			cd "${tmpDir}";
			git clone https://github.com/jeffmm/pypi-simple-search;

			if [[ -d pypi-simple-search/bin ]]; then
				cd pypi-simple-search/bin;
				for f in $(echo 'pip-pss pypi-simple-search'); do
					sudo cp -a "$f" "/usr/local/bin/$f";
					sudo chown root:root "/usr/local/bin/$f";
					sudo chmod 755 "/usr/local/bin/$f";
				done
			fi
			cd "${startingDir}";
		fi
	fi

	if [[ 'all' == "${target}" || 'dnf' == "${target}" ]]; then
		if [[ -d /var/cache/dnf ]]; then
			# When perms are set incorrectly in this folder, it can generate
			# unnecessary error output from running certain dnf commands as non-root
			# ex:
			#	$ ls -acl /var/cache/dnf/asbru*.solv*
			#	-rw-r-----. 1 root root   82 Mar  1 22:05 /var/cache/dnf/asbru-cm-release-filenames.solvx
			#	-rw-r-----. 1 root root 2246 Mar  1 22:05 /var/cache/dnf/asbru-cm-release-noarch-filenames.solvx
			#	-rw-r--r--. 1 root root 8650 Mar  1 23:39 /var/cache/dnf/asbru-cm-release-noarch.solv
			#	-rw-r--r--. 1 root root 6167 Mar  1 23:39 /var/cache/dnf/asbru-cm-release.solv
			#	-rw-r-----. 1 root root  231 Mar  1 22:05 /var/cache/dnf/asbru-cm-release-source-filenames.solvx
			#	-rw-r--r--. 1 root root 7605 Mar  1 23:39 /var/cache/dnf/asbru-cm-release-source.solv
			#
			#	$ dnf list --cacheonly asbru*
			#	Error: Cache-only enabled but no cache for 'asbru-cm-release'
			#	Error: Cache-only enabled but no cache for 'asbru-cm-release-noarch'
			#	Error: Cache-only enabled but no cache for 'asbru-cm-release-source'
			#
			#	Meanwhile, running the same 'dnf list' command from root does NOT
			#	generate any of this error output. 'dnf list' does not alter system packages
			#	or expose any keys so it should be allowed for non-root users to run it.
			#

			# make sure sub-folders are readable to user + group + other
			sudo find /var/cache/dnf -type d -not -perm -ugo+rx -exec chmod ugo+rx "{}" \; 2>/dev/null

			# make sure all files are readable to user + group + other
			sudo find /var/cache/dnf -type f -not -perm -ugo+r -exec chmod ugo+r "{}" \; 2>/dev/null
		elif [[ 'dnf' == "${target}" ]]; then
			echo "W: /var/cache/dnf not found; skipping";
		fi
	fi
}
function runCommandAsUser() {
	if [[ "" == "$1" || "" == "$2" ]]; then
		echo "expected usage:";
		echo "  runCommandAsUser USER COMMAND";
		echo "";
		echo "  If the command consists of arguments or otherwise";
		echo "  contains spaces, then it must be enclosed in quotes.";
		return -1;
	fi

	# "${@:2}" - all arguments except the first one
	su - "$1" -c "${@:2}"
}
function checkBIOSType() {
	if [[ -e /sys/firmware/efi ]]; then
		echo "OS has been booted using UEFI.";
	else
		echo "OS has been booted using Legacy BIOS.";
	fi
}
function checkOSVersionInfo() {
	local funcName='checkOSVersionInfo';
	case "$DISTRO_NAME" in
		# supported targets
		debian) isSupported=1 ;;
		fedora) isSupported=1 ;;
		lmde) isSupported=1 ;;
		mint) isSupported=1 ;;
		ubuntu) isSupported=1 ;;

		# fail
		*) [[ -n "$DISTRO_NAME" ]] && echo "E: $funcName does not currently support '$DISTRO_NAME' based distros.";
			[[ -z "$DISTRO_NAME" ]] && echo "E: '\$DISTRO_NAME' var not defined. Expected export from ~/.bashrc.";
			return -1;
			;;
	esac

	local isRecursive="$1";
	if [[ $isRecursive =~ ^\-[Rr]$ ]]; then
		isRecursive=1;
		shift 1;
	else
		isRecursive="$2";
		if [[ $isRecursive =~ ^\-[Rr]$ ]]; then
			isRecursive=1;
		else
			isRecursive=0;
		fi
	fi

	# if this distro is based on something else, a distro name can be passed in to indicate that info
	# on that specific base version is desired.
	# Examples:
	#	if on Linux Mint, you can pass 'mint', 'ubuntu', 'debian'
	#	if on LMDE, you can pass 'mint' or 'debian'
	#	if on Ubuntu, you can pass 'ubuntu' or 'debian'
	#	if on Fedora, you can pass only pass 'fedora'
	#
	local targetDistroName=$(echo "$1"|tr '[:upper:]' '[:lower:]');
	local isSupported=0;

	# check that passed version is supported by the function
	# and that the passed version is acceptable (matches detected base os)
	[[ -z "$targetDistroName" ]] && targetDistroName="$BASE_DISTRO";
	case "$targetDistroName" in
		debian) isSupported=1; isRecursive=0 ;;
		lmde) isSupported=1 ;;
		mint) isSupported=1 ;;
		ubuntu) isSupported=1 ;;
		fedora) isSupported=1; isRecursive=0 ;;

		# fail
		*) echo "E: $funcName does not currently support target '$targetDistroName'";
			return -1;
			;;
	esac
	local displayName="$(tr '[:lower:]' '[:upper:]' <<< ${targetDistroName:0:1})${targetDistroName:1}"

	#echo "targetDistroName: $targetDistroName, displayName: $displayName, isRecursive: $isRecursive";
	local osInfo=''
	case "$DISTRO_NAME" in
		# supported targets
		debian)
			if [[ "$DISTRO_NAME" == 'ubuntu' || "$DISTRO_NAME" == 'mint' ]]; then
				osInfo="CODENAME: $(cat /etc/lsb-release)";
				if [[ -n "$DEBIAN_VERSION" ]]; then
					osInfo="VERSION: $DEBIAN_VERSION, $osInfo";
				fi
			elif [[ "$DISTRO_NAME" == 'lmde' ]]; then
				osInfo="VERSION: $(cat /etc/lsb-release)";
				if [[ -n "$DEBIAN_CODENAME" ]]; then
					osInfo="$osInfo, CODENAME: $DEBIAN_CODENAME";
				fi
			else
				osInfo="$(cat /etc/debian_version)";
			fi
			;;
		fedora) osInfo="$(cat /etc/system-release)" ;;
		lmde)   osInfo="$(cat /etc/linuxmint/info)" ;;
		mint)	osInfo="$(cat /etc/linuxmint/info)" ;;
		ubuntu)
			if [[ "$DISTRO_NAME" == 'ubuntu' ]]; then
				osInfo="$(cat /etc/lsb-release)";
			else
				osInfo="$(cat /etc/upstream-release/lsb-release)";
			fi
			;;
	esac

	local sep='==========================================';
	printf '\n%s\n%s Info:\n%s\n%s\n' "$sep" "$displayName" "$sep" "$osInfo";

	if [[ $isRecursive -eq 1 ]]; then
		local upstreamTarget=''
		case "$targetDistroName" in
			lmde) upstreamTarget='debian' ;;
			mint) upstreamTarget='ubuntu' ;;
			ubuntu) upstreamTarget='debian' ;;

			# fail
			*) echo "E: $funcName - Unable to lookup upstream details for $targetDistroName";
				return -2;
				;;
		esac
		checkOSVersionInfo -R "$upstreamTarget"
	fi
}
function makeBackupWithTimestamp() {
	# defaultTsFormat = timestamp format if none is passed as an arg
	local defaultTsFormat="%Y-%m-%d-%H%M";
	local defaultDelim=".";

	# pattern format:
	#	%p - source path
	#	%t - timestamp (tsFormat if passed, otherwise fallback to defaultTsFormat)
	#	%d - short description (only used if passed as arg)
	#	%b - the bak extension (does not include dot)
	#
	# defaultBakFormat = pattern format if none is passed as an arg
	local defaultBakFormat="%p${defaultDelim}%t${defaultDelim}%b";
	local maxDescLength=40;

	local targetPath="$1";
	local tsFormat="$2";
	local bakFormat="$3";
	local shortDesc="$4";
	local showUsage='false';
	if [[ "" == "${targetPath}" ]]; then
		echo "E: No arguments.";
		showUsage='true';
	elif [[ "-h" == "${targetPath}" || "--help" == "${targetPath}" ]]; then
		showUsage='true';
	elif [[ "/" == "${targetPath}" ]]; then
		echo "E: Root path not allowed.";
		showUsage='true';
	elif [[ ! -e "${targetPath}" ]]; then
		echo "E: Path '${targetPath}' does not exist.";
		showUsage='true';
	elif [[ -L "${targetPath}" ]]; then
		echo "E: Path '${targetPath}' is a link.";
		showUsage='true';
	else
		# remove any trailing slash if one exists
		if [[ '/' == "${targetPath:${#targetPath}-1}" ]]; then
			targetPath="${targetPath:0:${#targetPath}-1}";
		fi

		# resolve any relative or weirdly constructed paths to absolute paths
		targetPath=$(realpath "${targetPath}" 2>/dev/null);
		if [[ "" == "${targetPath}" ]]; then
			echo "E: Unresolvable path.";
			showUsage='true';
		elif [[ "/" == "${targetPath}" ]]; then
			echo "E: Root path not allowed.";
			showUsage='true';
		elif [[ ! -e "${targetPath}" ]]; then
			echo "E: Path '${targetPath}' does not exist.";
			showUsage='true';
		elif [[ -L "${targetPath}" ]]; then
			echo "E: Path '${targetPath}' is a link.";
			showUsage='true';
		fi
	fi
	if [[ "true" == "${showUsage}" ]]; then
		echo "";
		echo "Expected usage:";
		echo "makeBackupWithTimestamp SOURCE_PATH";
		echo "makeBackupWithTimestamp SOURCE_PATH [tsFormat] [backupFormat] [desc]";
		echo "";
		echo "This will create a backup of the indicated path at: ";
		echo " '\${SOURCE_PATH}.yyyymmdd.HHMMSS.bak'";
		echo "";
		echo "SOURCE_PATH:  path to a file or a folder.";
		echo "   NOTE: Links are not supported.";
		echo "";
		echo "tsFormat:     timeformat for /bin/date";
		echo "   defaults to '${defaultTsFormat}'";
		echo "";
		echo "backupFormat: format for backup name, as follows:";
		echo "   %p - source path";
		echo "   %t - timestamp";
		echo "   %d - short description";
		echo "   %b - the bak extension (does not include dot)";
		echo "";
		echo "   defaults to '${defaultBakFormat}'";
		echo "";
		echo "desc:         short description of ${maxDescLength} chars or less.";
		echo " The description text can only contain alphanum, dot, plus, minus, and equals characters.";
		echo "";
		return 0;
	fi

	# check if the current user has write perms for a file or folder
	# https://askubuntu.com/questions/980658
	if [[ ! -w "${targetPath}" ]]; then
		# user does not own a file then
		# get sudo prompt out of the way before other messaging
		sudo ls -acl 2>/dev/null >/dev/null;
	fi

	# check backup name format
	if [[ "" == "${bakFormat}" ]]; then
		bakFormat="${defaultBakFormat}";
	elif [[ $bakFormat =~ ^.*[^-A-Za-z0-9.+=_%].*$ ]]; then
		# bad format; clear it and let it use default
		echo "W: Backup name format contains invalid characters; falling back to default."
		bakFormat="${defaultBakFormat}";
	else
		# when dealing with paths that contain more than just filename
		# require that %p must be used AND must appear only at the start
		if [[ $targetPath =~ ^.*\/.*$ ]]; then
			if [[ ! $bakFormat =~ ^%p.*$ || $bakFormat =~ ^..*%p.*$ ]]; then
				# bad format; clear it and let it use default
				echo "W: The passed source path contains /; In this case,the Backup name format must use %p and it must appear at the start of the pattern; falling back to default."
				bakFormat="${defaultBakFormat}";
			fi
		fi
		local testPattern=$(printf "%s" "${bakFormat}.%d"|sed 's/%[bdtp]//g');
		if [[ $testPattern =~ ^.*%.*$ ]]; then
			# bad format; clear it and let it use default
			echo "W: Backup name format contains invalid % escape sequences; falling back to default."
			bakFormat="${defaultBakFormat}";
		fi
	fi
	# check timestamp format
	if [[ "" != "${tsFormat}" ]]; then
		tsFormat=$(date +"${tsFormat}");
		if [[ "0" != "$?" || $tsFormat =~ ^.*[^-A-Za-z0-9.+=_].*$ ]]; then
			# bad format; clear it and let it use default
			echo "W: Bad timestamp format; falling back to default."
			tsFormat="";
		fi
	fi
	# set default timestamp format if none defined
	if [[ "" == "${tsFormat}" ]]; then
		tsFormat="${defaultTsFormat}";
	fi
	# check short description for spaces, invalid chars, length
	if [[ "" != "${shortDesc}" ]]; then
		if [[ $shortDesc =~ ^.*[^-.+=_A-Za-z0-9].*$ ]]; then
			shortDesc=$(printf "${shortDesc}"|sed 's/\s+/\-/g'|sed 's/[^-.+=_A-Za-z0-9]+//g');
		fi
		if (( ${#shortDesc} > $maxDescLength )); then
			shortDesc="${shortDesc:0:$maxDescLength}";
		fi
	fi
	local timeStamp=$(date +"${tsFormat}");

	# build backup name from pattern
	local backupPath=$(printf "%s" "${bakFormat}"|sed 's/%b/bak/g'|sed "s/%t/${timeStamp}/g");
	if [[ "" != "${shortDesc}" && $backupPath =~ ^.*%d.*$ ]]; then
		backupPath=$(printf "%s" "${backupPath}"|sed "s/%d/${shortDesc}/g");
	fi
	if [[ "%p" == "${backupPath:0:2}" ]]; then
		backupPath="${targetPath}${backupPath:2}";
	elif [[ $backupPath =~ ^.*%p.*$ ]]; then
		backupPath=$(printf "%s" "${backupPath}"|sed "s|%p|${targetPath}|g");
	fi

	# validate backup path
	if [[ $backupPath =~ ^.*%.*$ ]]; then
		echo "E: backupPath contains unexpanded strings.";
		echo "   backupPath: '${backupPath}'";
		echo "";
		echo "Aborting function call ...";
		return -1;
	fi

	# if backup path exists, try to see if numeric indexes of it exist...
	if [[ -e "${backupPath}" ]]; then
		for i in {2..9..1}; do
			if [[ ! -e "${backupPath}-${i}" ]]; then
				backupPath="${backupPath}-${i}";
				break;
			fi
		done
	fi

	# if not able to find a non-existing backup path then abort with error code
	if [[ -e "${backupPath}" ]]; then
		echo "E: backupPath already exists...";
		echo "   backupPath: '${backupPath}'";
		echo "";
		echo "Aborting function call ...";
		return -2;
	fi

	echo "Creating backup at: '${backupPath}' ...";
	# check if the current user has write perms for a file or folder
	# https://askubuntu.com/questions/980658
	if [[ ! -w "${targetPath}" ]]; then
		# user does not write perms for a file then
		sudo cp -a --no-clobber "${targetPath}" "${backupPath}";
	else
		cp -a --no-clobber "${targetPath}" "${backupPath}";
	fi
	if [[ "0" == "$?" ]]; then
		echo "-> SUCCESS";
	else
		echo "-> FAILURE";
	fi
}
function makeBackupWithDateOnly() {
	local path="$1";
	local bakFmt="$2";
	local comment="$3";
	if [[ "" == "${comment}" ]]; then
		makeBackupWithTimestamp "$path" '%Y-%m-%d' '%p.%t.%b';
	else
		makeBackupWithTimestamp "$path" '%Y-%m-%d' '%p.%t.%d.%b' "${comment}";
	fi
}
function makeBackupWithReadableTimestamp() {
	local path="$1";
	local bakFmt="$2";
	local comment="$3";
	if [[ "" == "${comment}" ]]; then
		makeBackupWithTimestamp "$path" '%Y-%m-%d-%H%M' '%p.%t.%b';
	else
		makeBackupWithTimestamp "$path" '%Y-%m-%d-%H%M' '%p.%t.%d.%b' "${comment}";
	fi
}
function makeBackupWithFullTimestamp() {
	local path="$1";
	local bakFmt="$2";
	local comment="$3";
	if [[ "" == "${comment}" ]]; then
		makeBackupWithTimestamp "$path" '%Y-%m-%d-%H%M%S' '%p.%t.%b';
	else
		makeBackupWithTimestamp "$path" '%Y-%m-%d-%H%M%S' '%p.%t.%d.%b' "${comment}";
	fi
}
function makeDirMine() {
	local FN_NAME="makeDirMine";
	local TARGET_DIR="$1";
	local RECURSIVE="false";
	if [[ "" != "$2" ]]; then
		if [[ "-R" == "$1" || "-r" == "$1" || "--recursive" == "$1" ]]; then
			TARGET_DIR="$2"
			RECURSIVE="true";
		elif [[ "-R" == "$2" || "-r" == "$2" || "--recursive" == "$2" ]]; then
			RECURSIVE="true";
		fi;
	fi
	if [[ "" == "${TARGET_DIR}" ]]; then
		echo "E: ${FN_NAME}: Missing target dir. Exiting function...";
		return -1;
	fi
	if [[ ! -e "${TARGET_DIR}" ]]; then
		echo "E: ${FN_NAME}: ${TARGET_DIR} does not exist. Exiting function...";
		return -2;
	fi
	if [[ "true" == "${RECURSIVE}" ]]; then
		sudo chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${TARGET_DIR}";
	else
		sudo chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${TARGET_DIR}";
	fi
}
function makeDirMineNonRecursively() {
	makeDirMine "$1";
}
function makeDirMineRecursively() {
	makeDirMine -R "$1";
}
function makeDirOnlyMineNonRecursively() {
	makeDirMine "$1";
	sudo chmod o-rwx "$1";
}
function makeDirOnlyMineRecursively() {
	makeDirMine -R "$1";
	sudo chmod -R o-rwx "$1";
}
#==========================================================================
# End Section: Administration functions
#==========================================================================

#==========================================================================
# Start Section: Hard Drive functions
#==========================================================================
function displayFstabDiskMountpoints() {
	#determine mount points as defined in /etc/fstab
	local mntpnts=$(awk -F'\\s+' '/^(UUID|\/dev\/).*/ {print $2}' /etc/fstab|tr '\n' '|');

	#remove trailing delim
	mntpnts="${mntpnts:0:${#mntpnts}-1}";

	# display disk mount points from df but filter to only things defined in fstab
	echo "Mounted fstab partitions from df -h:";
	echo "==========================================";
	df -h|grep -P "^.*(${mntpnts})$"|grep -Pv '^(tmpfs|/dev/loop|udev|/dev/sr0)';
}
function displayNonFstabDiskMountpoints() {
	#determine mount points as defined in /etc/fstab
	local mntpnts=$(awk -F'\\s+' '/^(UUID|\/dev\/).*/ {print $2}' /etc/fstab|tr '\n' '|');

	#remove trailing delim
	mntpnts="${mntpnts:0:${#mntpnts}-1}";

	# display disk mount points from df but filter out anything defined in fstab
	echo "Mounted non-fstab partitions from df -h:";
	echo "==========================================";
	# display disk mount points from df but filter out anything defined in fstab
	df -h|grep -Pv "^.*(${mntpnts})$"|grep -Pv '^(tmpfs|/dev/loop|udev|/dev/sr0)';

	echo "";
	echo "USB disks detected under /dev/disks/by-id:";
	echo "==========================================";
	ls -gG /dev/disk/by-id/|grep usb|awk -F' ' '{print $9"\t"$7}'|sed 's/^\.\.\/\.\./\/dev/';
}
function printAndSortByAvailableDriveSpace() {
	local sep="============================================================";
	printf '%s\n%s\n%s\n%s\n' "${sep}" "Drive Space as of $(date +'%a, %b %d @ %H:%M:%S')" "${sep}" "Filesystem      Size  Used Avail Use% Mounted on";

	# sort no suffix first (e.g. corresponds to bytes)
	df -h 2>/dev/null| grep -Pv '(/dev/loop|tmpfs|udev|/dev/sr0|Operation not permitted)'|awk -F'\\s+' '$4~/^([0-9][.0-9]*)$/ {print $0}'|sort -k4 -n

	# sort suffixes in increasing order
	local suffixOrder="K M G T";
	for suffix in $suffixOrder; do
		df -h 2>/dev/null| grep -Pv '(/dev/loop|tmpfs|udev|/dev/sr0|Operation not permitted)'|awk -F'\\s+' "\$4~/^([0-9][.0-9]*${suffix})\$/ {print \$0}"|sort -k4 -n;
	done
}
function printAndSortByMountPoint() {
	local secondColumnIndent='      '
	local longestFilesystem=$(mount 2>/dev/null|grep -P '//|/dev/sd|/media|/mnt'|awk -F'\\s+' '{print $1}'|awk ' { if ( length > x ) { x = length; y = $0 } }END{ print y }'|head -1);
	if [[ '' != "${longestFilesystem}" && ${#longestFilesystem} -gt 10 ]]; then
		if [[ $longestFilesystem =~ ^/dev/sd.*$ || $longestFilesystem =~ ^//.*$ ]]; then
			# make an overly long initial value and we'll trunctate to desired length
			secondColumnIndent='                                                       ';

			# find desired length:
			#	desiredLength = longestFilesystem + 2 spaces - len("Filesystem" str)
			#	desiredLength = longestFilesystem + 2 spaces - 10
			#	desiredLength = longestFilesystem - 8
			desiredLength=$(( ${#longestFilesystem} - 8 ));

			secondColumnIndent="${secondColumnIndent:0:${desiredLength}}";
		fi
	fi

	local sep="============================================================";
	local headerText="Filesystem${secondColumnIndent}Size  Used Avail Use% Mounted on";
	printf '%s\n%s\n%s\n%s\n' "${sep}" "Drive Space as of $(date +'%a, %b %d @ %H:%M:%S')" "${sep}" "${headerText}";

	df -h 2>/dev/null| grep -Pv '(/dev/loop|tmpfs|udev|/dev/sr0|Operation not permitted)'|awk -F'\\s+' '$4~/^([0-9].*)$/ {print $0}'|sort -k6;
}
function mountAllFstabEntries() {
	# first make sure all the auto mount stuff is mounted
	# this also doubles as a way to get the sudo prompt out
	# of the way up front
	sudo mount --all;
	sleep 1s;

	local fstabMountPointsArray=($(awk -F'\\s+' '/^\s*[^#].*\/media\/.*$/ {print $2}' /etc/fstab));
	local activeMountsArray=($(mount | awk -F'\\s+' '/^.*\/media\/.*$/ {print $3}'));
	local isAlreadyMounted="false";

	# now check for everything else; at this point it
	# should just be the entries with noauto
	for mountPoint in "${fstabMountPointsArray[@]}"; do
		isAlreadyMounted="false";
		for activeMount in "${activeMountsArray[@]}"; do
			if [[ "${activeMount}" == "${mountPoint}" ]]; then
				# set flag
				isAlreadyMounted="true";

				# exit inner loop
				break;
			fi
		done
		if [[ "true" == "${isAlreadyMounted}" ]]; then
			# already mounted; skip to next fstab entry
			continue;
		fi
		#echo "Attempting to mount ${mountPoint}";
		sudo mount "${mountPoint}" 2>/dev/null;
	done
}
function printDriveAndPartitionInfo() {
	# declare maps
	declare -A partitionToUUIDMap;
	declare -A partitionToLabelMap;
	declare -A partitionToTypeMap;
	declare -A UUIDtoMountPointMap;
	declare -A partitionToMountPointMap;
	declare -A partitionToTotalSizeMap;
	declare -A partitionToFreeSpaceeMap;
	declare -A partitionToUsedSpaceMap;
	declare -A hardDiskToModelMap;
	declare -A hardDiskToSizeMap;

	# get map of device path to hard drive model
	eval $(sudo parted --list --machine 2>/dev/null|grep -Pv 'BYT|sr0|zram0|^$|^\d'|gawk -F: '{print $1" \""$7"\""}'|sort -u|xargs -n 2 sh -c 'echo "hardDiskToModelMap[\"$1\"]=\"$2\""' argv0);

	# get map of device path to hard drive size
	eval $(eval echo $(sudo parted --list --machine 2>/dev/null|grep -Pv 'BYT|sr0|zram0|^$|^\d'|gawk -F: '{print $1" "$2}'|sed -E 's/([1-9][0-9]{3})GB/\$\(printf "%0.2f\\n" \$\(echo "\1\/1024"|bc -l))TB/g')|xargs -n 2 sh -c 'echo "hardDiskToSizeMap[\"$1\"]=\"$2\""' argv0);

	# get map of device paths to UUIDs
	eval $(sudo blkid|grep -P '^/dev/sd[a-z].*UUID'|sed -E 's|(/dev/sd[a-z][1-9]):.*\s+UUID=("[^"]+").*$|\1 \2|g'|sed -E 's|(/dev/sd[a-z][1-9]):.*\s+PARTUUID=("[^"]+").*$|\1 \2|g'|sort -u|xargs -n 2 sh -c 'echo "partitionToUUIDMap[\"$1\"]=\"$2\""' argv0);

	# get map of device paths to partition types
	eval $(sudo blkid|grep -P '^/dev/sd[a-z].*TYPE'|sed -E 's|(/dev/sd[a-z][1-9]):.*\s+TYPE=("[^"]+").*$|\1 \2|g'|sort -u|xargs -n 2 sh -c 'echo "partitionToTypeMap[\"$1\"]=\"$2\""' argv0);

	# get map of device paths to partition labels
	eval $(sudo blkid|grep -P '^/dev/sd[a-z].*LABEL'|sed -E 's|(/dev/sd[a-z][1-9]):.*\s+LABEL=("[^"]+").*$|\1 \2|g'|sed -E 's|(/dev/sd[a-z][1-9]):.*\s+PARTLABEL=("[^"]+").*$|\1 \2|g'|sort -u|xargs -n 2 sh -c 'echo "partitionToLabelMap[\"$1\"]=\"$2\""' argv0);

	# get map of device paths to mount points
	eval $(df -h|gawk -F'\\s+' '$1 ~ /^\/dev\/sd[a-z][1-9]$/ {print $1" "$6}'|sort -u|xargs -n 2 sh -c 'echo "partitionToMountPointMap[\"$1\"]=\"$2\""' argv0);

	# get map of device paths to total partition size
	eval $(eval echo $(sudo parted --list --machine 2>/dev/null|grep -Pv 'BYT|sr0'|sed -Ez 's|\n(/dev/sd[a-z])([1-9]?:[^\n]+)\n([1-9]:[^/\n]+)\n([1-9]:[^/\n]+)\n|\n\1\2\n\1\3\n\1\4\n|g'|grep -Pv 'BYT|sr0'|sed -Ez 's|\n(/dev/sd[a-z])([1-9]?:[^\n]+)\n([1-9]:[^/\n]+)\n([1-9]:[^/\n]+)\n|\n\1\2\n\1\3\n\1\4\n|g'|sed -Ez 's|\n?(/dev/sd[a-z])([1-9]?:[^\n]+)\n([1-9]:[^/\n]+)\n|\n\1\2\n\1\3\n|g'|sed -Ez 's|\n?(/dev/sd[a-z])([1-9]?:[^\n]+)\n([1-9]:[^/\n]+)\n|\n\1\2\n\1\3\n|g'|sed '/^$/d'|sed -E 's/^(\/dev\/sd\w:[^:]+):.*:(gpt|msdos):([^:]+):.*$/\1:\2:\3/g'|grep -P '/dev/sd\w[1-9]:'|sed -E 's/^(\/dev\/sd\w[1-9]):[^:]+:[^:]+:([^:]+):.*$/\1:\2/g'|sed -E 's/([1-9][0-9]{3})GB/\$\(printf "%0.2f\\n" \$\(echo "\1\/1024"|bc -l))T/g'|sed -E 's/([1-9][0-9]{3})kB/\$\(printf "%0.1f\\n" \$\(echo "\1\/1024"|bc -l))M/g'|sed -E 's/([GM])B$/\1/g')|tr ':' ' '|xargs -n 2 sh -c 'echo "partitionToTotalSizeMap[\"$1\"]=\"$2\""' argv0);
	eval $(df -h|gawk -F'\\s+' '$1 ~ /^\/dev\/sd[a-z][1-9]$/ {print $1" "$2}'|sort -u|xargs -n 2 sh -c 'echo "partitionToTotalSizeMap[\"$1\"]=\"$2\""' argv0);

	# get map of device paths to free space
	eval $(df -h|gawk -F'\\s+' '$1 ~ /^\/dev\/sd[a-z][1-9]$/ {print $1" "$4}'|sort -u|xargs -n 2 sh -c 'echo "partitionToFreeSpaceeMap[\"$1\"]=\"$2\""' argv0);

	# get map of device paths to used space
	eval $(df -h|gawk -F'\\s+' '$1 ~ /^\/dev\/sd[a-z][1-9]$/ {print $1" "$3}'|sort -u|xargs -n 2 sh -c 'echo "partitionToUsedSpaceMap[\"$1\"]=\"$2\""' argv0);

	# get maps of uuid to mount points
	eval $(gawk -F'\\s+' '$1 ~ /^UUID=/ {print $1" "$2}' /etc/fstab|sort -u|xargs -n 2 sh -c 'echo "UUIDtoMountPointMap[\"$1\"]=\"$2\""' argv0);

	# print entries
	local diskDevicePath='';
	local diskModel='';
	local diskCapacity='';
	local partitionDevicePath='';
	local uuid='';
	local label='';
	local fstype='';
	local mountPoint='';
	local totalSize='';
	local freeSpace='';
	local usedSpace='';

	for diskDevicePath in "${!hardDiskToModelMap[@]}"; do
		diskModel="${hardDiskToModelMap[$diskDevicePath]}";
		diskCapacity="${hardDiskToSizeMap[$diskDevicePath]}";

		echo "";
		echo "===============================================================================================";
		printf '%s Drive "%s" at %s\n' "${diskCapacity}" "${diskModel}" "${diskDevicePath}";
		echo "===============================================================================================";
		printf '%s\t%s\t%s\t%s\t%s\t%-22s\t%s\n' 'Filesystem' 'Type' 'Size' 'Used' 'Avail' 'Label' 'Mounted on'
		for i in {1..9}; do
			partitionDevicePath="${diskDevicePath}${i}";
			uuid="${partitionToUUIDMap[$partitionDevicePath]}";
			if [[ "" == "${uuid}" ]]; then
				continue;
			fi

			label="${partitionToLabelMap[$partitionDevicePath]}";
			fstype="${partitionToTypeMap[$partitionDevicePath]}";
			mountPoint="${partitionToMountPointMap[$partitionDevicePath]}";
			totalSize="${partitionToTotalSizeMap[$partitionDevicePath]}";
			freeSpace="${partitionToFreeSpaceeMap[$partitionDevicePath]}";
			usedSpace="${partitionToUsedSpaceMap[$partitionDevicePath]}";

			if [[ "" == "${mountPoint}" ]]; then
				mountPoint="${UUIDtoMountPointMap[$uuid]}";
			fi
			if [[ "" == "${mountPoint}" ]]; then
				mountPoint="<not mounted>";
			fi
			if [[ "Microsoft reserved partition" == "${label}" ]]; then
				label="Microsoft Reserved";
			fi
			printf '%s\t%s\t%s\t%s\t%s\t%-22s\t%s\n' "${partitionDevicePath}" "${fstype}" "${totalSize}" "${usedSpace}" "${freeSpace}" "${label:0:18}" "${mountPoint}";
		done
	done
}
function checkFileNamesValidForWindows() {
	local parentDir="$1";
	if [[ "" == "${parentDir}" || ! -d "${parentDir}" ]]; then
		echo "E: checkFileNamesValidForWindows(): Expected path to folder containing files to be checked.";
		return 501;
	fi

	local startingDir=$(pwd);
	echo "=======================================================================";
	echo "Checking for invalid Windows filenames under: ";
	echo "  '${parentDir}' ";
	echo "=======================================================================";

	cd "${parentDir}";

	echo '';
	echo '-----------------------------------------------------';
	printf 'Checking for basic invalid characters ... ';
	local matchCount=$(LC_ALL=C find . -name '*[:<>?|"*]*' -o -name '*\*' -o -name '*[! -~]*' | wc -l);
	printf 'Found %s occurrences: \n' "${matchCount}";

	if [[ 0 != ${matchCount} ]]; then
		# https://unix.stackexchange.com/questions/109747/identify-files-with-non-ascii-or-non-printable-characters-in-file-name
		# https://www.asciitable.com/
		LC_ALL=C find . -name '*[:<>?|"*]*' -o -name '*\*' -o -name '*[! -~]*' | sort;
	fi
	echo '-----------------------------------------------------';

	echo '';
	echo '-----------------------------------------------------';
	printf '\nChecking for Invalid Spacing ... \n';
	local countA=$(LC_ALL=C find . -iregex '^.*/ .*$' -o -iregex '^.* /.*$'|wc -l);
	local countB=$(LC_ALL=C find . -type f -iregex '^.* \.[A-Za-z0-9][A-Za-z0-9]*'|wc -l);
	matchCount=$(( $countA + $countB ));
	printf 'Found %s leading spaces and %s trailing spaces: \n' "${countA}" "${countB}";

	if [[ 0 != ${matchCount} ]]; then
		LC_ALL=C find . -iregex '^.*/ .*$' -o -iregex '^.* /.*$'|sort;
		LC_ALL=C find . -type f -iregex '^.* \.[A-Za-z0-9][A-Za-z0-9]*'|sort;
	fi
	echo '-----------------------------------------------------';

	#echo '';
	#echo '-----------------------------------------------------';
	#printf 'Checking for non-printable characters ... ';
	#printf 'Found %s occurrences: \n' $(LC_ALL=C find . -exec grep -l '[^[:print:]]' "{}" \; | wc -l);
	# https://unix.stackexchange.com/questions/350990/searching-files-containing-non-ascii-characters
	#LC_ALL=C find . -exec grep -l '[^[:print:]]' "{}" \;| sort;
	#echo '-----------------------------------------------------';

	# Ignore starting path because e.g. '/media/myusb-drive' would, under Windows,
	# be mounted as e.g. 'F:\'. Length should be calculated as:
	# A) Absolute Path (e.g. '/media/myusb-drive/foo.txt'), minus the
	#		parent path (e.g. '/media/myusb-drive'), plus 2 (letter + colon)
	# OR more simply:
	# B) Relative unix path (e.g. './media/myusb-drive/foo.txt'), minus one (leading dot),
	#	plus 2 (letter + colon)
	# OR even more simply
	# C) Relative unix path (e.g. './media/myusb-drive/foo.txt'),
	#	plus 1 (letter + colon minus the leading dot from unix relative path)
	#
	# SO we can start with the "Max Windows Path (Under FAT)" as 255
	# then subtract 1 (254) to find the Max Relative Path size under unix
	# that will successfully work on a FAT partition.
	# Then add one to (255) find paths that are too long.

	echo '';
	echo '-----------------------------------------------------';
	printf '\nChecking for invalid path length ... ';
	matchCount=$(LC_ALL=C find .|grep -Pc '^.{255,}$');
	printf 'Found %s paths that are too long for FAT partitions (max 255 chars*): \n' "${matchCount}";
	if [[ 0 != ${matchCount} ]]; then
		LC_ALL=C find .|grep -P '^.{255,}$'|sort
	fi
	echo '-----------------------------------------------------';

	printf '\n\n*Note: this includes the drive letter and colon added by Windows.\n\n';

	cd "${startingDir}";
}
function removeInvalidCharactersFromFileNames() {
	local typeList='d f';
	local separator='=========================================================';

	declare -A windowsInvalidCharactersMap;
	windowsInvalidCharactersMap["\""]="s/\"//g";
	windowsInvalidCharactersMap[":"]="s/://g";
	windowsInvalidCharactersMap["[?]"]="s/[?]//g";
	windowsInvalidCharactersMap["[*]"]="s/[*]//g";
	windowsInvalidCharactersMap[">"]="s/>//g";
	windowsInvalidCharactersMap["<"]="s/<//g";
	windowsInvalidCharactersMap["[\\\\]"]="s/[\\\\]//g";
	windowsInvalidCharactersMap["[|]"]="s/[|]//g";
	windowsInvalidCharactersMap["[\`]"]="s/[\`]/'/g";

	local typeName='';
	printf '%s\n%s\n%s\n' "${separator}" "Checking for invalid Windows characters:" "${separator}";
	for type in $typeList; do
		#echo "type: $type";
		if [[ 'd' == "${type}" ]]; then
			typeName='Dir';
		else
			typeName='File';
		fi

		for invalidCharacter in "${!windowsInvalidCharactersMap[@]}"; do
			#echo "invalidCharacter: $invalidCharacter";
			replacePattern="${windowsInvalidCharactersMap[$invalidCharacter]}";
			#echo "replacePattern: $replacePattern";

			printf '%s: Checking for character %s in name ... \n' "${typeName}" "'${invalidCharacter}'";
			find . -type ${type} -iname "*${invalidCharacter}*" -exec prename "${replacePattern}" "{}" \; 2>/dev/null;
		done

		# moving this one outside the loop as it can sometimes cause issues when bash interprets as a non-literal character
		printf '%s: Checking for exclaimation point character in name ... \n' "${typeName}";
		find . -type ${type} -iname '*!*' -exec prename 's/!//g' "{}" \; 2>/dev/null;
	done

	declare -A unicodeCharactersReplacementMap;
	unicodeCharactersReplacementMap["¡"]="s/¡//g";
	unicodeCharactersReplacementMap["«"]="s/«/[/g";
	unicodeCharactersReplacementMap["®"]="s/®//g";
	unicodeCharactersReplacementMap["™"]="s/™//g";
	unicodeCharactersReplacementMap["´"]="s/´/'/g";
	unicodeCharactersReplacementMap["»"]="s/»/]/g";
	unicodeCharactersReplacementMap["¿"]="s/¿//g";
	unicodeCharactersReplacementMap["ß"]="s/ß/ss/g";
	unicodeCharactersReplacementMap["à"]="s/à/a/g";
	unicodeCharactersReplacementMap["á"]="s/á/a/g";
	unicodeCharactersReplacementMap["â"]="s/â/a/g";
	unicodeCharactersReplacementMap["ä"]="s/ä/a/g";
	unicodeCharactersReplacementMap["å"]="s/å/a/g";
	unicodeCharactersReplacementMap["è"]="s/è/e/g";
	unicodeCharactersReplacementMap["é"]="s/é/e/g";
	unicodeCharactersReplacementMap["ê"]="s/ê/e/g";
	unicodeCharactersReplacementMap["ë"]="s/ë/e/g";
	unicodeCharactersReplacementMap["í"]="s/í/i/g";
	unicodeCharactersReplacementMap["ï"]="s/ï/i/g";
	unicodeCharactersReplacementMap["ñ"]="s/ñ/n/g";
	unicodeCharactersReplacementMap["ó"]="s/ó/o/g";
	unicodeCharactersReplacementMap["ô"]="s/ô/o/g";
	unicodeCharactersReplacementMap["Ö"]="s/Ö/O/g";
	unicodeCharactersReplacementMap["ö"]="s/ö/o/g";
	unicodeCharactersReplacementMap["Ø"]="s/Ø/0/g";
	unicodeCharactersReplacementMap["ú"]="s/ú/u/g";
	unicodeCharactersReplacementMap["ü"]="s/ü/u/g";
	unicodeCharactersReplacementMap["ō"]="s/ō/o/g";
	unicodeCharactersReplacementMap["й"]="s/й/n/g";
	unicodeCharactersReplacementMap["к"]="s/к/k/g";
	unicodeCharactersReplacementMap["о"]="s/о/o/g";
	unicodeCharactersReplacementMap["п"]="s/п/n/g";
	unicodeCharactersReplacementMap["ґ"]="s/ґ/r/g";
	unicodeCharactersReplacementMap["–"]="s/\\s*–\\s*/ - /g";
	unicodeCharactersReplacementMap["–"]="s/\\s*–\\s*/ - /g";
	unicodeCharactersReplacementMap["‘"]="s/‘/'/g";
	unicodeCharactersReplacementMap["’"]="s/’/'/g";
	unicodeCharactersReplacementMap["…"]="s/…/ /g";
	unicodeCharactersReplacementMap["…"]="s/…/ /g";
	unicodeCharactersReplacementMap["“"]="s/“//g";
	unicodeCharactersReplacementMap["”"]="s/”//g";

	printf '%s\n%s\n%s\n' "${separator}" "Checking for unicode characters:" "${separator}";
	for type in $typeList; do
		#echo "type: $type";
		if [[ 'd' == "${type}" ]]; then
			typeName='Dir';
		else
			typeName='File';
		fi

		for unicodeCharacter in "${!unicodeCharactersReplacementMap[@]}"; do
			#echo "unicodeCharacter: $unicodeCharacter";
			replacePattern="${unicodeCharactersReplacementMap[$unicodeCharacter]}";
			#echo "replacePattern: $replacePattern";

			printf '%s: Checking for unicode character %s in name ... \n' "${typeName}" "'${unicodeCharacter}'";
			find . -type ${type} -iname "*${unicodeCharacter}*" -exec prename "${replacePattern}" "{}" \; 2>/dev/null;
		done

		printf '%s: Replacing all other misc unicode characters in name ... \n' "${typeName}";
		ALL=C find . -type ${type} -name '*[! -~]*' -exec prename 's/[^ -~]//g' "{}" \; 2>/dev/null;
	done

	printf '%s\n%s\n%s\n' "${separator}" "Checking for leading/trailing spaces:" "${separator}";
	for type in $typeList; do
		#echo "type: $type";
		if [[ 'd' == "${type}" ]]; then
			typeName='Dir';
		else
			typeName='File';
		fi

		printf '%s: Checking for leading spaces/dots/underscores in name ... \n' "${typeName}";
		find . -type ${type} -iregex '^.*/[. _][^/]*$' -exec prename 's/^(.*\/)[\s_\.]+(.+)$/$1$2/g' "{}" \; 2>/dev/null;

		printf '%s: Checking for trailing spaces/dots/underscores in name ... \n' "${typeName}";
		find . -type ${type} -name '*[. _]' -exec prename 's/^(.+[^\s_\.])[\s_\.]+$/$1/g' "{}" \; 2>/dev/null;
	done
	# and for trailing spaces/dots/underscores BEFORE the file extension
	find . -type f -name '*[. _].*' -exec prename 's/^(.+[^\s_\.])[\s_\.]+(\.\w+)$/$1$2/g' "{}" \; 2>/dev/null;
}
#==========================================================================
# End Section: Hard Drive functions
#==========================================================================

#==========================================================================
# Start Section: Network functions
#==========================================================================
function getGbUsedThisSession() {
	local ethernetInterface=$(ip -4 -o -br addr|grep -P '^[e]\w+\d+\b'|head -1|gawk -F'\\s+' '{print $1}');
	local ethernetBytes=0;
	if [[ '' != "${ethernetInterface}" ]]; then
		ethernetBytes=$(cat "/sys/class/net/${ethernetInterface}/statistics/rx_bytes");
	fi

	local wifiInterface=$(ip -4 -o -br addr|grep -P '^[w]\w+\d+\b'|head -1|gawk -F'\\s+' '{print $1}');
	local wifiBytes=0;
	if [[ '' != "${wifiInterface}" ]]; then
		wifiBytes=$(cat "/sys/class/net/${wifiInterface}/statistics/rx_bytes");
	fi

	local vpnBytes=$(cat "/sys/class/net/tun0/statistics/rx_bytes");
	local totalBytes=$(echo "${ethernetBytes} + ${vpnBytes} + ${wifiBytes}"|bc -l)
	local totalGB=$(printf "%.2f" $(echo "${totalBytes} / 1024 / 1024 / 1024 "|bc -l));

	echo "Total GB used since PC was started: ${totalGB} GB";
}
function isValidIpAddr() {
	# return code only version
	local ipaddr="$1";
	[[ ! $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && return 1;
	for quad in $(echo "${ipaddr//./ }"); do
		(( $quad >= 0 && $quad <= 255 )) && continue;
		return 1;
	done
}
function validateIpAddr() {
	# return code + output version
	local ipaddr="$1";
	local errmsg="E: $1 is not a valid IP address";
	[[ ! $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && echo "$errmsg" && return 1;
	for quad in $(echo "${ipaddr//./ }"); do
		(( $quad >= 0 && $quad <= 255 )) && continue;
		echo "$errmsg";
		return 1;
	done
	echo "SUCCESS: $1 is a valid IP address";
}
function mountWindowsNetworkShare() {
	if [[ 'debian' != "${BASE_DISTRO}" && 'fedora' != "${BASE_DISTRO}" ]]; then
		echo "E: mountWindowsNetworkShare() has not been updated to work with ${BASE_DISTRO}-based distros.";
		return -1;
	fi

	local networkPath="$1";
	local mountPoint="$2";
	local remoteLogin="$3";
	local remotePassword="$4";

	# validate input
	local showUsage="false";
	if [[ "-h" == "$1" || "--help" == "$1" ]]; then
		showUsage="true";

	elif [[ "" == "${networkPath}" ]]; then
		echo "E: REMOTE_PATH is empty";
		showUsage="true";

	elif [[ "" == "${mountPoint}" ]]; then
		echo "E: LOCAL_PATH is empty";
		showUsage="true";

	elif [[ ! $mountPoint =~ ^[~.]?\/.*$ || $mountPoint =~ ^\/\/.*$ ]]; then
		echo "E: LOCAL_PATH must be a valid local path";
		showUsage="true";

	elif [[ "" == "${remoteLogin}" ]]; then
		echo "E: REMOTE_USER is empty";
		showUsage="true";

	elif [[ "" == "${remotePassword}" ]]; then
		echo "E: REMOTE_PWD is empty";
		showUsage="true";
	fi

	# secondary validations
	if [[ "false" == "${showUsage}" ]]; then
		# get sudo prompt out of the way
		sudo ls -acl 2>/dev/null >/dev/null;

		# canonicalize network path
		if [[ "//" != "${networkPath:0:2}" ]]; then
			networkPath="//${networkPath}";
		fi

		# Make sure network path is of the format:
		#	HOST/SHARE
		#
		# Where REMOTE_HOST is either a valid HOST or a valid IP_ADDR
		local remoteHost=$(printf "${networkPath}"|sed -E 's|^//([^/]+)/.*$|\1|g');
		local shareName=$(printf "${networkPath}"|sed -E 's|^//[^/]+/(.*)$|\1|g');

		if [[ "${#networkPath}" == "${#remoteHost}" || "0" == "${#remoteHost}" || "${#networkPath}" == "${#shareName}" || "0"  == "${#shareName}" ]]; then
			echo "E: REMOTE_PATH is invalid. It should be in the form: //IPADDR/SHARE_NAME";
			showUsage="true";

		elif [[ $shareName =~ ^.*[^\-A-Za-z0-9_\.\+\=\ \~\%\@\#\(\)\&].*$ ]]; then
			echo "E: REMOTE_PATH is invalid. shareName '${shareName}' contains invalid characters.";
			showUsage="true";

		elif [[ $remoteHost =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
			# definitely *supposed* to be an ip address
			# check if it is a *valid* ip address (correct numerical ranges)

			# check that each ip quad is with the range 0 to 255
			isValidIpAddr "$remoteHost";
			if [[ "0" != "$?" ]]; then
				echo "E: REMOTE_PATH is invalid. host '${remoteHost}' is not a valid ip address.";
				showUsage="true";
			fi

		elif [[ $remoteHost =~ ^[A-Za-z][\-A-Za-z0-9_\.]*$ ]]; then
			# host names are only allowed if the system supports
			# resolving hostnames...
			local supportsHostNameResolution="true";
			if [[ ! -f /etc/nsswitch.conf ]]; then
				echo "W: Missing /etc/nsswitch.conf; will not be able to resolve Windows host names...";
				supportsHostNameResolution="false";
			else
				local winbindPkgCount=0;
				if [[ 'debian' == "${BASE_DISTRO}" ]]; then
					winbindPkgCount=$(apt search winbind | grep -P "^i\s+(winbind|libnss-winbind)\s+"|wc -l);
				fi
				if (( $winbindPkgCount < 2 )); then
					echo "W: Missing winbind / libnss-winbind packages; will not be able to resolve Windows host names...";
					supportsHostNameResolution="false";
				fi
			fi

			if [[ "false" == "${supportsHostNameResolution}" ]]; then
				echo "E: REMOTE_PATH is invalid; system doesn't support resolution of named host '${remoteHost}'.";
				echo "";
				echo "Use IP address instead or update system to support host name resolution.";
				echo "See:";
				echo "   https://www.techrepublic.com/article/how-to-enable-linux-machines-to-resolve-windows-hostnames/";
				echo "   https://askubuntu.com/a/516533/1003652";
				showUsage="true";

				echo "";
				echo "Attempting to resolve for next time ...";

				requiredPackages='winbind libnss-winbind';

				if [[ -f /usr/bin/dnf ]]; then
					requiredPackages='samba-winbind cifs-utils';
					installCommand="Please run: sudo dnf install -y ${requiredPackages}";
					sudo dnf install -y ${requiredPackages} 2>/dev/null >/dev/null;

				elif [[ -f /usr/bin/apt-get ]]; then
					requiredPackages='winbind libnss-winbind';
					installCommand="Please run: sudo apt-get install -y ${requiredPackages}";
					sudo apt-get install -y ${requiredPackages} 2>/dev/null >/dev/null;

				else
					installCommand="Please install the following packages: ${requiredPackages}";
				fi
			else
				local unresolvedHostChk=$(ping -c 1 "$remoteHost" 2>&1 | grep 'Name or service not known'|wc -l);
				if [[ "0" == "${unresolvedHostChk}" ]]; then
					echo "E: REMOTE_PATH is invalid; system was unable to resolve named host '${remoteHost}'.";
					echo "";
					echo "Use IP address instead or update system to support host name resolution.";
				fi
			fi
		fi
	fi

	if [[ "true" == "${showUsage}" ]]; then
		echo "";
		echo "Expected usage:";
		echo "mountWindowsNetworkShare REMOTE_PATH LOCAL_PATH REMOTE_USER REMOTE_PWD";
		echo "";
		echo "Mounts the indicated path, if it is not already mounted.";
		echo "";
		echo "REMOTE_PATH must be in the form: //IPADDR/SHARE_NAME";
		echo "";
		echo "LOCAL_PATH  must be a valid local path.";
		echo "";
		echo "REMOTE_USER should be the user name on the remote machine. If it contains spaces, pass in quotes.";
		echo "";
		echo "REMOTE_PWD should be the user password on the remote machine. This should always be passed in quotes. Additionally, special characters should be preceded by a backslash (\\) when using double-quotes. Especially:";
		echo " * dollar sign (\$)";
		echo " * backslash (\\)"
		echo " * backtick (\`)";
		echo " * double-quote (\")";
		echo " * exclaimation mark (!)";
		echo " * all special characters may be escaped but the above are required.";
		echo "";
		return 0;
	fi

	local isAlreadyMounted=$(mount|grep -P "${mountPoint}"|wc -l);
	if [[ "0" != "${isAlreadyMounted}" ]]; then
		echo "E: '${mountPoint}' is already mounted."
		return -1;
	fi

	if [[ ! -e "${mountPoint}" ]]; then
		sudo mkdir "${mountPoint}";
		sudo chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "${mountPoint}";
	fi
	echo "Attempting to mount '${networkPath}' at '${mountPoint}' ...";
	sudo mount -t cifs "${networkPath}" "${mountPoint}" -o "user=${remoteLogin},username=${remoteLogin},password=${remotePassword},dir_mode=0777,file_mode=0777";
	if [[ "0" == "$?" ]]; then
		echo "-> SUCCESS";
	else
		echo "-> FAILURE";
	fi
}
function unmountWindowsNetworkShare() {
	local mountPoint="$1";

	# validate input
	if [[ "" == "${mountPoint}" ]]; then
		echo "E: local mountPoint is empty";
		echo "Expected usage:";
		echo "unmountWindowsNetworkShare /local/path/to/mount/point";
		echo "";
		echo "   unmounts the indicated path, if it is mounted.";
		echo "";
		return -1;
	fi

	# check if mounted
	local isAlreadyMounted=$(mount|grep -P "${mountPoint}"|wc -l);
	if [[ "0" == "${isAlreadyMounted}" ]]; then
		echo "E: '${mountPoint}' is not currently mounted."
		return -2;
	fi
	echo "Attempting to unmount '${mountPoint}' ...";
	sudo umount --force "${mountPoint}";
	if [[ "0" == "$?" ]]; then
		echo "-> SUCCESS";
	else
		echo "-> FAILURE";
	fi
}
function displayGatewayIp() {
	ip r|grep default|grep -v tun0|sed -E 's/^.*\b([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\b.*$/\1/g';
}
export -f displayGatewayIp;
function displayNetworkHostnames() {
	local gatewayIp=$(ip r|grep -v tun|grep default|sed -E 's/^.*\b([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\b.*$/\1/g');

	echo "IP Address    Hostname";
	local ipAddr='';
	for ipAddr in $(arp -vn|grep -P '^\d'|grep -Pv "\\b(${gatewayIp})\\b" |awk -F'\\s+' '{print $1}'); do
		local hostName=$(nmblookup -A "${ipAddr}"|grep -Pvi '(Looking|No reply|<GROUP>|MAC Address)'|grep -i '<ACTIVE>'|head -1|sed -E 's/^\s+(\S+)\s*.*$/\1/');
		echo "${ipAddr}    ${hostName}";
	done
}
function printNetworkType() {
	local inetType=0;
	if [[ 0 != $(ip -4 -o -br addr|grep -Pc '^tun\d+') ]]; then
		inetType='v';
	else
		inetType=$(ip -4 -o -br addr|grep -P '^[we]\w+\d+\b'|head -c 1);
	fi
	case "${inetType}" in
		v) inetType=vpn ;;
		e) inetType=ethernet ;;
		w) inetType=wifi ;;
		*) inetType=unknown ;;
	esac
	echo "Connected to internet via: ${inetType}";
}
function scanAllOnLocalNetwork() {
	# get gateway ip address - this way we're not hard-coding a specific IP range and
	# it is more portable when using on other networks
	if [[ 1 != $(displayGatewayIp|wc -l) ]]; then
		echo "E: Multiple gateway ip addresses detected. Update function displayGatewayIp.";
		return -1;
	fi
	local gatewayIp=$(displayGatewayIp);
	if [[ '' == "${gatewayIp}" ]]; then
		echo "E: No gateway ip v4 address detected. Update function displayGatewayIp.";
		return -2;

	elif [[ ! $gatewayIp =~ ^[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*$ ]]; then
		echo "E: Invalid gateway ip v4 address detected: '${gatewayIp}'. Update function displayGatewayIp.";
		return -3;

	elif [[ $gatewayIp =~ ^.*([1-9][0-9][0-9][0-9]|[3-9][0-9][0-9]|2[6-9][0-9]|25[6-9]).*$ ]]; then
		echo "E: Invalid gateway ip v4 address range detected: '${gatewayIp}'. Update function displayGatewayIp.";
		return -4;
	fi

	echo "Router/Gateway ip v4 addr:  ${gatewayIp}";

	local localIpAddr=$(ip -4 -o -br addr|grep -P '^[we]\w+\s+UP\b'|gawk '{print $3}'|cut -d/ -f1);
	if [[	! $localIpAddr =~ ^[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*$ || \
			 $localIpAddr =~ ^.*([1-9][0-9][0-9][0-9]|[3-9][0-9][0-9]|2[6-9][0-9]|25[6-9]).*$ ]]; then

		echo "E: Invalid local ip v4 address detected: '${localIpAddr}'. Update function displayGatewayIp.";
		return -5;
	fi

	local nmapOpts="--exclude ${localIpAddr}";
	echo "This computer's ip v4 addr: ${localIpAddr}";
	echo "";

	echo 'Scanning for all other LAN IPs...';
	echo 'Press Ctrl+C to cancel.';
	echo '';
	nmap -sn "${gatewayIp}/24" ${nmapOpts} | \
	grep -Pv 'MAC Address|latency|Starting Nmap|Nmap done'|\
	grep -Pv "${gatewayIp}"|\
	sed -E 's/^.*[^0-9]([1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*)\b.*$/\1/g'
}
function scanPortOnLocalNetwork() {
	# get gateway ip address - this way we're not hard-coding a specific IP range and
	# it is more portable when using on other networks
	if [[ 1 != $(displayGatewayIp|wc -l) ]]; then
		echo "E: Multiple gateway ip addresses detected. Update function displayGatewayIp.";
		return -1;
	fi
	local gatewayIp=$(displayGatewayIp);
	if [[ '' == "${gatewayIp}" ]]; then
		echo "E: No gateway ip v4 address detected. Update function displayGatewayIp.";
		return -2;

	elif [[ ! $gatewayIp =~ ^[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*$ ]]; then
		echo "E: Invalid gateway ip v4 address detected: '${gatewayIp}'. Update function displayGatewayIp.";
		return -3;

	elif [[ $gatewayIp =~ ^.*([1-9][0-9][0-9][0-9]|[3-9][0-9][0-9]|2[6-9][0-9]|25[6-9]).*$ ]]; then
		echo "E: Invalid gateway ip v4 address range detected: '${gatewayIp}'. Update function displayGatewayIp.";
		return -4;
	fi

	echo "Router/Gateway ip v4 addr:  ${gatewayIp}";

	local localIpAddr=$(ip -4 -o -br addr|grep -P '^[we]\w+\s+UP\b'|gawk '{print $3}'|cut -d/ -f1);
	if [[	! $localIpAddr =~ ^[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*$ || \
			 $localIpAddr =~ ^.*([1-9][0-9][0-9][0-9]|[3-9][0-9][0-9]|2[6-9][0-9]|25[6-9]).*$ ]]; then

		echo "E: Invalid local ip v4 address detected: '${localIpAddr}'. Update function displayGatewayIp.";
		return -5;
	fi

	local nmapOpts="--exclude ${localIpAddr}";
	echo "This computer's ip v4 addr: ${localIpAddr}";
	echo "";

	local port="$1";
	if [[ ! $port =~ ^[1-9][0-9]*$ &&
		! $port =~ ^[1-9][-0-9,]*[0-9]$ ]]; then
		echo "E: '$port' is not a valid port."
		return -6;
	fi

	echo "Scanning LAN IPs for open port on $port ...";
	echo 'Press Ctrl+C to cancel.';
	echo '';
	nmap -p $port "${gatewayIp}/24" ${nmapOpts} --open | \
	grep -Pv 'MAC Address|latency|Starting Nmap|Nmap done|^\s*$'|\
	grep -Pv "${gatewayIp}"|\
	grep -Pv 'tcp|udp|PORT.*STATE.*SERVICE'|\
	grep -Pv 'Not shown'|\
	sed -E 's/^.*[^0-9]([1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*\.[1-9][0-9]*)\b.*$/\1/g'
	echo ''
}
#==========================================================================
# End Section: Network functions
#==========================================================================

#==========================================================================
# Start Section: Package Management functions
#==========================================================================
function aptToDnfWrapper() {
#	https://www.rootusers.com/25-useful-dnf-command-examples-for-package-management-in-linux/
#	https://embeddedinventor.com/dnf-vs-apt-similarities-and-differences-analyzed/
#	https://www.digitalocean.com/community/tutorials/package-management-basics-apt-yum-dnf-pkg
#	https://www.ubuntubuzz.com/2017/03/comparison-of-common-commands-ubuntu-ubuntu-apt-fedora-dnf.html
#
#	samples
#	dnf install httpd               :       apt-get install package
#	dnf install package -y          :       apt-get install -y package OR apt-get install package -y
#	dnf check-update                :       apt-get update

	echo "Hey Dumbass, did you mean to use 'dnf' instead of 'apt'?";

	# Evaluate each passed arg. don't allow anything more complicated than -y and package names with hyphens
	local hasSimpleArgs="true";
	for passedArg in "${@}"; do
		[[ "" == "${passedArg}" || "-y" == "${passedArg}" ]] && continue; # ignore
		[[ $passedArg =~ ^[A-Za-z0-9][A-Za-z0-9]*$ || $passedArg =~ ^[A-Za-z0-9][-A-Za-z0-9.:]*[A-Za-z0-9]$ ]] && continue; # ignore
		hasSimpleArgs="false";
	done

	local commandVerb="$1";
	if [[ "true" == "${hasSimpleArgs}" ]]; then
		case "$commandVerb" in
			# simple commands that are very similar
			install) commandVerb="install" ;;
			list) commandVerb="list" ;;
			purge) commandVerb="erase" ;;  # note dnf remove is deprecated
			search)  commandVerb="search all" ;;
			show)  commandVerb="info" ;;
			update)  commandVerb="check-update" ;;
			upgrade)  commandVerb="upgrade" ;;

			# more complex commands or ones that are not very similar
			remove) commandVerb="erase";  # note dnf remove is deprecated
				echo "W: 'apt remove' keeps config files; 'dnf erase' does not.";
				;;

			*)
				commandVerb='';
				;;
		esac
	fi

	if [[ "true" != "${hasSimpleArgs}" || "" == "${commandVerb}" ]]; then
		echo "RTFM; This command or argument isn't recognized or is non-trivial to map.";
		return 404;
	fi
	echo dnf "${@}";
}
function aptToPacmanWrapper() {
	echo "Hey Dumbass: Did you mean...";
	echo "dnf ${@}"
}
function dnfToAptWrapper() {
	echo "Hey Dumbass: Did you mean...";
	echo "apt ${@}"
}
function PacmanToAptWrapper() {
	echo "Hey Dumbass: Did you mean...";
	echo "pacman ${@}"
}
function whichPackageVersion() {
	local fnName='whichPackageVersion';
	if [[ 'debian' != "${BASE_DISTRO}" && 'fedora' != "${BASE_DISTRO}"  ]]; then
		if [[ -z "${BASE_DISTRO}" ]]; then
			BASE_DISTRO='unknown';
		fi
		echo "E: ${fnName}() has not been testd with ${BASE_DISTRO}-based distros.";
		return -1;
	fi

	local packageName='';
	local printHeaders=1;
	local installType='any'
	local versionStringType='raw'
	local showHelp=0;

	if [[ 0 == $(testPassedOptionsRegex '-\w*[h]\w*|--help' "${@}") ]]; then
		showHelp=1;
	else
		# if the major version flag is passed, that will take precedence over the regular version flag
		# since those 2 options are mutually exclusive of each other
		if [[ 0 == $(testPassedOptionsRegex '-\w*[Mm]\w*|--major|--major\-?versions?' "${@}") ]]; then
			printHeaders=0;
			versionStringType='major'

		elif [[ 0 == $(testPassedOptionsRegex '-\w*[Bb]\w*|--major\-?minor|--minor|--minor\-?versions?' "${@}") ]]; then
			printHeaders=0;
			versionStringType='minor'

		elif [[ 0 == $(testPassedOptionsRegex '-\w*[Nn]\w*|--numeric' "${@}") ]]; then
			printHeaders=0;
			versionStringType='numeric'

		elif [[ 0 == $(testPassedOptionsRegex '-\w*[Vv]\w*|--version' "${@}") ]]; then
			printHeaders=0;
			versionStringType='raw'
		fi

		# if the installed version flag is passed, that will take precedence over the available version flag
		# since those 2 options are mutually exclusive of each other
		if [[ 0 == $(testPassedOptionsRegex '-\w*[Ii]\w*|--installed|--installed\-?versions?' "${@}") ]]; then
			installType='installed';

		elif [[ 0 == $(testPassedOptionsRegex '-\w*[Ii]\w*|--available|--available\-?versions?' "${@}") ]]; then
			installType='available';
		fi

		# any options will only be considered if a packagename is found
		for (( i=1; i <= ${#@}; i++ )); do
			#echo "\${@:$i:1} = '${@:$i:1}'";
			currentArg="${@:$i:1}";

			if [[ -z "${packageName}" && $currentArg =~ ^[A-Za-z0-9].*$ ]]; then
				packageName="$currentArg";
			fi
		done
	fi

	if [[ -z "${packageName}" || 1 == ${showHelp} ]]; then
		if [[ 1 != ${showHelp} ]]; then
			echo "E: ${fnName}(): no packageName provided";
			echo "";
		fi
		echo "expected usage:";
		echo "    ${fnName} [OPTIONS] PACKAGE_NAME";
		echo " or ${fnName} PACKAGE_NAME [OPTIONS]";
		echo "";
		echo "Determines which version of an application is installed, or if";
		echo "not installed then, then which version is available for download.";
		echo "By default, this will be printed with headers but that can be"
		echo "controlled using the options below."
		echo "";
		echo "PACKAGE_NAME can be either a package name. In some cases, a local";
		echo "binary can be used in place of a package name (if it is on the PATH";
		echo "and supports -version or --version).";
		echo "";
		echo "OPTIONS:";
		echo "  -h, --help       Display this help content";
		echo "  -v, --version    Print version only, no header";
		echo "  -m, --major      Print major version only, no header or minor version";
		echo "  -b, --minor      Print major + minor version only, no header or minor version";
		echo "  -n, --numeric    Print numeric version only, no header or text info version info";
		echo "  -i, --installed  Show only local version and skip the newest available";
		echo "  -a, --available  Skip the local version and check the newest available";
		echo "                   version from repos.";
		echo "";
		echo "More than one option may be combined as long as they are not mutually-";
		echo "exclusive options. Mutually exclusive options are as follows:";
		echo "  -m, -b, -n, -v   are all mutually exclusive with one another";
		echo "  -i, -a           are mutually exclusive with each other";
		echo "";
		echo "However, options from the first and second group can be mixed freely. e.g.";
		echo "";
		echo "  # display x version type with y (installed or available) app";
		echo "  ${fnName} -m -i PACKAGE_NAME";
		echo "  ${fnName} -a -m PACKAGE_NAME";
		echo "  ${fnName} -ba PACKAGE_NAME";
		echo "  ${fnName} -av PACKAGE_NAME";
		echo "  ${fnName} --numeric --installed PACKAGE_NAME";
		echo "  ${fnName} --available --minor PACKAGE_NAME";
		echo "";
		return 0;
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "${fnName}(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo "";
		echo "packageName: $packageName";
		echo "printHeaders: ${printHeaders}";
		echo "versionStringType: ${versionStringType}";
		echo "installType: ${installType}";
		echo "";
	fi

	local versionString=''

	# Has tool:
	#	https://github.com/kdabir/has.git
	# Found out about it here:
	# 	https://ostechnix.com/how-to-find-if-a-package-is-installed-or-not-in-linux-and-unix/
	#
	local allowHas=1;
	if [[ '1' == "${allowHas}" && '' != "$(which $WHICH_OPTS has 2>/dev/null)" ]]; then
		versionString="$(has "${packageName}" 2>/dev/null|grep -v "not understood")";
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "allowHas: $allowHas";
		if [[ '1' == "${allowHas}" && '' != "$(which $WHICH_OPTS has 2>/dev/null)" ]]; then
			echo "versionString: $versionString";
		fi
		echo "";
	fi

	local isInstalled=0;
	local isAvailable=0;
	local tempOutput='';
	local commandOutput='';
	local packageSearchCommand='';

	if [[ '' == "${versionString}" ]]; then
		# escape special characters that apply in grep -P patterns
		local packageNameRegex="${packageName}";
		packageNameRegex="${packageNameRegex/-/\\-}";
		packageNameRegex="${packageNameRegex/./\\.}";
		packageNameRegex="${packageNameRegex/(/\\(}";
		packageNameRegex="${packageNameRegex/)/\\)}";
		packageNameRegex="${packageNameRegex/\*/\\*}";

		#echo "packageNameRegex: $packageNameRegex"

		# See:
		#	https://www.2daygeek.com/find-out-if-package-is-installed-or-not-in-linux-unix/
		#
		if [[ -f /usr/bin/dnf ]]; then
			if [[ 'available' != "${installType}" ]]; then
				packageSearchCommand='dnf list installed'
				commandOutput="$(dnf list installed --nogpgcheck --cacheonly --assumeno --quiet "${packageName}" 2>/dev/null|grep -v "^Installed Packages")";
				tempOutput="$(echo "${commandOutput}"|grep -Pic "^${packageNameRegex}\\b")"

				if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
					isInstalled=1;
					versionString="$(echo "$commandOutput"|grep -Pi "^${packageNameRegex}\\b"|sed -E 's/\s+/ /g'|cut -d' ' -f2|sed -E 's/\.[a-z][a-z]\w+$//g')";
				fi
			fi
			if [[ 'available' == "${installType}" || ( 'any' != "${installType}" && 0 == ${isInstalled} ) ]]; then
				packageSearchCommand='dnf list available'
				commandOutput="$(dnf list available --nogpgcheck --cacheonly --assumeno --quiet "${packageName}" 2>/dev/null|grep -v "^Available Packages")";
				tempOutput="$(echo "${commandOutput}"|grep -Pic "^${packageNameRegex}\\b")"
				if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
					versionString="$(echo "$commandOutput"|grep -Pi "^${packageNameRegex}\\b"|sed -E 's/\s+/ /g'|cut -d' ' -f2|sed -E 's/\.[a-z][a-z]\w+$//g')";
				fi
			fi

		elif [[ -f /usr/bin/yum && "$(realpath /usr/bin/dnf 2>/dev/null)" != "$(realpath /usr/bin/yum 2>/dev/null)" ]]; then
			if [[ 'available' != "${installType}" ]]; then
				packageSearchCommand='yum list installed'
				commandOutput="$(yum list installed --nogpgcheck --cacheonly --assumeno --quiet "${packageName}" 2>/dev/null|grep -v "^Installed Packages")";
				tempOutput="$(echo "${commandOutput}"|grep -Pic "^${packageNameRegex}\\b")"
				if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
					isInstalled=1;
					versionString="$(echo "$commandOutput"|grep -Pi "^${packageNameRegex}\\b"|sed -E 's/\s+/    /g')";
				fi
			fi
			if [[ 'available' == "${installType}" || ( 'any' != "${installType}" && 0 == ${isInstalled} ) ]]; then
				packageSearchCommand='yum list available'
				commandOutput="$(yum list available --nogpgcheck --cacheonly --assumeno --quiet "${packageName}" 2>/dev/null|grep -v "^Available Packages")";
				tempOutput="$(echo "${commandOutput}"|grep -Pic "^${packageNameRegex}\\b")"
				if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
					versionString="$(echo "$commandOutput"|grep -Pi "^${packageNameRegex}\\b"|sed -E 's/\s+/    /g')";
				fi
			fi

		elif [[ -f /usr/bin/pacman ]]; then
			if [[ 'available' != "${installType}" ]]; then
				packageSearchCommand='pacman -Qs'
				commandOutput="$(pacman -Qs "${packageName}" 2>/dev/null)";
				tempOutput="$(echo "${commandOutput}"|grep -Pic "\\b${packageNameRegex}\\b")"
				if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
					isInstalled=1;
					versionString="$(echo "$commandOutput"|grep -Pi "^${packageNameRegex}\\b"|sed -E 's/\s+/    /g')";
				fi
			fi
			if [[ 'available' == "${installType}" || ( 'any' != "${installType}" && 0 == ${isInstalled} ) ]]; then
				packageSearchCommand='pacman -Qs'
				commandOutput="$(pacman -Qs "${packageName}" 2>/dev/null)";
				tempOutput="$(echo "${commandOutput}"|grep -Pic "\\b${packageNameRegex}\\b")"
				if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
					versionString="$(echo "$commandOutput"|grep -Pi "^${packageNameRegex}\\b"|sed -E 's/\s+/    /g')";
				fi
			fi

		elif [[ -f /usr/bin/zypper ]]; then
			if [[ 'available' != "${installType}" ]]; then
				packageSearchCommand='zypper se --installed-only | grep -Pi'
				commandOutput="$(zypper se --installed-only 2>/dev/null|grep -Pi "\\b${packageNameRegex}\\b")";
				tempOutput="$(echo "${commandOutput}"|grep -Pic "\\b${packageNameRegex}\\b")"
				if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
					isInstalled=1;
				fi
			fi
			if [[ 'available' == "${installType}" || ( 'any' != "${installType}" && 0 == ${isInstalled} ) ]]; then
				echo "E: UNIMPLEMENTED";
			fi

		elif [[ -f /usr/bin/dpkg && -f /usr/bin/apt-cache ]]; then
			# first, determine current status of package (prevent partial matches)
			packageSearchCommand='dpkg -l'
			commandOutput="$(dpkg -l "${packageName}" 2>/dev/null|grep -P "^ii\\s+${packageName}\\s+")";
			tempOutput="$(echo "${commandOutput}"|grep -Pc "^ii\\s+${packageName}\\s+")"
			if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
				isInstalled=1;
			fi

			if [[ 1 == ${isInstalled} && 'available' != "${installType}" ]]; then
				packageSearchCommand='apt-cache policy'
				versionString=$(apt-cache policy "${packageName}" 2>/dev/null|grep -P '^\s+Installed:\s+'|sed -E 's/^\s+Installed:\s+//g');

			elif [[ 'available' == "${installType}" || ( 'any' == "${installType}" && 0 == ${isInstalled} ) ]]; then
				packageSearchCommand='apt-cache policy'
				commandOutput=$(apt-cache policy "${packageName}" 2>/dev/null|grep -Pi "^${packageNameRegex}\\b"|grep -P '^\s+Candidate:\s+');
				tempOutput="$(echo "${commandOutput}"|grep -Pi "^${packageNameRegex}\\b"|grep -Pc '^\s+Candidate:\s+')"
				if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
					versionString=$(apt-cache policy "${packageName}" 2>/dev/null|grep -P '^\s+Candidate:\s+'|sed -E 's/^\s+Candidate:\s+//g');
				fi
			fi

		elif [[ -f /usr/bin/rpm ]]; then
			if [[ 'available' != "${installType}" ]]; then
				packageSearchCommand='rpm -qa'
				commandOutput="$(rpm -qa "${packageName}" 2>/dev/null|grep -Pi "\\b${packageNameRegex}\\b")";
				tempOutput="$(echo "${commandOutput}"|grep -Pic "^${packageNameRegex}\\b")"
				if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
					isInstalled=1;
				fi
			fi
			if [[ 'available' == "${installType}" || ( 'any' != "${installType}" && 0 == ${isInstalled} ) ]]; then
				echo "E: UNIMPLEMENTED";
			fi
		fi

		# some sample versionStrings before formatting:
		#	linuxmint-20:
		#		firefox (central repo):		versionString: 87.0+linuxmint1+ulyssa
		#		neofetch (central repo):	versionString: 7.0.0-1
		#		teamviewer (custom repo):	versionString: 15.16.8
		#		sublime-text (custom repo):	versionString: 3211
		#		lutris (custom repo):		versionString: 0.5.8.3~ubuntu20.04.1

		formattedVersion="${versionString}";

		if [[ 'major' == "${versionStringType}" ]]; then
			formattedVersion="$(echo "${versionString}"|cut -d'.' -f1)";

		elif [[ 'minor' == "${versionStringType}" ]]; then
			formattedVersion="$(echo "${versionString}"|sed -E -e 's/^([0-9][.0-9]+[0-9])[^0-9].*$/\1/g' -e 's/^([0-9][0-9]*)\.([0-9][0-9]*)\..*$/\1.\2/g')";

		elif [[ 'numeric' == "${versionStringType}" ]]; then
			formattedVersion="$(echo "${versionString}"|sed -E 's/^([0-9][.0-9]+[0-9])[^0-9].*$/\1/g')";
		fi

		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "commandOutput: $commandOutput";
			echo "isAvailable: $isAvailable";
			echo "isInstalled: $isInstalled";
			echo "packageName: $packageName";
			echo "packageSearchCommand: $packageSearchCommand";
			echo "printOutput: $printOutput";
			echo "tempOutput: $tempOutput";
			echo "versionString: $versionString";
			echo "formattedVersion: $formattedVersion";
			echo "";
		fi

		if [[ 1 == ${printHeaders} ]]; then
			local sep="==================================================================";

			if [[ 1 == ${isInstalled} ]]; then
				printf '\n%s\n Installed? : Yes\n Version: %s\n Path: %s\n%s\n' \
				"${sep}" "${formattedVersion}" "$(which $WHICH_OPTS ${packageName} 2>/dev/null)" "${sep}";
			elif [[ 1 == ${isAvailable} ]]; then
				printf '\n%s\n Installed? : No\n Available? : Yes\n Version: %s\n%s\n' \
				"${sep}" "${formattedVersion}" "${sep}";
			else
				printf '\n%s\n Installed? : No\n Available? : No\n%s\n' "${sep}" "${sep}";
			fi

			if [[ 'debian' == "${BASE_DISTRO}" && '/usr/bin/rmadison' == "$(which $WHICH_OPTS rmadison 2>/dev/null)" ]]; then
				echo '';
				echo 'Debian versions:';
				rmadison "${packageName}" --architecture amd64,i386,all 2>/dev/null;
			fi
		else
			echo "${formattedVersion}"
		fi
	fi
}
function whichRealBinary() {
	if [[ "" == "$1" || "-h" == "$1" || "--help" == "$1" ]]; then
		echo "Expected usage";
		echo "   whichRealBinary binaryName";
		echo "or whichRealBinary pathToBinary";
		echo "";
		echo "Similar to which but it will display the following additional information:";
		echo " * file type (file or symlink)";
		echo " * if the file is a symlink, the real path will be displayed.";
		echo "";
		echo "  binaryName   - Name of a binary on \$PATH such as 7z, curl, firefox, etc";
		echo "  pathToBinary - Path to a binary installed by a package. This can be the path of an actual file (e.g. /usr/bin/7z) or a symlink to an actual file (e.g. /usr/bin/vi); however either the resolved file must be part of a package.";
		echo "";
		return 0;
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
		local binLocation=$();
		if [[ "" != "${binLocation}" && -e "${binLocation}" ]]; then
			local realLoc="${binLocation}";
			local type="file";
			if [[ -L "${binLocation}" ]]; then
				realLoc=$(realpath "${binLocation}");
				type="symlink";
			fi
			echo "${realLoc}";
		fi
	fi
}
function whichPackage() {
	local fnName='whichPackage';
	if [[ 'debian' != "${BASE_DISTRO}" && 'fedora' != "${BASE_DISTRO}"  ]]; then
		if [[ -z "${BASE_DISTRO}" ]]; then
			BASE_DISTRO='unknown';
		fi
		echo "E: ${fnName}() has not been testd with ${BASE_DISTRO}-based distros.";
		return -1;
	fi

	if [[ "" == "$1" || "-h" == "$1" || "--help" == "$1" ]]; then
		echo "Expected usage";
		echo "   ${fnName} binaryName";
		echo "or ${fnName} pathToBinary";
		echo "";
		echo "Finds what package a binary is from (e.g. /usr/bin/7z => p7zip-full)";
		echo "  binaryName   - Name of a binary on \$PATH such as 7z, curl, firefox, etc";
		echo "  pathToBinary - Path to a binary installed by a package. This can be the path of an actual file (e.g. /usr/bin/7z) or a symlink to an actual file (e.g. /usr/bin/vi); however either the resolved file must be part of a package.";
		echo "";
		return 0;
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
		local binLocation=$(which $WHICH_OPTS "${path}" 2>/dev/null);
		if [[ "" != "${binLocation}" && -e "${binLocation}" ]]; then
			local realLoc="${binLocation}";
			if [[ -L "${binLocation}" ]]; then
				realLoc=$(realpath "${binLocation}");
			fi
			path="${realLoc}";
		fi
	fi

	if [[ 'fedora' == "${BASE_DISTRO}"  ]]; then
		dnf provides --nogpgcheck --cacheonly --assumeno --quiet "${path}"|grep -Pv '^($|Repo|Matched|Filename)'|sort -u;
	elif [[ 'debian' == "${BASE_DISTRO}" ]]; then
		dpkg -S "${path}"|awk -F: '{print $1}';
	fi
}
function whichBinariesInPackage() {
	if [[ 'debian' != "${BASE_DISTRO}" && 'fedora' != "${BASE_DISTRO}"  ]]; then
		if [[ -z "${BASE_DISTRO}" ]]; then
			BASE_DISTRO='unknown';
		fi
		echo "E: whichBinariesInPackage() has not been updated to work with ${BASE_DISTRO}-based distros.";
		return -1;
	fi

	if [[ "" == "$1" || "-h" == "$1" || "--help" == "$1" ]]; then
		echo "Expected usage";
		echo "   whichBinariesInPackage packageName";
		echo "";
		echo "Find out which binaries are in a package (e.g. p7zip-full => /usr/bin/7z)";
		echo "  packageName   - Name of a package to find binaries for such as p7zip-full, curl, firefox, etc";
		echo "";
		return 0;
	fi
	local beVerbose="false";
	local binariesList=(  );
	local packageName="$1";
	local option="$2"

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "whichBinariesInPackage(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo ""
		echo "packageName: $packageName"
	fi

	# set verbosity
	if [[ "-v" == "$2" || "--verbose" == "$2" ]]; then
		beVerbose="true";
	fi

	local isPackageMissing=0;
	if [[ 'fedora' == "${BASE_DISTRO}" ]]; then
		isPackageMissing=$(dnf repoquery --installed --list --nogpgcheck --cacheonly --assumeno --quiet ${packageName} 2>/dev/null|wc -l);
		# need to reverse the value to match debian testcase
		if [[ '0' == "$isPackageMissing" ]]; then
			isPackageMissing=1;
		else
			isPackageMissing=0;
		fi

	elif [[ 'debian' == "${BASE_DISTRO}" ]]; then
		isPackageMissing=$(dpkg -L ${packageName} 2>&1|grep -c "package '${packageName}' is not installed");
	fi

	if [[ "0" != "${isPackageMissing}" ]]; then
		echo "Package '${packageName}' is not installed.";
		return 0;
	fi

	local allPackageFilesList=(  );
	if [[ 'fedora' == "${BASE_DISTRO}" ]]; then
		allPackageFilesList=($(dnf repoquery --installed --list --nogpgcheck --cacheonly --assumeno --quiet ${packageName} 2>/dev/null|grep -Pv '^(/\.$|/usr/(?:share/)?(?:applications|dbus\-\d|doc|doc-base|icons|lib|lintian|man|nemo|pixmaps|polkit\-\d)\b(?:/.*)?$|/etc\b(?:/.*))'));

	elif [[ 'debian' == "${BASE_DISTRO}" ]]; then
		allPackageFilesList=($(dpkg -L ${packageName} 2>/dev/null|grep -Pv '^(/\.$|/usr/(?:share/)?(?:applications|dbus\-\d|doc|doc-base|icons|lib|lintian|man|nemo|pixmaps|polkit\-\d)\b(?:/.*)?$|/etc\b(?:/.*))'));
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "beVerbose: $beVerbose"
		echo "isPackageMissing: $isPackageMissing"
		echo ""
		echo "-------------------------------------------------------"
		echo "sizeof(allPackageFilesList): ${#allPackageFilesList[@]}"
		printf "allPackageFilesList:\n"
		printf "  %s\n" "${allPackageFilesList[@]}"
		echo "-------------------------------------------------------"
		echo ""
	fi

	for packagePath in "${allPackageFilesList[@]}"; do
		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "packagePath (aka allPackageFilesList[i]): $packagePath"
		fi
		if [[ "" == "${packagePath}" ]]; then
			continue;

		elif [[ -d "${packagePath}" ]]; then
			# skip directories
			continue;
		fi
		# make sure the file is executable
		if [[ ! -x "${packagePath}" ]]; then
			continue;
		fi
		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "packagePath executable?: true"
		fi

		# add to list
		binariesList+=("${packagePath}");
	done

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo ""
		echo "-------------------------------------------------------"
		echo "sizeof(binariesList): ${#binariesList[@]}"
		printf "binariesList:\n"
		printf "  %s\n" "${binariesList[@]}"
		echo "-------------------------------------------------------"
		echo ""
	fi

	if [[ "0" == "${#binariesList[@]}" ]]; then
		echo "No executable files found for package '${packageName}'";
		echo "This is common for library packages but can occassionally be a sign that a non-library package was not installed correctly and does not have the execute permission set on one or more files.";
		return 503;
	fi

	# trim down path list to only those that have files
	local finalPathsList=(  );
	local initialPathsList=($(echo "$PATH"|sed -E 's/:/\n/g'));
	for path in "${initialPathsList[@]}"; do
		if [[ ! -d "${path}" ]]; then
			continue;
		fi
		# remove any trailing slashes
		if [[ "/" == "${path}" ]]; then
			path="${path:0:${#path}-1}";
		fi
		finalPathsList+=("${path}");
	done

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo ""
		echo "-------------------------------------------------------"
		echo "sizeof(finalPathsList): ${#finalPathsList[@]}"
		printf "finalPathsList:\n"
		printf "  %s\n" "${finalPathsList[@]}"
		echo "-------------------------------------------------------"
		echo ""
	fi

	if [[ "true" == "${beVerbose}" ]]; then
		echo "=======================================================";
		echo "List of executable files in package [ ${#binariesList[@]} file(s) ]:";
		echo "=======================================================";
	fi
	local parentDir="";
	local pathAddressableBinariesList=(  );
	for file in "${binariesList[@]}"; do
		#echo "---------------------------------------------";
		if [[ "true" == "${beVerbose}" ]]; then
			echo "${file}";
		fi

		# Check if the current package file is directly addressable
		# on the $PATH (e.g. as opposed to via a symlink on $PATH)
		parentDir=$(dirname "$file");
		for path in "${finalPathsList[@]}"; do
			# if file is directly under current path, add it and move on
			if [[ "${parentDir}" == "${path}" ]]; then
				pathAddressableBinariesList+=("${file}");
				break; # break out of inner loop
			fi
		done
	done

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo ""
		echo "-------------------------------------------------------"
		echo "sizeof(pathAddressableBinariesList): ${#pathAddressableBinariesList[@]}"
		printf "pathAddressableBinariesList:\n"
		printf "  %s\n" "${pathAddressableBinariesList[@]}"
		echo "-------------------------------------------------------"
		echo ""
	fi

	if [[ "0" != "${#pathAddressableBinariesList[@]}" ]]; then
		if [[ "true" == "${beVerbose}" ]]; then
			echo "";
		fi
		echo "=======================================================";
		echo "PATH-addressable binaries [ ${#pathAddressableBinariesList[@]} file(s) ]:";
		echo "=======================================================";
		for file in "${pathAddressableBinariesList[@]}"; do
			echo "${file}";
		done
	fi
}
function whichFilesInPackage() {
	if [[ 'debian' != "${BASE_DISTRO}" && 'fedora' != "${BASE_DISTRO}"  ]]; then
		if [[ -z "${BASE_DISTRO}" ]]; then
			BASE_DISTRO='unknown';
		fi
		echo "E: whichBinariesInPackage() has not been updated to work with ${BASE_DISTRO}-based distros.";
		return -1;
	fi

	if [[ "" == "$1" || "-h" == "$1" || "--help" == "$1" ]]; then
		echo "Expected usage";
		echo "   whichBinariesInPackage packageName";
		echo "";
		echo "Find out which binaries are in a package (e.g. p7zip-full => /usr/bin/7z)";
		echo "  packageName   - Name of a package to find binaries for such as p7zip-full, curl, firefox, etc";
		echo "";
		return 0;
	fi
	local beVerbose="false";
	local pkgFilesList=(  );
	local packageName="$1";
	local option="$2"

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "whichFilesInPackage(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo ""
		echo "packageName: $packageName"
	fi

	# set verbosity
	if [[ "-v" == "$2" || "--verbose" == "$2" ]]; then
		beVerbose="true";
	fi

	local isPackageMissing=0;
	if [[ 'fedora' == "${BASE_DISTRO}" ]]; then
		isPackageMissing=$(dnf repoquery --installed --list --nogpgcheck --cacheonly --assumeno --quiet ${packageName} 2>/dev/null|wc -l);
		# need to reverse the value to match debian testcase
		if [[ '0' == "$isPackageMissing" ]]; then
			isPackageMissing=1;
		else
			isPackageMissing=0;
		fi

	elif [[ 'debian' == "${BASE_DISTRO}" ]]; then
		isPackageMissing=$(dpkg -L ${packageName} 2>&1|grep -c "package '${packageName}' is not installed");
	fi

	if [[ "0" != "${isPackageMissing}" ]]; then
		echo "Package '${packageName}' is not installed.";
		return 0;
	fi

	local allPackageFilesList=(  );
	if [[ 'fedora' == "${BASE_DISTRO}" ]]; then
		allPackageFilesList=($(dnf repoquery --installed --list --nogpgcheck --cacheonly --assumeno --quiet ${packageName} 2>/dev/null|grep -Pv '^(/\.$|/usr/(?:share/)?(?:applications|dbus\-\d|doc|doc-base|icons|lib|lintian|man|nemo|pixmaps|polkit\-\d)\b(?:/.*)?$|/etc\b(?:/.*))'));

	elif [[ 'debian' == "${BASE_DISTRO}" ]]; then
		allPackageFilesList=($(dpkg -L ${packageName} 2>/dev/null|grep -Pv '^(/\.$|/usr/(?:share/)?(?:applications|dbus\-\d|doc|doc-base|icons|lib|lintian|man|nemo|pixmaps|polkit\-\d)\b(?:/.*)?$|/etc\b(?:/.*))'));
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "beVerbose: $beVerbose"
		echo "isPackageMissing: $isPackageMissing"
		echo ""
		echo "-------------------------------------------------------"
		echo "sizeof(allPackageFilesList): ${#allPackageFilesList[@]}"
		printf "allPackageFilesList:\n"
		printf "  %s\n" "${allPackageFilesList[@]}"
		echo "-------------------------------------------------------"
		echo ""
	fi

	for packagePath in "${allPackageFilesList[@]}"; do
		#printf "packagePath-raw: %s\n" "$packagePath"
		if [[ "" == "${packagePath}" ]]; then
			continue;

		elif [[ -d "${packagePath}" ]]; then
			# skip directories
			continue;
		fi

		# add to list
		pkgFilesList+=("${packagePath}");
	done

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo ""
		echo "-------------------------------------------------------"
		echo "sizeof(pkgFilesList): ${#pkgFilesList[@]}"
		printf "pkgFilesList:\n"
		printf "  %s\n" "${pkgFilesList[@]}"
		echo "-------------------------------------------------------"
		echo ""
	fi

	if [[ "0" == "${#pkgFilesList[@]}" ]]; then
		echo "No files found for package '${packageName}'. Virtual package?";
		return 503;
	fi

	echo "=======================================================";
	echo "List of files in package [ ${#pkgFilesList[@]} file(s) ]:";
	echo "=======================================================";
	for file in "${pkgFilesList[@]}"; do
		echo "${file}";
	done
}
function addPPAIfNotInSources () {
	if [[ "ubuntu" != "${DISTRO_NAME}" && "ubuntu" != "${PARENT_DISTRO}" ]]; then
		echo "E: addPPAIfNotInSources() -- and PPAs in general -- only work with Ubuntu-based distros.";
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

	local ppaUrl="$1";
	local ppaPath="${ppaUrl:4}";

	if [[ "" == "$ppaUrl" ]]; then
		echo " E: addPPAIfNotInSources(): Found empty PPA URL." | tee -a "${logFile}";
		echo " Aborting function call" | tee -a "${logFile}";
		return -2;
	fi

	if [[ ! $ppaUrl =~ ^ppa:[A-Za-z0-9][\-A-Za-z0-9_\.\+]*/[A-Za-z0-9][\-A-Za-z0-9_\.\+]*$ ]]; then
		echo " E: addPPAIfNotInSources(): Invalid PPA URL format." | tee -a "${logFile}";
		echo "           Found '${ppaUrl}'" | tee -a "${logFile}";
		echo "           Expected 'ppa:[A-Za-z0-9][\-A-Za-z0-9_\.\+]*/[A-Za-z0-9][\-A-Za-z0-9_\.\+]*'" | tee -a "${logFile}";
		echo " Aborting function call" | tee -a "${logFile}";
		return -3;
	fi
	#echo "Detected '${ppaUrl}' as valid";

	local existingSourceMatches=$(grep -R "${ppaPath}" /etc/apt/sources.list.d/*.list|wc -l);
	#echo "existingSourceMatches: $existingSourceMatches";
	if [[ "0" != "${existingSourceMatches}" ]]; then
		echo "W: addPPAIfNotInSources(): Found '${ppaPath}' in existing source(s); skipping..." | tee -a "${logFile}";
		echo " Aborting function call" | tee -a "${logFile}";
		return -4;
	fi

	#PPA doesn't exist in sources, so add it...
	sudo add-apt-repository -y $* > /dev/null;
}
function addCustomSource() {
	echo "W: addCustomSource is deprecated. Replace with package manager-specific"
	echo "function call. e.g. addAptCustomSource(), addYumCustomSource(), etc"
	# Pass all args as-is (preserving positional params and quoted strings)
	addAptCustomSource "$@"
}
function addAptCustomSource() {
	if [[ 'debian' != "${BASE_DISTRO}" ]]; then
		echo "E: addAptCustomSource() will not work with non-debian distros.";
		return -1;
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "addAptCustomSource(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo "";
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

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "---------------------------------------------------------------"
		echo "appendEntry (initial): $appendEntry"
		echo "errorMessage (initial): $errorMessage"
		echo "hasMissingOrInvalidInfo (initial): $hasMissingOrInvalidInfo"
		echo "logFile: $logFile"
		echo "outputFileName: $outputFileName"
		echo "repoDetails (initial): $repoDetails"
		echo "showUsageInfo: $showUsageInfo"
		echo "showUsageInfo: $showUsageInfo"
		echo "useLogFile: $useLogFile"
		echo "";
	fi
	if [[ "true" != "$showUsageInfo" ]]; then
		if [[ "0" != "${#@}" && "1" != "${#@}" ]]; then
			echo "addAptCustomSource(): validating '$1' '${@:2}'";
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

		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "---------------------------------------------------------------"
			echo "errorMessage (1st validation): $errorMessage"
			echo "hasMissingOrInvalidInfo (1st validation): $hasMissingOrInvalidInfo"
			echo "";
		fi

		if [[ 'true' != "${hasMissingOrInvalidInfo}" ]]; then
			echo "Validating repo details";
			#check if more than 2 args
			arg3="$3";
			arg4="$4";
			arg5="$5";
			arg6="$6";

			if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
				echo "---------------------------------------------------------------"
				echo "arg3: $arg3"
				echo "arg4: $arg4"
				echo "arg5: $arg5"
				echo "arg6: $arg6"
				echo "";
			fi

			# BEGIN combination of multiple args into single string
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

				if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
					echo "---------------------------------------------------------------"
					echo "appendEntry (after combining): $appendEntry"
					echo "errorMessage (after combining): $errorMessage"
					echo "hasMissingOrInvalidInfo (after combining): $hasMissingOrInvalidInfo"
					echo "repoDetails (after combining): $repoDetails"
					echo "";
				fi
			fi
			# END combination of multiple args into single string

			if [[ ! $repoDetails =~ ^deb.*$ && $repoDetails =~ ^https?:\/\/.*$ ]]; then
				echo "W: repoDetails appears to be missing prefix. Prepending 'deb' ...";
				repoDetails="deb $repoDetails";

			elif [[ ! $repoDetails =~ ^deb\ .*$ && ! $repoDetails =~ ^deb\-src\ .*$ ]]; then
				hasMissingOrInvalidInfo="true";
				errorMessage="Invalid prefix. Expected 'deb' or 'deb-src'";
			elif [[ $repoDetails =~ ^deb\-src\ .*$ ]]; then
				# if deb-src, then always set appendEntry to true
				appendEntry="true";
			fi

			if [[ 'true' != "${hasMissingOrInvalidInfo}" ]]; then
				# Check known formats
				#	technically next line also allows other things inside the brackets
				#	e.g. [arch=amd64] -> ok
				#	 but also [arch=amd64 signed-by=/usr/share/keyrings/some-keyring.gpg] -> also ok
				#
				remoteRepoDetails=$(echo "$repoDetails"|sed -E 's/^(deb|deb\-src)\s+//g'|sed -E 's/\[arch=[-A-Za-z0-9]+( [-A-Za-z0-9=/.]*)?\]\s+//g');
				echo "remoteRepoDetails: '${remoteRepoDetails}'";

				if [[ $remoteRepoDetails =~ ^https?:\/\/[A-Za-z0-9][-A-Za-z0-9.]*[^\ ]*\ [^\ ]*\ ?[^\ ]*$ ]]; then
					echo "OK: repo details appear to be valid.";
					repoDetails="$repoDetails";
				else
					hasMissingOrInvalidInfo="true";
					errorMessage="invalid/unsupported repo details format for '${repoDetails}'";
				fi
			fi

			if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
				echo "---------------------------------------------------------------"
				echo "appendEntry (final): $appendEntry"
				echo "errorMessage (final): $errorMessage"
				echo "hasMissingOrInvalidInfo (final): $hasMissingOrInvalidInfo"
				echo "remoteRepoDetails: $remoteRepoDetails"
				echo "repoDetails (final): $repoDetails"
				echo "";
			fi
		fi
	fi

	if [[ "true" == "$showUsageInfo" || "true" == "$hasMissingOrInvalidInfo" ]]; then
		if [[ "true" == "$hasMissingOrInvalidInfo" ]]; then
			echo "E: addAptCustomSource(): ${errorMessage}." | tee -a "${logFile}";
		fi
		echo "" | tee -a "${logFile}";
		echo "usage:" | tee -a "${logFile}";
		echo "   addAptCustomSource REPO_NAME REPO_DETAILS" | tee -a "${logFile}";
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
		echo "   addAptCustomSource sublimetext 'deb https://download.sublimetext.com/ apt/stable/' " | tee -a "${logFile}";
		echo "   addAptCustomSource sublimetext deb https://download.sublimetext.com/ apt/stable/ " | tee -a "${logFile}";
		echo "" | tee -a "${logFile}";
		return 0;
	fi

	#check if it already exists...
	echo "Checking if repo source file already exists..." | tee -a "${logFile}";
	if [[ 'false' == "${appendEntry}" && -f "/etc/apt/sources.list.d/${outputFileName}.list" ]]; then
		echo "W: addAptCustomSource(): Source ${outputFileName} already defined; skipping..." | tee -a "${logFile}";
		return -1;
	elif [[ 'true' == "${appendEntry}" && ! -f "/etc/apt/sources.list.d/${outputFileName}.list" ]]; then
		echo "W: addAptCustomSource(): Source ${outputFileName} doesn't have any binary sources defined; skipping..." | tee -a "${logFile}";
		return -2;
	else
		echo "  -> PASSED";
	fi

	#check if details already exist...
	echo "Checking if repo details not already defined in another file ..." | tee -a "${logFile}";
	local existingRepoDetsCount=$(sudo grep -Ri "${repoDetails}" /etc/apt/sources.list.d/*.list 2>/dev/null|wc -l);
	if [[ "0" != "${existingRepoDetsCount}" ]]; then
		echo "W: addAptCustomSource(): Repo details already defined for '${repoDetails}'; skipping..." | tee -a "${logFile}";
		echo "Existing matches:" | tee -a "${logFile}";
		echo "" | tee -a "${logFile}";
		sudo grep -RHni "${repoDetails}" /etc/apt/sources.list.d/*.list 2>/dev/null | tee -a "${logFile}";
		return 0;
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
function listUninstalledPackageRecommends() {
	echo "W: listUninstalledPackageRecommends is deprecated. Replace with package manager-specific"
	echo "function call. e.g. listUninstalledAptPackageRecommends()"
	# Pass all args as-is (preserving positional params and quoted strings)
	listUninstalledAptPackageRecommends "$@"
}
function listUninstalledAptPackageRecommends() {
	if [[ 'debian' != "${BASE_DISTRO}" ]]; then
		echo "E: listUninstalledAptPackageRecommends() will not work with non-debian distros.";
		return -1;
	fi

	local packageList="$1";
	local hasRecommends=$(sudo apt install --assume-no "${packageList}" 2>/dev/null|grep 'Recommended packages:'|wc -l);
	if [[ "0" == "${hasRecommends}" ]]; then
		echo "";
		return 0;
	fi
	# note the first sed is to remove a pipe that was present in
	# actual output from apt install; see 'sudo apt install --assume-no ledgersmb'
	sudo apt install --assume-no "${packageList}" 2>/dev/null|sed -E 's/(\s+)\|\s+/\1/g'|sed '/^The following NEW packages will be installed:$/Q'|sed '0,/^Recommended packages:$/d'|sed -E 's/^\s+|\s+$//g'|tr ' ' '\n';
}
function listUninstalledPackageSuggests() {
	echo "W: listUninstalledPackageSuggests is deprecated. Replace with package manager-specific"
	echo "function call. e.g. listUninstalledAptPackageSuggests()"
	# Pass all args as-is (preserving positional params and quoted strings)
	listUninstalledAptPackageSuggests "$@"
}
function listUninstalledAptPackageSuggests() {
	if [[ 'debian' != "${BASE_DISTRO}" ]]; then
		echo "E: listUninstalledAptPackageSuggests() will not work with non-debian distros.";
		return -1;
	fi

	local packageList="$1";
	local hasSuggests=$(sudo apt install --assume-no "${packageList}" 2>/dev/null|grep 'Suggested packages:'|wc -l);
	if [[ "0" == "${hasSuggests}" ]]; then
		echo "";
		return 0;
	fi
	# note the first sed is to remove a pipe that was present in
	# actual output from apt install; see 'sudo apt install --assume-no ledgersmb'
	sudo apt install --assume-no "${packageList}" 2>/dev/null|sed -E 's/(\s+)\|\s+/\1/g'|sed '/^The following NEW packages will be installed:$/Q'|sed '/^Recommended packages:$/Q'|sed '0,/^Suggested packages:$/d'|sed -E 's/^\s+|\s+$//g'|tr ' ' '\n';
}
function previewUpgradablePackagesDownloadSize() {
	if [[ 'debian' != "${BASE_DISTRO}" ]]; then
		echo "E: previewUpgradablePackagesDownloadSize() has not been updated to work with non-debian distros.";
		return -1;
	fi

	#get sudo prompt out of the way so it doesn't appear in the middle of output
	sudo ls -acl >/dev/null;

	echo "";
	echo "=============================================================";
	echo "Updating apt cache ...";
	echo "=============================================================";
	sudo apt update 2>&1|grep -Pv '^(Build|Fetch|Get|Hit|Ign|Read|WARNING|$)'|sed -E 's/^(.*) Run.*$/-> \1/g';
	echo "-> Getting list of upgradable packages ...";

	local upgradablePackageList=$(sudo apt list --upgradable 2>&1|grep -Pv '^(Listing|WARNING|$)'|sed -E 's/^([^\/]+)\/.*$/\1/g'|tr '\n' ' '|sed -E 's/^\s+|\s+$//g');
	local upgradablePackageArray=($(echo "$upgradablePackageList"|tr ' ' '\n'));
	#echo "upgradablePackageArray size: ${#upgradablePackageArray[@]}"

	echo "";
	echo "=============================================================";
	echo "Calculating download sizes (note: there may be overlaps) ...";
	echo "=============================================================";

	echo "";
	newPackageCount=0;
	for packageName in "${upgradablePackageArray[@]}"; do
		#echo "packageName: '$packageName'"
		apt show "$packageName" 2>/dev/null|grep --color=never -P '(Package|Version|Installed-Size|Download-Size):';
		is_installed=$(apt install --simulate --assume-yes "$packageName" 2>/dev/null|grep --color=never 'already the newest');
		if [[ "" == "${is_installed}" ]]; then
			newPackageCount=$(( newPackageCount + 1 ));
			aptitude install --simulate --assume-yes --without-recommends "$packageName" 2>/dev/null|grep 'Need to get'|tail -1|sed -E 's/^Need to get ([0-9[[0-9\.,]*) ([kmgKMG]i?[Bb]).*$/With dependencies only:           \1 \2/g'
			aptitude install --simulate --assume-yes --with-recommends    "$packageName" 2>/dev/null|grep 'Need to get'|tail -1|sed -E 's/^Need to get ([0-9[[0-9\.,]*) ([kmgKMG]i?[Bb]).*$/With dependencies and recommends: \1 \2/g'
		else
			echo "${is_installed}";
		fi
		echo "";
	done
	echo "";
	echo "=============================================================";
	echo "Total:";
	echo "=============================================================";
	#echo "test: ${upgradablePackageArray[@]}"
	aptitude install --simulate --assume-yes --without-recommends "${upgradablePackageArray[@]}" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9\.,]*) ([kmgKMG]i?[Bb]).*$/With dependencies only:           \1 \2/g'
	aptitude install --simulate --assume-yes --with-recommends    "${upgradablePackageArray[@]}" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9\.,]*) ([kmgKMG]i?[Bb]).*$/With dependencies and recommends: \1 \2/g'
	echo "";
}
function previewPackageDownloadSize() {
	if [[ 'debian' != "${BASE_DISTRO}" ]]; then
		echo "E: previewPackageDownloadSize() has not been updated to work with non-debian distros.";
		return -1;
	fi

	if [[ "0" == "${#@}" ]]; then
		echo "Expected usage:";
		echo "  previewPackageDownloadSize PACKAGE_NAME";
		echo "  previewPackageDownloadSize PACKAGE1 [PACKAGE2 [PACKAGE3 [...]]]] ";
		return -1;
	fi
	#get sudo prompt out of the way so it doesn't appear in the middle of output
	sudo ls -acl >/dev/null;

	echo "=============================================================";
	newPackageCount=0;
	for packageName in "$@"; do
		apt show "$packageName" 2>/dev/null|grep --color=never -P '(Package|Version|Installed-Size|Download-Size):';
		is_installed=$(apt install --simulate --assume-yes "$packageName" 2>/dev/null|grep --color=never 'already the newest');
		if [[ "" == "${is_installed}" ]]; then
			newPackageCount=$(( newPackageCount + 1 ));
			aptitude install --simulate --assume-yes --without-recommends "$packageName" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9\.,]*) ([kmgKMG]i?[Bb]).*$/Without recommends: \1 \2/g'
			aptitude install --simulate --assume-yes --with-recommends "$packageName" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9\.,]*) ([kmgKMG]i?[Bb]).*$/With recommends:    \1 \2/g'
		else
			echo "${is_installed}";
		fi
		echo "=============================================================";
	done
	if [[ "0" != "${newPackageCount}" ]]; then
		echo "Total:"
		aptitude install --simulate --assume-yes --without-recommends "${@}" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9\.,]*) ([kmgKMG]i?[Bb]).*$/Without recommends: \1 \2/g'
		aptitude install --simulate --assume-yes --with-recommends "${@}" 2>/dev/null|grep 'Need to get'|sed -E 's/^Need to get ([0-9[[0-9\.,]*) ([kmgKMG]i?[Bb]).*$/With recommends:    \1 \2/g'
	fi
}
function installPackages() {
	if [[ 'debian' != "${BASE_DISTRO}" ]]; then
		echo "E: installPackages() has not been updated to work with non-debian distros.";
		return -1;
	fi
	# Pass all args as-is (preserving positional params and quoted strings)
	installAptPackages "$@"
}
function installAptPackages() {
	if [[ 'debian' != "${BASE_DISTRO}" ]]; then
		echo "E: installAptPackages() has not been updated to work with non-debian distros.";
		return -1;
	fi

	# get sudo password prompt out of the way early on (for cleaner message display)
	sudo ls -acl 2>&1 >/dev/null

	local installOptions="-y -qq -o=Dpkg::Use-Pty=0";
	local packageList="$1";
	local installRecommends="$2";
	local installSuggests="$3";
	local showProgress="$4";

	if [[ "true" == "${installRecommends}" ]]; then
		installOptions="${installOptions} --install-recommends";
	fi
	if [[ "true" == "${installSuggests}" ]]; then
		installOptions="${installOptions} --install-suggests";
	fi
	if [[ "true" == "${showProgress}" ]]; then
		installOptions="${installOptions} --show-progress";
	fi

	if [[ "" == "$INSTALL_LOG" ]]; then
		sudo apt install ${installOptions} ${packageList} 2>&1 | grep -v 'apt does not have a stable CLI interface';
		return 0;
	fi
	printf '\n%s\n' "Running: sudo apt install ${installOptions} ${packageList} | grep -v 'apt does not have a stable CLI interface'" | tee -a "${INSTALL_LOG}";
	sudo apt install ${installOptions} ${packageList} 2>&1 | grep -v 'apt does not have a stable CLI interface' | tee -a "${INSTALL_LOG}";
}
function installPackagesWithRecommends() {
	echo "W: installPackagesWithRecommends is deprecated. Replace with package manager-specific"
	echo "function call. e.g. installAptPackagesWithRecommends()"
	# Pass all args as-is (preserving positional params and quoted strings)
	installAptPackagesWithRecommends "$@"
}
function installAptPackagesWithRecommends() {
	installAptPackages "$1" "true" "false" "$2";
}
function installPackagesWithRecommendsAndSuggests() {
	echo "W: installPackagesWithRecommendsAndSuggests is deprecated. Replace with package manager-specific"
	echo "function call. e.g. installAptPackagesWithRecommendsAndSuggests()"
	# Pass all args as-is (preserving positional params and quoted strings)
	installAptPackagesWithRecommendsAndSuggests "$@"
}
function installAptPackagesWithRecommendsAndSuggests() {
	installAptPackages "$1" "true" "true" "$2";
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
		echo "E: verifyAndInstallPackagesFromMap() has not been updated to work with non-debian distros.";
		return -1;
	fi

	# get sudo prompt out of way up-front so that it
	# doesn't appear in the middle of other output
	sudo ls -acl 2>/dev/null >/dev/null;

	# ==================================================================
	# This function expects $1 to be an associative array (aka a map)
	# which contains:
	#	Map<Key=localBinaryPath,Value=packageNameOfBinary>
	# where
	# localBinaryPath     = path to a local binary (e.g. /usr/bin/7z)
	# packageNameOfBinary = install package for binary (e.g. p7zip-full)
	# ==================================================================
	# Sample usage:
	#
	# # 1) Define a dependenciesMap
	# declare -A dependenciesMap=(
	#	['/usr/bin/7z']='p7zip-full'
	#	['/usr/bin/curl']='curl'
	#	['/usr/bin/yad']='yad'
	#	['/usr/bin/convert']='imagemagick'
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
		binExists=$(/usr/bin/which $WHICH_OPTS "${binPathKey}" 2>/dev/null|wc -l);
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
			binExists=$(/usr/bin/which $WHICH_OPTS "${binPathKey}" 2>/dev/null|wc -l);
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
		echo "E: verifyAndInstallPackagesFromList() has not been updated to work with non-debian distros.";
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
				echo "E: package '${reqPkgName}' cannot be verified due to multiple matches.";
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
function isPackageInstalled() {
	if [[ 'debian' != "${BASE_DISTRO}" && 'fedora' != "${BASE_DISTRO}"  ]]; then
		if [[ -z "${BASE_DISTRO}" ]]; then
			BASE_DISTRO='unknown';
		fi
		echo "E: isPackageInstalled() has not been testd with ${BASE_DISTRO}-based distros.";
		return -1;
	fi

	# Use -q, -s, --quiet, or --silent to avoid printing output and just use return codes
	# to indicate if package is installed or not. In this case, a return code of 0 indicates
	# the package is not installed and a return code of 1 indicates it is.
	local packageName='';
	local printOutput=1;
	local showHelp=0;
	for (( i=1; i <= ${#@}; i++ )); do
		#echo "\${@:$i:1} = '${@:$i:1}'";
		currentArg="${@:$i:1}";
		if [[ $currentArg =~ ^\-[h]$ || $currentArg =~ ^\-\-*help$ ]]; then
			showHelp=1;
		elif [[ $currentArg =~ ^\-[qs]$ || $currentArg =~ ^\-\-*quiet$ || $currentArg =~ ^\-\-*silent$ ]]; then
			printOutput=0;
		elif [[ -z "${packageName}" && $currentArg =~ ^[A-Za-z0-9].*$ ]]; then
			packageName="$currentArg";
		fi
	done

	if [[ -z "${packageName}" || '1' == "${showHelp}" ]]; then
		if [[ -z "${packageName}" ]]; then
			echo "E: isPackageInstalled(): no packageName provided";
			echo "";
		fi
		echo "expected usage:";
		echo "  isPackageInstalled PACKAGE_NAME";
		echo "";
		echo "  Determines whether or not the given package is installed locally.";
		echo "  By default, it will print output and return 1 for installed and 0";
		echo "  for not installed.";
		echo "";
		echo "OPTIONS:";
		echo "  -h, --help    Display this help content";
		echo "  -q, --quiet   Do not print output; only use return code";
		echo "  -s, --silent  Same as --quiet";
		return 0;
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "isPackageInstalled(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo ""
		echo "packageName: $packageName"
		echo "printOutput: $printOutput"
	fi

	local isInstalled=0;
	local tempOutput='';
	local commandOutput='';
	if [[ '0' != "$(which $WHICH_OPTS "${packageName}" 2>/dev/null|wc -l)" ]]; then
		isInstalled=1;
		if [[ '1' != "${printOutput}" ]]; then
			return ${isInstalled};
		fi
	fi

	# escape special characters that apply in grep -P patterns
	local packageNameRegex="${packageName}";
	packageNameRegex="${packageNameRegex/-/\\-}";
	packageNameRegex="${packageNameRegex/./\\.}";
	packageNameRegex="${packageNameRegex/(/\\(}";
	packageNameRegex="${packageNameRegex/)/\\)}";
	packageNameRegex="${packageNameRegex/\*/\\*}";

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "packageNameRegex: $packageNameRegex"
	fi

	# See:
	#	https://www.2daygeek.com/find-out-if-package-is-installed-or-not-in-linux-unix/
	#
	local packageSearchCommand='';
	if [[ -f /usr/bin/dnf ]]; then
		packageSearchCommand='dnf list installed'
		commandOutput="$(dnf list installed --nogpgcheck --cacheonly --assumeno --quiet "${packageName}" 2>/dev/null|grep -v "^Installed Packages")";
		tempOutput="$(echo "${commandOutput}"|grep -Pic "^${packageNameRegex}\\b")"
		if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
			isInstalled=1;
		fi

	elif [[ -f /usr/bin/yum && "$(realpath /usr/bin/dnf 2>/dev/null)" != "$(realpath /usr/bin/yum 2>/dev/null)" ]]; then
		packageSearchCommand='yum list installed'
		commandOutput="$(yum list installed --nogpgcheck --cacheonly --assumeno --quiet "${packageName}" 2>/dev/null|grep -v "^Installed Packages")";
		tempOutput="$(echo "${commandOutput}"|grep -Pic "^${packageNameRegex}\\b")"
		if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
			isInstalled=1;
		fi

	elif [[ -f /usr/bin/pacman ]]; then
		packageSearchCommand='pacman -Qs'
		commandOutput="$(pacman -Qs "${packageName}" 2>/dev/null)";
		tempOutput="$(echo "${commandOutput}"|grep -Pic "\\b${packageNameRegex}\\b")"
		if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
			isInstalled=1;
		fi

	elif [[ -f /usr/bin/zypper ]]; then
		packageSearchCommand='zypper se --installed-only | grep -Pi'
		commandOutput="$(zypper se --installed-only 2>/dev/null|grep -Pi "\\b${packageNameRegex}\\b")";
		tempOutput="$(echo "${commandOutput}"|grep -Pic "\\b${packageNameRegex}\\b")"
		if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
			isInstalled=1;
		fi

	elif [[ -f /usr/bin/apt ]]; then
		packageSearchCommand='apt search'
		commandOutput="$(apt search "${packageName}" 2>/dev/null)";
		tempOutput="$(echo "${commandOutput}"|grep -Pic "^\\w*i\\w*\\s+${packageNameRegex}\\s")"
		if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
			isInstalled=1;
		fi

	elif [[ -f /usr/bin/dpkg ]]; then
		packageSearchCommand='dpkg -l'
		commandOutput="$(dpkg -l "${packageName}" 2>/dev/null|grep -Pi "\\b${packageNameRegex}\\b")";
		tempOutput="$(echo "${commandOutput}"|grep -Pic "^ii\\s+${packageNameRegex}\\s")"
		if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
			isInstalled=1;
		fi

	elif [[ -f /usr/bin/rpm ]]; then
		packageSearchCommand='rpm -qa'
		commandOutput="$(rpm -qa "${packageName}" 2>/dev/null|grep -Pi "\\b${packageNameRegex}\\b")";
		tempOutput="$(echo "${commandOutput}"|grep -Pic "^${packageNameRegex}\\b")"
		if [[ '0' != "${tempOutput}" && $tempOutput =~ ^[1-9][0-9]*$ ]]; then
			isInstalled=1;
		fi
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "packageSearchCommand: $packageSearchCommand"
		echo "commandOutput: $commandOutput"
		echo "tempOutput: $tempOutput"
		echo "isInstalled: $isInstalled"
		echo "==============================================================="
	fi

	if [[ '1' == "${printOutput}" ]]; then
		commandOutput="$(echo "${commandOutput}"|sed -E 's/[ \t]+/    /g')"
		local sep="==================================================================";
		printf '\n%s\nPath from which:\n%s\n%s\nResults from $(%s %s):\n%s\n%s\n' \
			"${sep}" "$(which $WHICH_OPTS ${packageName} 2>/dev/null)" \
			"${sep}" "${packageSearchCommand}" "${packageName}" \
			"${commandOutput}" "${sep}";
	fi
	return ${isInstalled};
}
#==========================================================================
# End Section: Package Management functions
#==========================================================================

#==========================================================================
# Start Section: Filesystem functions
#==========================================================================
function backupBrowserProfile() {
	local fnName='backupBrowserProfile'

	local backupDir='';
	local browserType='';

	local showHelp=0;
	local retCode=0;

	if [[ '-h' == "$1" || '--help' == "$1" || '' == "$1" ]]; then
		showHelp=1;

	elif [[ '-t' == "$1" ]]; then
		backupDir="$2";
		if [[ '' == "${backupDir}" ]]; then
			echo "E: ${fnName}: Found flag '-t' but no path set for BROWSER_BACKUP_DIR.";
			showHelp=1;
			retCode=-1;

		elif [[ ! -d "${backupDir}" ]]; then
			echo "E: ${fnName}: Passed BROWSER_BACKUP_DIR '${backupDir}' does not exist.";
			showHelp=1;
			retCode=-1;
		fi
		shift 2;

	else
		if [[ -z "${BROWSER_BACKUP_DIR}" ]]; then
			echo "E: ${fnName}: BROWSER_BACKUP_DIR not defined/exported.";
			showHelp=1;
			retCode=-1;

		elif [[ ! -d "${BROWSER_BACKUP_DIR}" ]]; then
			echo "E: ${fnName}: Passed BROWSER_BACKUP_DIR '${BROWSER_BACKUP_DIR}' does not exist.";
			showHelp=1;
			retCode=-1;
		else
			backupDir="${BROWSER_BACKUP_DIR}";
		fi
	fi

	if [[ 1 != ${showHelp} ]]; then
		browserType="$1";
		if [[ '' == "{browserType}" ]]; then
			echo "E: ${fnName}: no BROWSER_NAME passed.";
			showHelp=1;
			retCode=-1;
		fi
	fi

	if [[ 1 != ${showHelp} ]]; then
		echo "";
		echo "usage:";
		echo "  ${fnName} -t BROWSER_BACKUP_DIR BROWSER_NAME";
		echo " or"
		echo "  export BROWSER_BACKUP_DIR=\"/path\"";
		echo "  ${fnName} BROWSER_NAME";
		echo "";
		echo "BROWSER_BACKUP_DIR must be passed as the first argument unless it is";
		echo "exported as a variable.";
		echo "";
		echo "This function will archive the appropriate browser profile and copy"
		echo "the archive to the path BROWSER_BACKUP_DIR.";
		echo "";
		return ${retCode};
	fi

	local packageName=='';
	local profileDir=='';
	local displayName='';
	local isSupportedBrowser=0

	case "${browserType}" in
		[Bb]rave) isSupportedBrowser=1; displayName='brave'; packageName='brave'; profileDir="${HOME}/.config/BraveSoftware" ;;

		[Cc]hrome) isSupportedBrowser=1; displayName='google-chrome'; packageName='google-chrome'; profileDir="${HOME}/.config/google-chrome" ;;
		[Gg]oogle) isSupportedBrowser=1; displayName='google-chrome'; packageName='google-chrome'; profileDir="${HOME}/.config/google-chrome" ;;
		[Gg]oogle[Cc]hrome) isSupportedBrowser=1; displayName='google-chrome'; packageName='google-chrome'; profileDir="${HOME}/.config/google-chrome" ;;
		[Gg]oogle\-[Cc]hrome) isSupportedBrowser=1; displayName='google-chrome'; packageName='google-chrome'; profileDir="${HOME}/.config/google-chrome" ;;
		[Gg][Cc]) isSupportedBrowser=1; displayName='google-chrome'; packageName='google-chrome'; profileDir="${HOME}/.config/google-chrome" ;;

		[Cc]hromium) isSupportedBrowser=1; displayName='chromium'; packageName='chromium'; profileDir="${HOME}/.config/chromium" ;;

		[Vv]ivaldi) isSupportedBrowser=1; displayName='vivaldi'; packageName='vivaldi'; profileDir="${HOME}/.config/vivaldi" ;;

		[Mm]oz) isSupportedBrowser=1; displayName='firefox'; packageName='firefox'; profileDir="${HOME}/.mozilla" ;;
		[Mm]ozilla) isSupportedBrowser=1; displayName='firefox'; packageName='firefox'; profileDir="${HOME}/.mozilla" ;;
		[Ff]irefox) isSupportedBrowser=1; displayName='firefox'; packageName='firefox'; profileDir="${HOME}/.mozilla" ;;
		[Ff][Ff]) isSupportedBrowser=1; displayName='firefox'; packageName='firefox'; profileDir="${HOME}/.mozilla" ;;

		[Ww]aterfox) isSupportedBrowser=1; displayName='waterfox'; packageName='waterfox'; profileDir="${HOME}/.waterfox" ;;
		[Ww][Ff]) isSupportedBrowser=1; displayName='waterfox'; packageName='waterfox'; profileDir="${HOME}/.waterfox" ;;

		*) isSupportedBrowser=0 ;;
	esac
	if [[ 1 != ${isSupportedBrowser} ]]; then
		echo "E: ${fnName}: browserType '${browserType}' not supported.";
		return -1;
	fi

	if [[ ! -d "${backupDir}" ]]; then
		echo "E: ${fnName}: backupDir '${backupDir}' does not exist.";
		return -1;
	fi

	if [[ ! -d "${profileDir}" ]]; then
		echo "E: ${fnName}: profileDir '${profileDir}' does not exist.";
		return -1;
	fi

	isDebugActive=0
	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		# workaround to avoid breaking call to whichPackageVersion below
		isDebugActive=1;
		DEBUG_BASH_FUNCTIONS=0;

		echo "==============================================================="
		echo "${fnName}(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo ""
		echo "packageName: $packageName"
		echo "isSupportedBrowser: $isSupportedBrowser"
		echo "displayName: $displayName"
		echo "profileDir: $profileDir"
		echo "backupDir: $backupDir"
		echo "browserVersion: $browserVersion"
		echo ""
	fi

	local browserVersion="$(whichPackageVersion -bi "${packageName}")";
	if [[ '' == "${browserVersion}" ]]; then
		echo "E: ${fnName}: package '${browserVersion}' not installed.";
		return -1;
	fi

	if [[ 1 == $isDebugActive ]]; then
		DEBUG_BASH_FUNCTIONS=1
		echo "browserVersion: $browserVersion"
		echo ""
		return 0;
	fi

	echo "Archiving ${displayName} profile to '${backupDir}' ...";
	xzdir "${profileDir}" "${backupDir}/$USER@$HOSTNAME.${displayName}-${browserVersion}@$(date +'%Y-%m-%d-%H%M').tar.xz"
	return 0
}
function copyToGroupDirAndFixPerms() {
	local fnName='copyToGroupDirAndFixPerms'
	local arg1="$1";
	local arg2="$2";
	if [[ '-h' == "${arg1}" || '--help' == "${arg1}" ]]; then
		echo "usage:";
		echo "  ${fnName} -t NIX_SHARED_DIR PATH_TO_COPY";
		echo " or"
		echo "  export NIX_SHARED_DIR=\"/path\"";
		echo "  ${fnName} PATH_TO_COPY";
		echo "";
		echo "NIX_SHARED_DIR must be passed as the first argument unless it is";
		echo "exported as a variable.";
		echo "";
		echo "This function will copy PATH_TO_COPY under NIX_SHARED_DIR, ";
		echo "then if the group of the copied files is different they will be updated";
		echo "to use the group of NIX_SHARED_DIR.";
		echo "";
		return 0;

	# if using the -t form from cp/mv ...
	elif [[ '-t' == "${arg1}" ]]; then
		if [[ ! -d "${arg2}" ]]; then
			echo "E: ${fnName}: passed targetDir does not exist or is not a directory.";
			echo "  targetDir: '${arg2}'";
			return -1;

		elif [[ ! -w "${arg2}" ]]; then
			echo "E: ${fnName}: current user does not have write permissions for passed targetDir.";
			echo "  targetDir: '${arg2}'";
			return -1;

		elif [[ ! -O "${arg2}" ]]; then
			echo "E: ${fnName}: current user does not own the passed targetDir.";
			echo "  targetDir: '${arg2}'";
			return -1;

		else
			targetDir="${arg2}";
		fi

		# if using the -t form from cp/mv, then after we've stored the path to a local variable (above)
		# use shift to remove both the '-t' and the targetDir
		shift 2;
		arg1="$1";

	# if NOT using the -t form from cp/mv (e.g. we are using exported NIX_SHARED_DIR variable)
	else
		if [[ -z "${NIX_SHARED_DIR}" ]]; then
			echo "E: ${fnName}: NIX_SHARED_DIR not defined and no passed destination path.";
			return -1;

		elif [[ ! -d "${NIX_SHARED_DIR}" ]]; then
			echo "E: ${fnName}: NIX_SHARED_DIR does not exist and no passed destination path.";
			echo "  NIX_SHARED_DIR: '${NIX_SHARED_DIR}'";
			return -1;

		elif [[ ! -w "${NIX_SHARED_DIR}" ]]; then
			echo "E: ${fnName}: current user does not have write permissions for NIX_SHARED_DIR.";
			echo "  NIX_SHARED_DIR: '${NIX_SHARED_DIR}'";
			return -1;

		elif [[ ! -O "${NIX_SHARED_DIR}" ]]; then
			echo "E: ${fnName}: current user does not own NIX_SHARED_DIR.";
			echo "  NIX_SHARED_DIR: '${NIX_SHARED_DIR}'";
			return -1;

		else
			targetDir="${NIX_SHARED_DIR}"
		fi
	fi

	# if a targetDir is not defined then fail
	if [[ -z "${arg1}" ]]; then
		echo "E: ${fnName}: No targetDir passed / NIX_SHARED_DIR not exported.";
		return -1;
	fi

	# if a first arg is not provided then fail
	if [[ -z "${arg1}" ]]; then
		echo "E: ${fnName}: No passed arguments / nothing to copy.";
		return -1;
	fi

	# get group owner of targetDir
	targetGroup="$(stat --format="%G" "${targetDir}" 2>/dev/null)";
	if [[ -z "${targetGroup}" ]]; then
		targetGroup="$(stat --format="%G" "${targetDir}" 2>/dev/null)";
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "${fnName}(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo "";

		echo "targetDir: '${targetDir}'";
		echo "args-@: ${@}";
	fi

	# if the function was passed a glob/pattern, then the shell will have expanded that
	# and we will have multiple function arguments that each correspond to a file/folder path
	for path in "${@}"; do
		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "-> Copying '${path}' to '${targetDir}' ...";
		fi
		# copy files
		cp -a --no-preserve=ownership -t "${targetDir}" "${path}";
	done
	fixGroupDirPermissions "${targetDir}";
}
function moveToGroupDirAndFixPerms() {
	local fnName='moveToGroupDirAndFixPerms'
	local arg1="$1";
	local arg2="$2";
	if [[ '-h' == "${arg1}" || '--help' == "${arg1}" ]]; then
		echo "usage:";
		echo "  ${fnName} -t NIX_SHARED_DIR PATH_TO_MOVE";
		echo " or"
		echo "  export NIX_SHARED_DIR=\"/path\"";
		echo "  ${fnName} PATH_TO_MOVE";
		echo "";
		echo "NIX_SHARED_DIR must be passed as the first argument unless it is";
		echo "exported as a variable.";
		echo "";
		echo "This function will move PATH_TO_MOVE under NIX_SHARED_DIR, ";
		echo "then if the group of the moved files is different they will be updated";
		echo "to use the group of NIX_SHARED_DIR.";
		echo "";
		return 0;

	# if using the -t form from cp/mv ...
	elif [[ '-t' == "${arg1}" ]]; then
		if [[ ! -d "${arg2}" ]]; then
			echo "E: ${fnName}: passed targetDir does not exist or is not a directory.";
			echo "  targetDir: '${arg2}'";
			return -1;

		elif [[ ! -w "${arg2}" ]]; then
			echo "E: ${fnName}: current user does not have write permissions for passed targetDir.";
			echo "  targetDir: '${arg2}'";
			return -1;

		elif [[ ! -O "${arg2}" ]]; then
			echo "E: ${fnName}: current user does not own the passed targetDir.";
			echo "  targetDir: '${arg2}'";
			return -1;

		else
			targetDir="${arg2}";
		fi

		# if using the -t form from cp/mv, then after we've stored the path to a local variable (above)
		# use shift to remove both the '-t' and the targetDir
		shift 2;
		arg1="$1";

	# if NOT using the -t form from cp/mv (e.g. we are using exported NIX_SHARED_DIR variable)
	else
		if [[ -z "${NIX_SHARED_DIR}" ]]; then
			echo "E: ${fnName}: NIX_SHARED_DIR not defined and no passed destination path.";
			return -1;

		elif [[ ! -d "${NIX_SHARED_DIR}" ]]; then
			echo "E: ${fnName}: NIX_SHARED_DIR does not exist and no passed destination path.";
			echo "  NIX_SHARED_DIR: '${NIX_SHARED_DIR}'";
			return -1;

		elif [[ ! -w "${NIX_SHARED_DIR}" ]]; then
			echo "E: ${fnName}: current user does not have write permissions for NIX_SHARED_DIR.";
			echo "  NIX_SHARED_DIR: '${NIX_SHARED_DIR}'";
			return -1;

		elif [[ ! -O "${NIX_SHARED_DIR}" ]]; then
			echo "E: ${fnName}: current user does not own NIX_SHARED_DIR.";
			echo "  NIX_SHARED_DIR: '${NIX_SHARED_DIR}'";
			return -1;

		else
			targetDir="${NIX_SHARED_DIR}"
		fi
	fi

	# if a targetDir is not defined then fail
	if [[ -z "${arg1}" ]]; then
		echo "E: ${fnName}: No targetDir passed / NIX_SHARED_DIR not exported.";
		return -1;
	fi

	# if a first arg is not provided then fail
	if [[ -z "${arg1}" ]]; then
		echo "E: ${fnName}: No passed arguments / nothing to move.";
		return -1;
	fi

	# get group owner of targetDir
	targetGroup="$(stat --format="%G" "${targetDir}" 2>/dev/null)";
	if [[ -z "${targetGroup}" ]]; then
		targetGroup="$(stat --format="%G" "${targetDir}" 2>/dev/null)";
	fi

	if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
		echo "==============================================================="
		echo "${fnName}(): Debug"
		echo "==============================================================="
		echo "passed args: $@"
		echo "";

		echo "targetDir: '${targetDir}'";
		echo "args-@: ${@}";
	fi

	# if the function was passed a glob/pattern, then the shell will have expanded that
	# and we will have multiple function arguments that each correspond to a file/folder path
	for path in "${@}"; do
		if [[ 1 == $DEBUG_BASH_FUNCTIONS ]]; then
			echo "-> Moving '${path}' to '${targetDir}' ...";
		fi
		# movr files
		mv -t "${targetDir}" "${path}";
	done
	fixGroupDirPermissions "${targetDir}";
}
function fixGroupDirPermissions() {
	local fnName='fixGroupDirPermissions'
	local sharedDir="$1";
	if [[ '-h' == "${arg1}" || '--help' == "${arg1}" ]]; then
		echo "usage:";
		echo "  ${fnName} SHARED_DIR";
		echo "";
		echo "This function will fix group ownership and all file/subfolder permissions under";
		echo "the passed sharedDir. Note that the sharedDir itself will not have its group or";
		echo "permissions altered and will be used as a reference for setting the group of its";
		echo "children. So the sharedDir should be set correctly prior to calling the function.";
		echo "";
		return 0;
	fi

	# if a first arg is not provided then fail
	if [[ -z "${arg1}" ]]; then
		echo "E: ${fnName}: No passed sharedDir / nothing to fix.";
		return -1;
	fi

	# get group owner of targetDir
	targetGroup="$(stat --format="%G" "${sharedDir}" 2>/dev/null)";
	if [[ -z "${targetGroup}" ]]; then
		targetGroup="$(stat --format="%g" "${sharedDir}" 2>/dev/null)";
	fi

	# change group
	chgrp -R "${targetGroup}" "${sharedDir}" 2>/dev/null;

	# make sure sub-folders are readable to user + group
	find "${sharedDir}" -mindepth 1 -type d -not -perm -ug+rx,g+s -exec chmod ug+rx,g+s "{}" \; 2>/dev/null

	# make sure all files are readable to user + group
	find "${sharedDir}" -mindepth 1 -type f -not -perm -ug+r -exec chmod ug+r "{}" \; 2>/dev/null

	# remove access for "other" users (on subfolders and files) - good security practice
	find "${sharedDir}" -mindepth 1 -perm /o+rwx -exec chmod o-rwx "{}" \; 2>/dev/null

	# make sure regular files are not executable - good security practice
	find "${sharedDir}" -mindepth 1 -type f -perm /gu+x -not \( -iname '*.sh' -o -iname '*.py' \) -exec chmod gu-x "{}" \; 2>/dev/null
}
#==========================================================================
# End Section: Filesystem functions
#==========================================================================

#==========================================================================
# Start Section: Process and window functions
#==========================================================================
function getProcessInfoByInteractiveMouseClick() {
	ps -o pid,comm,start,etime,pcpu,pmem,size,args -p $(echo $(PIDSTR=$(xprop _NET_WM_PID); echo "$PIDSTR" | sed "s/^.*[^0-9]\([0-9][0-9]*\)[^0-9]*$/\1/g"))
}
function getProcessIdByWindowName() {
	local TARGET_NAME="$1";
	xdotool search --class "$TARGET_NAME" getwindowpid
}
function getProcessInfoByWindowName() {
	local TARGET_NAME="$1";
	ps -o pid,comm,start,etime,pcpu,pmem,size,args -p $(xdotool search --class "$TARGET_NAME" getwindowpid);
}
function moveWindowToWorkspace() {
	local windowTitleText="$1";
	local currentWorkspaceIndex=$2;
	wmctrl -r "${windowTitleText}" -t ${currentWorkspaceIndex};
}
function moveWindowToCurrentWorkspace() {
	local windowTitleText="$1";
	local currentWorkspaceIndex=$(wmctrl -d|grep '*'|cut -c1);
	wmctrl -r "${windowTitleText}" -t ${currentWorkspaceIndex};
}
function printAtQueue() {
	declare -A jobSchedulesMap;

	local MINJOB=$(/usr/bin/atq | sort -n | head -n1 | awk '{ print $1; }');
	local MAXJOB=$(/usr/bin/atq | sort -n | tail -n1 | awk '{ print $1; }');
	if [[ "" != "${MINJOB}" && "" != "${MAXJOB}" && $MINJOB =~ ^[0-9]+$ && $MAXJOB =~ ^[0-9]+$ ]]; then
		## put job list into a Map, then find paths, then use printf to display both data points together
		eval $(/usr/bin/atq|gawk -F'\\s+' '{print $1" \""$0"\""}'|xargs -n 2 sh -c 'echo "jobSchedulesMap[\"$1\"]=\"$2\""' argv0);

		# print a header
		printf '%-7s %-10s %s %-6s %-20s %s\n' 'JOBID' 'DATE' 'TIME     YEAR' 'QUEUE' 'USER' 'COMMAND';
		printf '==================================================================================================================\n';

		local jobId='';
		for jobId in $(seq ${MINJOB} ${MAXJOB}); do
			# the command to be run is always in the 2nd to last line returned by $(at -c ID)
			# and last line is blank
			#
			local commandToBeRun=$(at -c ${jobId}|grep -Pv '^$'|tail -1);
			local scheduleInfo="${jobSchedulesMap[$jobId]}";

			local scheduledDate=$(echo "${scheduleInfo}" | sed -E 's/^[1-9][0-9]*\s+(.*)\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\s+[1-9][0-9]{3}.*$/\1/g');
			local scheduledTimeAndYear=$(echo "${scheduleInfo}" | sed -E 's/^.*\s+([0-9]{2}:[0-9]{2}:[0-9]{2}\s+[1-9][0-9]{3})\s+.*$/\1/g');
			local queueName=$(echo "${scheduleInfo}" | sed -E 's/^.*:[0-9]{2}\s+[1-9][0-9]{3}\s+(\S+)\s+.*$/\1/g');
			local jobUser=$(echo "${scheduleInfo}" | sed -E 's/^.*:[0-9]{2}\s+[1-9][0-9]{3}\s+\S+\s+(\S+)$/\1/g');

			# Print consolidated row as output
			printf '%-7s %-10s %s %-6s %-20s %s\n' "${jobId}" "${scheduledDate}" "${scheduledTimeAndYear}" "${queueName}" "${jobUser}" "${commandToBeRun}";
		done
	fi
	unset jobSchedulesMap;
}
function rescheduleAtJob() {
	local jobId="$1";
	if [[ "" == "$1" || ! $jobId =~ ^[1-9][0-9]*$ ]]; then
		echo "E: rescheduleAtJob(): Invalid jobId '${jobId}'; aborting...";
		return -1;
	fi

	local newTime="$2";
	if [[ "" == "$2" || ! $newTime =~ ^[0-9][0-9]:[0-9][0-9].*$ ]]; then
		echo "E: rescheduleAtJob(): Invalid newTime '${newTime}'.";
		echo "newTime must begin with %H:%M (e.g. 02:00). This can be in 24-hr format or 12-hr format with am/pm (e.g. 02:00am)";
		echo "newTime may also include a date or keywords such as 'today'/'tomorrow' after the time (e.g. '02:00am tomorrow')";
		echo "For more info, see 'man at'";
		echo "";
		return -2;
	fi

	local jobExists=$(/usr/bin/atq|grep -Pc "^${jobId}\\b");
	if [[ "1" != "${jobExists}" ]]; then
		echo "E: rescheduleAtJob(): No AT jobs with jobId '${jobId}'; aborting...";
		return -3;
	fi

	at -c ${jobId}|grep -Pv '^$'|tail -1|at ${newTime};
	atrm ${jobId};
}
function addMinutesToAtJob() {
	local jobId="$1";
	if [[ "" == "$1" || ! $jobId =~ ^[1-9][0-9]*$ ]]; then
		echo "E: addMinutesToAtJob(): Invalid jobId '${jobId}'; aborting...";
		return -1;
	fi

	local minutesToAdd="$2";
	if [[ "" == "$2" || ! $minutesToAdd =~ ^[\-\+][1-9][0-9]*$ ]]; then
		echo "E: addMinutesToAtJob(): Invalid minutesToAdd '${minutesToAdd}'; expected a plus sign followed by a number of minutes, e.g. '+30'. Aborting...";
		return -2;
	fi

	local jobExists=$(/usr/bin/atq|grep -Pc "^${jobId}\\b");
	if [[ "1" != "${jobExists}" ]]; then
		echo "E: addMinutesToAtJob(): No AT jobs with jobId '${jobId}'; aborting...";
		return -3;
	fi
	local currentScheduleDate=$(/usr/bin/atq|grep -P "^${jobId}\\s+"|sed -E 's/[1-9][0-9]*\s+(Mon|T[hu][eu]|Wed|Fri|S[au][nt])\s+(J[au][nl]|Feb|Ma[ry]|A[up][rg]|Sep|Oct|Nov|Dec)\s+([0-3]?[0-9])\s+([0-2][0-9]:[0-5][0-9]):.*$/\2 \3/g');
	local currentSchedule24HourTime=$(/usr/bin/atq|grep -P "^${jobId}\\s+"|sed -E 's/[1-9][0-9]*\s+(Mon|T[hu][eu]|Wed|Fri|S[au][nt])\s+(J[au][nl]|Feb|Ma[ry]|A[up][rg]|Sep|Oct|Nov|Dec)\s+[0-3]?[0-9]\s+([0-2][0-9]:[0-5][0-9]):.*$/\3/g');
	local todaysDate=$(date --date 'today' +'%b %d');
	local tomorrowsDate=$(date --date 'tomorrow' +'%b %d');

	local newTime="";
	if [[ "$currentScheduleDate" == "${todaysDate}" ]]; then
		newTime=$(date --date "${currentSchedule24HourTime} today ${minutesToAdd} minute" +'%I:%M%p %b %d');
	elif [[ "$currentScheduleDate" == "${tomorrowsDate}" ]]; then
		newTime=$(date --date "${currentSchedule24HourTime} tomorrow ${minutesToAdd} minute" +'%I:%M%p %b %d');
	else
		newTime=$(date --date "${currentSchedule24HourTime} ${currentScheduleDate} ${minutesToAdd} minute" +'%I:%M%p %b %d');
	fi

	at -c ${jobId}|grep -Pv '^$'|tail -1|at ${newTime};
	atrm ${jobId};
}
#==========================================================================
# End Section: Process and window functions
#==========================================================================

#==========================================================================
# Start Section: Hardware functions
#==========================================================================
function printBatteryPercentages() {
	# this assumes that you only have 1 wireless device

	# 1. Get info from upower; this won't have everything (missing xbox 360 wireless)
	#		but it should have wireless kb/m and possibly some wireless controllers
	#
	#	1.1. get the dump from upower
	#	1.2. remove any info blocks for 'daemon'; they don't have any worthwhile info anyway
	#			perl -0 -pe 's/(?:^|\n\n)Daemon:.*?\n\n/\n/gsm'
	#	1.3. remove any device attribute lines not related to either model or (battery) percentage
	#		 while simultaneously reformatting
	#			perl -ne 'if ( /^$/ ) { print "\n" } elsif ( /^.*model:[ \t]+(.*)$/ ) { print "$1: " } elsif ( /^.*percentage:[ \t]+(.*)$/ ) { print "$1" }'

	upower --dump | perl -0 -pe 's/(?:^|\n\n)Daemon:.*?\n\n/\n/gsm' | perl -ne 'if ( /^$/ ) { print "\n" } elsif ( /^.*model:[ \t]+(.*)$/ ) { print "$1: " } elsif ( /^.*percentage:[ \t]+(.*)$/ ) { print "$1" }' | sed '/^$/d';
}
function unmuteAllAlsaAudioControls() {
	local INITIAL_IFS="$IFS";
	IFS='';
	amixer scontrols | sed "s|[^']*\('[^']*'\).*|\1|g" |
	while read control_name
	do
		if [[ "'Auto-Mute Mode'" ==  "$control_name" || "'Input Source'" ==  "$control_name" ]]; then
			#Skip these ones -- not really valid sources
			continue;
		fi
		#echo "control name: $control_name";
		amixer -q set "$control_name" 100% unmute;
		if [[ "0" != "$?" ]]; then
			echo "Error unmuting control name: $control_name";
		fi
	done
	IFS="$INITIAL_IFS";
}
#==========================================================================
# End Section: Hardware functions
#==========================================================================

#==========================================================================
# Start Section: Service functions
#==========================================================================
function stopSystemdServices() {
	for passedarg in "$@"; do
		#echo "passedarg is $passedarg"
		sudo systemctl stop $passedarg
	done
}
function disableSystemdServices() {
	for passedarg in "$@"; do
		#echo "passedarg is $passedarg"
		sudo systemctl disable $passedarg
	done
}
function stopAndDisableSystemdServices() {
	for passedarg in "$@"; do
		#echo "passedarg is $passedarg"
		sudo systemctl stop $passedarg
		sudo systemctl disable $passedarg
	done
}
function enableSystemdServices() {
	for passedarg in "$@"; do
		#echo "passedarg is $passedarg"
		sudo systemctl enable $passedarg
	done
}
function restartSystemdServices() {
	for passedarg in "$@"; do
		#echo "passedarg is $passedarg"
		sudo systemctl restart $passedarg
	done
}
function enableAndRestartSystemdServices() {
	for passedarg in "$@"; do
		#echo "passedarg is $passedarg"
		sudo systemctl enable $passedarg
		sudo systemctl restart $passedarg
	done
}
#==========================================================================
# End Section: Service functions
#==========================================================================

#==========================================================================
# Start Section: Launcher functions
#==========================================================================
function openGitExtensionsBrowse() {
	#launch background process
	(cd "$1"; /usr/bin/gitext >/dev/null 2>/dev/null;)&
}
function openFileInTextEditor() {
	openFileInSublime "$1";
}
function openFileInSublime() {
	#launch background process
	(/usr/bin/sublime "$1" >/dev/null 2>/dev/null;)&
}
function openFileInXed() {
	#launch background process
	(/usr/bin/xed "$1" >/dev/null 2>/dev/null;)&
}
function mergeFilesInMeld() {
	#launch background process
	(/usr/bin/meld "$1" "$2" >/dev/null 2>/dev/null;)&
}
function openNemo() {
	#launch background process
	(/usr/bin/nemo "$1" >/dev/null 2>/dev/null)&
}
#==========================================================================
# End Section: Launcher functions
#==========================================================================

#==========================================================================
# Start Section: Reference functions
#==========================================================================
# colorize man pages. See: https://www.ryanschulze.net/archives/2113
function man() {
	LESS_TERMCAP_mb=$(tput setaf 4)\
	LESS_TERMCAP_md=$(tput setaf 4;tput bold) \
	LESS_TERMCAP_so=$(tput setaf 7;tput setab 4;tput bold) \
	LESS_TERMCAP_us=$(tput setaf 6) \
	LESS_TERMCAP_me=$(tput sgr0) \
	LESS_TERMCAP_se=$(tput sgr0) \
	LESS_TERMCAP_ue=$(tput sgr0) \
	command man "$@"
}
function referenceGroupCommands() {
	# -------------------------------------------------------------------------------------------------
	# References:
	# https://www.howtogeek.com/50787/add-a-user-to-a-group-or-second-group-on-linux/
	# man find
	# 2>&- usage:
	#	https://unix.stackexchange.com/a/19433, https://stackoverflow.com/a/20564208, https://unix.stackexchange.com/a/131833
	# -------------------------------------------------------------------------------------------------

	echo "Group Administration Commands:";
	echo "======================================================================================================";
	echo " sudo groupadd GROUP            # create new group 'GROUP' ";
	echo " sudo groupadd -g 1337 GROUP    # create new group 'GROUP' with groupid (gid) as 1337 ";
	echo " sudo groupadd --system GROUP   # create new system group 'GROUP' (groupid will be in SYS_GID_MIN-SYS_GID_MAX range)";
	echo "";
	echo "# adds existing user 'USER' to existing group 'GROUP' ";
	echo "# Note: this doesn't normally take effect until user logs out/back in ";
	echo "# but can be forced to take effect in the same session"
	echo "# by running 'newgrp GROUP' from the newly added user"
	echo " sudo usermod -a -G GROUP USER";
	echo " sudo usermod -aG GROUP USER";
	echo " sudo gpasswd -a USER GROUP";
	echo " sudo gpasswd --add USER GROUP";
	echo "";
	echo "# adds existing user 'USER' to a list of muliple groups 'GROUP1' and 'GROUP2'";
	echo " sudo usermod -a -G GROUP1,GROUP2 USER";
	echo "";
	echo "# removes existing user 'USER' from existing group 'GROUP'";
	echo " sudo gpasswd -d USER GROUP";
	echo " sudo gpasswd --delete USER GROUP";
	echo "";
	echo "# remove the user 'USER' from any groups not explicitly listed";
	echo " sudo usermod -G USER USER         # User 'USER' will belong to *only* the default group 'USER' ";
	echo " sudo usermod -G USER,GROUP2 USER  # User will belong to *only* to groups 'USER' and 'GROUP2' ";
	echo "";
	echo " sudo usermod -g GROUP USER              # change the primary group of user 'USER' to group 'GROUP'";
	echo " sudo useradd -G GROUP USER              # create new user 'USER' and adds to existing group 'GROUP'";
	echo " sudo groupdel GROUP                     # delete group 'GROUP'";
	echo " sudo groupmod -n NEWGROUP OLDGROUP      # rename group 'OLDGROUP' to 'NEWGROUP'";
	echo "";
	echo " groups                                  # list the groups current user account is assigned to";
	echo " groups USER                             # list the groups user 'USER' is assigned to";
	echo " members GROUP                           # list the members of group 'GROUP'";
	echo " getent group                            # list all groups on system";
	echo " getent group GROUP                      # list details for group 'GROUP'";
	echo " getent group|grep -v nobody|grep -P ':[1-9]\\d{3,}:'  # list all groups on system with gids > 1000";
	echo " cat /etc/group                          # manually query group file (don't modify as this could corrupt system)";
	echo " sudo chgrp [-R] GROUP FILE              # change group ownership to GROUP for file FILE";
	echo " find . ! -perm /g=w 2>/dev/null         # find files that the owner can't write to";
	echo " find . ! -perm /g=w 2>&-                # find files that the owner can't write to (alternate)";
	echo " find . ! -group GROUP 2>/dev/null              # find files not owned by group 'GROUP'";
	echo " find . ! -group GROUP 2>&-                     # find files not owned by group 'GROUP' (alternate)";
	echo " find . -group GROUP ! -perm /g=w 2>/dev/null   # find unwritable files owned by group 'GROUP'";
	echo " find . -group GROUP ! -perm /g=w 2>&-          # find unwritable files owned by group 'GROUP' (alternate)";
	echo "";
	echo "# Useful aliases:";
	echo "  groupsref | groupsdoc                  # this help text";
	echo "  lsgroups                               # display non-service groups and their members";
	echo "  lsallgroups                            # display all groups and their members (sorted by id)";
	echo "  lsallgroupsbyname                      # display all groups and their members (sorted by name)";
	echo "";
}
function referenceUserCommands() {
	# -------------------------------------------------------------------------------------------------
	# References:
	# https://www.howtogeek.com/50787/add-a-user-to-a-group-or-second-group-on-linux/
	# man useradd
	# man usermod
	# man find
	# 2>&- usage:
	#	https://unix.stackexchange.com/a/19433, https://stackoverflow.com/a/20564208, https://unix.stackexchange.com/a/131833
	# -------------------------------------------------------------------------------------------------

	# on some systems such as fedora, "adduser" is just a symlink to
	# the "useradd" command. On other systems such as Debian/Mint/Ubuntu,
	# these are two separate binaries.
	# This matters for displaying reference commands because the 2 binaries
	# accept slightly different arguments and on systems where both commands
	# point to "useradd", passing arguments intended for the "adduser" binary
	# can cause the command to fail and return an error.
	local isAddUserSymlink=0;
	if [[ "$(which useradd)" == "$(realpath $(which adduser))"  ]]; then
		isAddUserSymlink=1;
	fi


	echo "User Administration Commands:";
	echo "=========================================================================================================";
	echo "# Create new user 'USER' with LAN access but no local login (reqs running passwd before login):";
	if [[ '0' == "$isAddUserSymlink" ]]; then
		echo "  sudo adduser --gecos \"\" --no-create-home --disabled-login --shell /bin/false USER";
	else
		echo "  sudo useradd --system --no-create-home --inactive 0 --shell /bin/false USER";
	fi

	echo "";
	echo "# Create new user 'USER' (w home dir, login enabled, reqs running passwd before login):";
	echo "  sudo useradd -m [-g GROUP] [-s SHELL] USER";
	echo "  sudo useradd --create-home [-gid GROUP] [--shell SHELL] USER";
	echo "  sudo usermod [-g GROUP] [-s SHELL] USER";
	echo "";
	echo "# Create new user with default password (only use for initial pwd as this is viewable in .bash_history):";
	echo "  sudo useradd -m [-g GROUP] [-s SHELL] -p PASSWD_HASH USER";
	echo "  sudo useradd --create-home [-gid GROUP] [--shell SHELL] -password PASSWD_HASH USER";
	echo "  sudo usermod [-g GROUP] [-s SHELL] -p PASSWD_HASH USER";
	echo "    ex: sudo useradd -m -p \$(echo 'abcd1234'|mkpasswd -m sha-512 -S saltsalt -s) USER";
	echo "";
	echo "# Create new user 'USER' (no home dir, login disabled, reqs running passwd before login):";
	echo "  sudo useradd --system [-g GROUP]  [-s SHELL] USER";
	echo "  sudo useradd --system -f 0 -M [-g GROUP]  [-s SHELL] USER";
	echo "  sudo useradd --system --no-create-home --inactive 0 [--gid GROUP] [--shell SHELL] USER";
	echo "  sudo usermod -L [-g GROUP] [-s SHELL] USER";
	echo "  sudo usermod --lock [--gid GROUP] [--shell SHELL] USER";
	echo "";
	echo "# Move home directory of user 'USER' to NEWHOME:";
	echo "  sudo usermod -m -d NEWHOME -m USER";
	echo "  sudo usermod --move-home --home NEWHOME -m USER";
	echo "";
	echo "# Rename user 'OLDUSER' to 'NEWUSER' (no change to homedir, no change to groupname/group ownership):";
	echo "  sudo usermod -l NEWUSER OLDUSER";
	echo "  sudo usermod --login NEWUSER OLDUSER";
	echo "";
	echo "# Rename user 'OLDUSER' to 'NEWUSER' AND move homedir to NEWHOME (no change to groupname/group ownership):";
	echo "  sudo usermod -m -d NEWHOME -l NEWUSER OLDUSER";
	echo "  sudo usermod --move-home --home NEWHOME --login NEWUSER OLDUSER";
	echo "";
	echo "# Delete user 'USER' (but leave their home dir):";
	echo "  sudo userdel USER";
	echo "";
	echo "# Delete user 'USER' (and remove their home dir):";
	echo "  sudo userdel -r USER";
	echo "";
	echo " id                                      # get id of current user";
	echo " id USER                                 # get id of user 'USER'";
	echo " whoami                                  # display name of current user";
	echo " who --all                               # display logged in users (includes ssh but not terminals spawned by current user)";
	echo " finger USER                             # display basic information about user 'USER'";
	echo " ssh USER@localhost                      # login to user 'USER' on local machine";
	echo " ssh USER@127.0.0.1                      # login to user 'USER' on local machine";
	echo " su - USER                               # switch to user 'USER' from terminal (reboot req'd for new users)";
	echo " exit                                    # return to initial terminal (after successfully using either of the previous 3 commands)";
	echo " su - USER -c COMMAND [args]             # run command as user 'USER'";
	echo " passwd                                  # change password for the current user";
	echo " sudo passwd USER                        # change password for user 'USER'";
	echo " sudo passwd --expire USER               # force user 'USER' to change their password next time they log in";
	echo " groups                                  # list the groups current user account is assigned to";
	echo " groups USER                             # list the groups user 'USER' is assigned to";
	echo " getent passwd                           # list all users on system (including service accounts)";
	echo " getent passwd USER                      # list details for user 'USER'";
	echo " getent passwd|grep -v nobody|grep -P ':[1-9]\\d{3,}:'  # list all users on system with uids > 1000";
	echo " cat /etc/passwd                         # manually query user file (don't modify as this could corrupt system)";
	echo " sudo chown [-R] USER:GROUP FILE         # change ownership to USER:GROUP for file FILE";
	echo " sudo chown [-R] USER FILE               # change ownership to USER for file FILE";
	echo " find . ! -perm /u=w 2>/dev/null         # find files that the owner can't write to";
	echo " find . ! -perm /u=w 2>&-                # find files that the owner can't write to (alternate)";
	echo " find . ! -user USER 2>/dev/null              # find files not owned by user 'USER'";
	echo " find . ! -user USER 2>&-                     # find files not owned by user 'USER' (alternate)";
	echo " find . -user USER ! -perm /u=w 2>/dev/null   # find unwritable files owned by user 'USER'";
	echo " find . -user USER ! -perm /u=w 2>&-          # find unwritable files owned by user 'USER' (alternate)";
	echo " wall MESSAGE_TEXT                       # broadcast message to all remotely loggged in users (e.g. ssh users)";
	echo " wall -g GROUP MESSAGE_TEXT              # broadcast message to remotely loggged in users in group 'GROUP'";
	echo " sudo pgrep -a -u USER                   # list all processes run by user 'USER'";
	echo " sudo pkill -9 -u USER                   # kill all processes run by user 'USER' (also kicks user login)";
	echo " sudo killall -9 -u USER                 # kill all processes run by user 'USER' (alternate; also kicks user login)";
	echo " sudo chsh -s /bin/false USER            # disable future logins by user 'USER'"
	echo " sudo chsh -s /usr/sbin/nologin USER     # disable future logins by user 'USER' (alternate)"
	echo " sudo smbpasswd -a \"smb_user_name\"     # create a samba user";
	echo " sudo pdbedit -L -v|grep smb_user_name   # verify user exists in samba database";
	echo "";
	echo "# Useful aliases:";
	echo "  usersref | usersdoc                    # this help text";
	echo "  lsusers                                # display non-service account users, their home dirs, and their shells";
	echo "  lsallusers                             # display all users, their home dirs, and their shells (sorted by id)";
	echo "  lsallusersbyname                       # display all users, their home dirs, and their shells (sorted by name)";
	echo "";
}
function referencePermissions() {
	echo "Permission Administration Commands:";
	echo "=======================================";
	echo "# Ownership";
	echo " sudo chown [-R] USER:GROUP FILE         # change ownership to USER:GROUP for file FILE";
	echo " sudo chown [-R] USER FILE               # change ownership to USER for file FILE";
	echo " sudo chgrp [-R] GROUP FILE              # change group ownership to GROUP for file FILE";
	echo "";
	echo "# Access Controls";
	echo " sudo chown [-R] OCTAL_PERMS FILE        # change permissions for file FILE";
	echo " sudo chown [-R] PERM_ABBREV FILE        # change permissions for file FILE";
	echo "";
	echo "# Octal Permission Legend";
	echo "  Octal perms can be given as 3- or 4-digit numbers. When given as 4 digit numbers, ";
	echo "  focus on the 3 right-most positions for the typical access control permissions.";
	echo "";
	echo "  The values in each position are considered separately rather than as a whole.";
	echo "  So 777 is not seven hundred seventy seven but rather 7-7-7.";
	echo "  Each of those numbers represents the permissions for a set of users:"
	echo "    U-- => the 3rd digit from the right (U) = user permissions (for the user owning the file)";
	echo "    -G- => the 2nd digit from the right (G) = group permissions (for the group owning the file)";
	echo "    --O => the 1st digit from the right (O) = other user permissions";
	echo "";
	echo "  The individual values for any set of users can range from 0 (no perms) to 7 (full perms)";
	echo "  Just start with 0 and add the numerical values of whatever permissions you want. The values";
	echo "  of the various permissions are as follows:";
	echo "    0 == No Permissions";
	echo "    1 == Execute permission (needed by all folders; needed to run programs; not needed for regular files)";
	echo "    2 == Write permission (needed to write, delete, or modify a file)";
	echo "    4 == Read permission (needed to read, view, or access a file)";
	echo "  so:";
	echo "    Read (4) + Nothing (0)             == 4";
	echo "    Read (4) + Execute (1)             == 5";
	echo "    Read (4) + Write (2)               == 6";
	echo "    Read (4) + Write (2) + Execute (1) == 7";
	echo ""
	echo "  some examples with the full Octal code can be read as:";
	echo "    777 = User can Read+Write+Execute (7), Group can Read+Write+Execute (7), Others can Read+Write+Execute (7)";
	echo "    755 = User can Read+Write+Execute (7), Group can Read+Execute (5), Others can Read+Execute (5)";
	echo "    766 = User can Read+Write+Execute (7), Group can Read+Write (6), Others can Read+Write (6)";
	echo "    640 = User can Read+Write (0), Group can Read (4), Others have no perms (0)";
	echo "";
	echo "# Octal Permission Examples";
	echo "  chmod 000 FILE => ---------- FILE ";
	echo "  chmod 100 FILE => ---x------ FILE ";
	echo "  chmod 200 FILE => --w------- FILE ";
	echo "  chmod 300 FILE => --wx------ FILE ";
	echo "  chmod 400 FILE => -r-------- FILE ";
	echo "  chmod 500 FILE => -r-x------ FILE ";
	echo "  chmod 600 FILE => -rw------- FILE ";
	echo "  chmod 700 FILE => -rwx------ FILE ";
	echo "  chmod 770 FILE => -rwxrwx--- FILE ";
	echo "  chmod 777 FILE => -rwxrwxrwx FILE ";
	echo "";
	echo "";
	echo "# Permission Abbreviations Legend";
	echo "  Alternately, you can skip Octal and just use abbreviations such as u=r. When doing so,";
	echo "  you'll specify 2 sets of letters: the letters on the left indicate which set of users";
	echo "  the permission applies to and the letters on the right indicate the actual perms.";
	echo "  There are also some special flags that can be set this way that yu cannot set with Octal codes";
	echo "";
	echo "  target letters (left side) - these are case-sensitive:";
	echo "    u: user";
	echo "    g: group";
	echo "    o: other";
	echo "    a: all (same as user + group + owner)";
	echo "";
	echo "  access letters (right side) - these are case-sensitive:";
	echo "    r: read";
	echo "    w: write";
	echo "    x: execute";
	echo "    s: sticky bit with execute (setuid bit for user, setgid bit for group, no meaning for others)";
	echo "    S: sticky bit without execute (setuid bit for user, setgid bit for group, no meaning for others)";
	echo "       -> Don't use S/s without reading up on them."
	echo "  so:";
	echo "    Read (r) + Nothing (nothing        == r";
	echo "    Read (r) + Execute (x)             == rx";
	echo "    Read (r) + Write (w)               == rw";
	echo "    Read (r) + Write (w) + Execute (x) == rwx";
	echo ""
	echo "  You can use equals (=) to set, plus (+) to add, and minus (-) to remove permissions."
	echo "  Equals sets to the exact value specified, plus only adds what is specified, and"
	echo "  minus only removes what is specified. Any non-conflicting combination of these can be used."
	echo "  some examples with the full Octal code can be read as:";
	echo "    a=rwx         : Set Read+Write+Execute (rwx) for All Users (User+Group+Others)";
	echo "    a+rx,u+w,go-w : Add Read+Execute (rx) for All Users (User+Group+Others), Add Write for User (u+w), ";
	echo "                    and Remove Write for Group and Others (go-w)";
	echo "    u=rwx,go=rx   : Set Read+Write+Execute for User(u=rwx), Read+Execute for Group/Others (go=rx)";
	echo "    ug=rwx,o=r    : Set Read+Write+Execute for User/Group (ug=rwx), Read for Others (o=r)";
	echo "    u=rw,g=r,o=   : Set Read+Write for User (u=rw), Read for Group (g=r), no perms for Others (o=)";
	echo "    a-x,u+rw,g+r,g-w,o-rw   : Remove execute for all (a-x), add Read+Write for User (u+rw),";
	echo "                              add Read for Group (g+r), remove Write for Group (g-w),";
	echo "                              remove Read+Write for Others (o-rw)";
	echo "";
	echo " # Permission Abbreviation Examples";
	echo "  chmod a=      FILE => ---------- FILE ";
	echo "  chmod a=x     FILE => ---x--x--x FILE ";
	echo "  chmod a=r     FILE => -r--r--r-- FILE ";
	echo "  chmod a=w     FILE => --w--w--w- FILE ";
	echo "  chmod a=rw    FILE => -rw-rw-rw- FILE ";
	echo "  chmod a=rwx   FILE => -rwxrwxrwx FILE ";
	echo "  chmod u=x     FILE => ---x------ FILE ";
	echo "  chmod u=w     FILE => --w------- FILE ";
	echo "  chmod u=wx    FILE => --wx------ FILE ";
	echo "  chmod u=r     FILE => -r-------- FILE ";
	echo "  chmod u=rx    FILE => -r-x------ FILE ";
	echo "  chmod u=rw    FILE => -rw------- FILE ";
	echo "  chmod u=rwx   FILE => -rwx------ FILE ";
	echo "  chmod gu=wrx  FILE => -rwxrwx--- FILE ";
	echo "  chmod ugo=xrw FILE => -rwxrwxrwx FILE ";
	echo "";
}
function referenceOctalPermissions() {
	if [[ '--abbrev' == "$1" ]]; then
		echo '1=x, 2=x, 4=r, 5=rx, 6=rw, 7=rwx';
		return 0;
	fi
	echo "Octal Permission Examples:";
	echo "====================================";
	echo "  chmod 000 FILE => ---------- FILE ";
	echo "  chmod 100 FILE => ---x------ FILE ";
	echo "  chmod 200 FILE => --w------- FILE ";
	echo "  chmod 300 FILE => --wx------ FILE ";
	echo "  chmod 400 FILE => -r-------- FILE ";
	echo "  chmod 500 FILE => -r-x------ FILE ";
	echo "  chmod 600 FILE => -rw------- FILE ";
	echo "  chmod 700 FILE => -rwx------ FILE ";
	echo "";

	echo "Common Octal Permissions:";
	echo "====================================";
	echo "  chmod 400 FILE => -r-------- FILE ";
	echo "  chmod 440 FILE => -r--r----- FILE ";
	echo "  chmod 444 FILE => -r--r--r-- FILE ";
	echo "";
	echo "  chmod 500 FILE => -r-x------ FILE ";
	echo "  chmod 540 FILE => -r-xr----- FILE ";
	echo "  chmod 544 FILE => -r-xr--r-- FILE ";
	echo "  chmod 550 FILE => -r-xr-x--- FILE ";
	echo "  chmod 554 FILE => -r-xr-xr-- FILE ";
	echo "  chmod 555 FILE => -r-xr-xr-x FILE ";
	echo "";
	echo "  chmod 600 FILE => -rw------- FILE ";
	echo "  chmod 640 FILE => -rw-r----- FILE ";
	echo "  chmod 644 FILE => -rw-r--r-- FILE ";
	echo "  chmod 660 FILE => -rw-rw---- FILE ";
	echo "  chmod 664 FILE => -rw-rw-r-- FILE ";
	echo "  chmod 666 FILE => -rw-rw-rw- FILE ";
	echo "";
	echo "  chmod 700 FILE => -rwx------ FILE ";
	echo "  chmod 740 FILE => -rwxr----- FILE ";
	echo "  chmod 744 FILE => -rwxr--r-- FILE ";
	echo "  chmod 750 FILE => -rwxr-x--- FILE ";
	echo "  chmod 755 FILE => -rwxr-xr-x FILE ";
	echo "  chmod 770 FILE => -rwxrwx--- FILE ";
	echo "  chmod 775 FILE => -rwxrwxr-x FILE ";
	echo "  chmod 777 FILE => -rwxrwxrwx FILE ";
	echo "";
}
function referenceVim() {
	echo 'Vi/Vim Cheatsheet';
	echo '======================================================================';
	echo 'Exit file if no changes made                       -    :q';
	echo 'Exit file and discard changes                      -    :q!';
	echo 'Save (Write) file and exit                         -    :x';
	echo 'Save (Write) file and exit                         -    :wq';
	echo 'Save (Write) file and exit                         -    :ZZ';
	echo 'Save (Write) file                                  -    :w';
	echo 'Save (Write) to a new file                         -    :w newfile';
	echo 'Discard changes (reload saved file)                -    :e!';
	echo '';
	echo 'Enter INSERT mode                                  -    i';
	echo 'Exit  INSERT mode                                  -    Esc';
	echo '';
	echo 'Non-Insert mode (aka normal mode) commands:';
	echo '----------------------------------------------------------------------';
	echo 'Delete single line at caret                        -    dd';
	echo 'Delete 10 lines starting at caret                  -    10dd';
	echo 'Yank (copy) a single line at caret                 -    yy';
	echo 'Yank (copy) 10 lines starting at caret             -    10yy';
	echo 'Paste yanked (copied) line(s) after line at caret  -    (lowercase) p';
	echo 'Paste yanked (copied) line(s) before line at caret -    (uppercase) P';
	echo '';
	echo 'Go to line number 14                               -    :14';
	echo '';
	echo 'Search by POSIX regex pattern                      -    :/pattern';
	echo 'Find next occurrence of pattern                    -    (lowercase) n';
	echo 'Find previous occurrence of pattern                -    (uppercase) N';
	echo 'Replace all occurrences of pattern with replace    -    :%s/pattern/replace/g';
	echo 'Replace all but with confirmations                 -    :%s/pattern/replace/gc';
	echo '';
	echo 'Go to start of line                                -    ^';
	echo 'Go to end of line                                  -    $';
	echo '';
	echo 'Undo last command                                  -    u';
	echo 'Redo last undo                                     -    Ctrl+U';
	echo '';
	echo 'Indent line by one tab character                   -    >';
	echo 'Un-indent line by one tab character                -    <';
	echo '';
	echo 'Show line numbers                                  -    :set number';
	echo 'Hide line numbers                                  -    :set nonumber';
	echo '';
	echo 'Sort lines 10-40                                   -    :10,40 !sort';
	echo '';
}
function referenceVimRc() {
	echo '----------------------------------------------------------------------';
	echo 'VIMRC (~/.vimrc) Cheatsheet:'
	echo '----------------------------------------------------------------------';
	echo '# Note that .vimrc only recognizes lines starting with a double-quote character (") as comment lines';
	echo '# BUT I will be also be intermittently using pound sign (#) as a comment here. If you use # in ~/.vimrc';
	echo '# it will not be treated as a comment and will cause an error.';
	echo '# Also any of these commands can also be set/overridden in normal mode by preceding the command with a colon.';
	echo '#     e.g. :set number';
	echo '# The colon is allowed but optional in the .vimrc file';
	echo '';
	echo '" leave this alone - compatible disables lots of vim features and puts it in backwards compatible mode';
	echo 'set nocompatible';
	echo '';
	echo '" Remap Ctrl+S to write (:w) to avoid locking terminal. Note: if this happens use Ctrl+Q to resume.';
	echo '" May also require dealing with stty issues by adding the following to ~/.bashrc: stty -ixon';
	echo ':nnoremap <c-s> :w<CR>';
	echo ':inoremap <c-s> <Esc>:w<CR>a';
	echo '';
	echo '" Make backspace work like in most other editors';
	echo "\" May also require dealing with stty issues by adding the following to ~/.bashrc: stty erase '^?'";
	echo 'set backspace=indent,eol,start';
	echo '';
	echo '#See http://vimcasts.org/episodes/tabs-and-spaces/';
	echo 'set tabstop=4      # Specifies the displayed width of a tab character, in spaces';
	echo 'set expandtab      # When enabled, causes spaces to be used in place of tab characters';
	echo 'set noexpandtab    # To explicitly disable expandtab (it is disabled by default)';
	echo 'set softtabstop=0  # fine tunes the amount of whitespace to be inserted in normal mode and number of spaces to delete with backspace when using expandtab.';
	echo 'set shiftwidth=4   # defines the amount of whitespace to be inserted during auto-indents.';
	echo '';
	echo 'softtabstop can also be abbreviated as sts such as set sts=0';
	echo 'tabstop can also be abbreviated as ts such as set ts=4';
	echo 'shiftwidth can also be abbreviated as sw such as set sts=4';
	echo '';
	echo '# If you prefer to work with tab characters then it is a good idea to ensure that tabstop == softtabstop';
	echo '# If you prefer to work with spaces, then it is preferable to ensure that softtabstop == shiftwidth. This way, you can expect the same number of spaces to be inserted whether you press the tab key in insert mode, or use the indentation commands in normal/visual modes.';
	echo '';
	echo '" Recommended setting for users who prefer to use tabs most of the time:';
	echo '" Make tabs 4 spaces wide and do not replace tabs with spaces';
	echo 'set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab';
	echo '';
	echo '" Permanently enable line numbers in margin. note that these are included when copying text from terminal.';
	echo 'set number';
	echo '';
	echo '" Enable syntax highlighting';
	echo 'syntax on';
	echo '';
	echo '" Fix bug in newer versions of vim where it ignores "highlight Comment"';
	echo '" https://vi.stackexchange.com/questions/4044/vimrc-contents-selectively-i-e-highlight-ignored';
	echo 'set background=light';
	echo '';
	echo '" Change the color of commented blocks to green (default is a light blue very similar to variable names)';
	echo ':highlight Comment ctermfg=DarkGreen';
	echo '';
}
function referenceSELinux() {
	#
	# See:
	#	https://howto.lintel.in/enable-disable-selinux-centos/
	#	https://linuxconfig.org/how-to-disable-enable-selinux-on-ubuntu-20-04-focal-fossa-linux
	#	https://www.tecmint.com/setup-samba-file-sharing-for-linux-windows-clients/
	#	https://ask.fedoraproject.org/t/how-to-setup-samba-on-fedora-the-easy-way/2551/19
	#	https://linux.die.net/man/8/samba_selinux
	#	https://www.linuxquestions.org/questions/linux-server-73/how-to-share-ntfs-partition-to-other-computers-using-samba-919827/
	#	https://www.tecmint.com/setup-samba-file-sharing-for-linux-windows-clients/
	#	https://reticent.net/sharing-an-ntfs-partition-with-samba-and-selinux/
	#	https://www.thegeekdiary.com/understanding-selinux-file-labelling-and-selinux-context/
	#	https://www.thegeekdiary.com/what-are-selinux-users-and-how-to-map-linux-users-to-selinux-users/
	#
	echo '----------------------------------------------------------------------';
	echo 'SELinux Cheatsheet:'
	echo '----------------------------------------------------------------------';
	echo '# get the status of a system running SELinux.'
	echo 'sestatus'
	echo ''
	echo '# Run the following to query the current status of SELinux.'
	echo '#     enforcing - SELinux security policy is enforced.'
	echo '#     permissive - SELinux prints warnings instead of enforcing.'
	echo '#     disabled - No SELinux policy is loaded.'
	echo 'getenforce';
	echo '';
	echo '# To change the SELinux status while it is running:';
	echo 'setenforce [ Enforcing or 1 | Permissive or 0 ]';
	echo '';
	echo '# To enable SELinux on Ubuntu/Mint/Debian-based systems';
	echo 'sudo apt install policycoreutils selinux-utils selinux-basics';
	echo 'sudo selinux-activate';
	echo 'sudo selinux-config-enforcing';
	echo 'sudo reboot';
	echo '';
	echo '# To permanently change status of SELinux, edit the';
	echo '# /etc/selinux/config file and change the value of';
	echo '# SELINUX=xxx as indiciated in the files contents';
	echo '# then reboot the system.';
	echo '';
	echo '# Allow samba to access the filesystem';
	echo 'sudo setsebool -P samba_export_all_ro=1 samba_export_all_rw=1'
	echo 'sudo setsebool -P samba_share_fusefs=1'
	echo '';
	echo '# Add the "samba_share_t" SELinux file context for a given path';
	echo 'sambaShare="/path/to/share/as-defined-in-smb.conf/definition"';
	echo 'sudo semanage fcontext --add --type "samba_share_t" "${sambaShare}(/.*)?"';
	echo 'sudo restorecon -R "${sambaShare}"';
	echo '';
	echo '# Remove the "samba_share_t" SELinux file context for a given path';
	echo 'sambaShare="/path-to-be-removed-from-selinux-whitelist"'
	echo 'sudo semanage fcontext --delete --type "samba_share_t" "${sambaShare}(/.*)?"';
	echo 'sudo restorecon -R "${sambaShare}"';
	echo '';
	echo '# View which file context(s) are defined for a given file/folder';
	echo 'ls -Z /path/to/file';
	echo 'ls -ldZ /path/tofolder/';
	echo '';
	echo '# View SELinux context information about processes';
	echo 'ps -Z';
	echo '';
	echo '# View SELinux context information about users';
	echo '# SELinux context is displayed by using the following syntax:';
	echo '# user:role:type:level';
	echo 'id -Z';
	echo '';
	echo '# View a list of mappings between SELinux and Linux user accounts';
	echo 'sudo semanage login -l';
	echo '';
}
function referencePackageManagement() {
	local hasApt=0;
	local hasAptCache=0;
	local hasAptFile=0;
	local hasAptGet=0;
	local hasAptitude=0;
	local hasDnf=0;
	local hasDpkg=0;
	local hasPacman=0;
	local hasRpm=0;
	local hasYum=0;
	local hasZypper=0;

	# ----------------------------------------------------------------
	# begin initialization
	[[ -f /usr/bin/apt ]] && hasApt=1;
	[[ -f /usr/bin/apt-cache ]] && hasAptCache=1;
	[[ -f /usr/bin/apt-file ]] && hasAptFile=1;
	[[ -f /usr/bin/apt-get ]] && hasAptGet=1;
	[[ -f /usr/bin/aptitude ]] && hasAptitude=1;
	[[ -f /usr/bin/dnf ]] && hasDnf=1;
	[[ -f /usr/bin/dpkg ]] && hasDpkg=1;
	[[ -f /usr/bin/pacman ]] && hasPacman=1;
	[[ -f /usr/bin/rpm ]] && hasRpm=1;
	# on fedora 33, yum is just a symlink to dnf and should be ignored
	[[ -f /usr/bin/yum && "$(realpath /usr/bin/dnf 2>/dev/null)" != "$(realpath /usr/bin/yum 2>/dev/null)" ]] && hasYum=1;
	[[ -f /usr/bin/zypper ]] && hasZypper=1;
	# end initialization
	# ----------------------------------------------------------------
	# start template
	# echo '# action to perform';
	# [[ 1 == $hasApt ]] && echo "APT UNDEFINED";
	# [[ 1 == $hasAptGet ]] && echo "APT-GET UNDEFINED";
	# [[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	# [[ 1 == $hasDnf ]] && echo "DNF UNDEFINED";
	# [[ 1 == $hasDpkg ]] && echo "DPKG UNDEFINED";
	# [[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	# [[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	# [[ 1 == $hasYum ]] && echo "YUM UNDEFINED";
	# [[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	# echo '';
	# end template
	# ----------------------------------------------------------------

	echo '# install a package';
	[[ 1 == $hasApt ]] && echo "apt install PACKAGENAME";
	[[ 1 == $hasAptGet ]] && echo "apt-get install PACKAGENAME";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf install PACKAGENAME";
	[[ 1 == $hasDpkg ]] && echo "DPKG UNDEFINED";
	[[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	[[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	[[ 1 == $hasYum ]] && echo "YUM UNDEFINED";
	[[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	echo '';

	echo '# remove a package';
	[[ 1 == $hasApt ]] && echo "apt remove PACKAGENAME";
	[[ 1 == $hasAptGet ]] && echo "apt-get remove PACKAGENAME";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf remove PACKAGENAME";
	[[ 1 == $hasDpkg ]] && echo "DPKG UNDEFINED";
	[[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	[[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	[[ 1 == $hasYum ]] && echo "YUM UNDEFINED";
	[[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	echo '';

	echo '# search available packages';
	[[ 1 == $hasApt ]] && echo "apt search PACKAGENAME";
	[[ 1 == $hasAptGet ]] && echo "APT-GET UNDEFINED";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf search PACKAGENAME";
	[[ 1 == $hasDpkg ]] && echo "DPKG UNDEFINED";
	[[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	[[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	[[ 1 == $hasYum ]] && echo "YUM UNDEFINED";
	[[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	echo '';

	echo '# list all installed packages';
	[[ 1 == $hasApt ]] && echo "APT UNDEFINED";
	[[ 1 == $hasAptGet ]] && echo "APT-GET UNDEFINED";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf list installed";
	[[ 1 == $hasDnf ]] && echo "dnf history userinstalled";
	[[ 1 == $hasDpkg ]] && echo "DPKG UNDEFINED";
	[[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	[[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	[[ 1 == $hasYum ]] && echo "YUM UNDEFINED";
	[[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	echo '';

	echo '# list all updateable packages';
	[[ 1 == $hasApt ]] && echo "APT UNDEFINED";
	[[ 1 == $hasAptGet ]] && echo "APT-GET UNDEFINED";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf list --updates";
	[[ 1 == $hasDnf ]] && echo "dnf list --upgrades";
	[[ 1 == $hasDpkg ]] && echo "DPKG UNDEFINED";
	[[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	[[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	[[ 1 == $hasYum ]] && echo "YUM UNDEFINED";
	[[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	echo '';

	echo '# update specific packages';
	[[ 1 == $hasApt ]] && echo "APT UNDEFINED";
	[[ 1 == $hasAptGet ]] && echo "APT-GET UNDEFINED";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf update PACKAGENAME";
	[[ 1 == $hasDnf ]] && echo "dnf upgrade PACKAGENAME";
	[[ 1 == $hasDpkg ]] && echo "DPKG UNDEFINED";
	[[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	[[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	[[ 1 == $hasYum ]] && echo "YUM UNDEFINED";
	[[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	echo '';

	echo '# list installed package version';
	[[ 1 == $hasApt ]] && echo "APT UNDEFINED";
	[[ 1 == $hasAptGet ]] && echo "APT-GET UNDEFINED";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf info PACKAGENAME";
	[[ 1 == $hasDnf ]] && echo "dnf info installed --cacheonly --quiet PACKAGENAME";
	[[ 1 == $hasDnf ]] && echo "dnf list PACKAGENAME";
	[[ 1 == $hasDnf ]] && echo "dnf list installed --cacheonly --quiet PACKAGENAME";
	[[ 1 == $hasDnf ]] && echo "dnf repoquery --installed PACKAGENAME";
	[[ 1 == $hasDpkg ]] && echo "dpkg -l PACKAGENAME";
	[[ 1 == $hasPacman ]] && echo "pacman -Qs PACKAGENAME";
	[[ 1 == $hasRpm ]] && echo "rpm -qa  PACKAGENAME";
	[[ 1 == $hasYum ]] && echo "yum list installed --cacheonly --quiet PACKAGENAME";
	[[ 1 == $hasZypper ]] && echo "zypper se --installed-only PACKAGENAME";
	echo '';

	echo '# list available package version';
	[[ 1 == $hasApt ]] && echo "APT UNDEFINED";
	[[ 1 == $hasAptCache ]] && echo "apt-cache policy PACKAGENAME";
	[[ 1 == $hasAptGet ]] && echo "APT-GET UNDEFINED";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf list available --quiet PACKAGENAME";
	[[ 1 == $hasDnf ]] && echo "dnf repoquery --available PACKAGENAME";
	[[ 1 == $hasDpkg ]] && echo "DPKG UNDEFINED";
	[[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	[[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	[[ 1 == $hasYum ]] && echo "yum list available --quiet PACKAGENAME";
	[[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	echo '';

	echo '# list files from installed package';
	[[ 1 == $hasApt ]] && echo "APT UNDEFINED";
	[[ 1 == $hasAptGet ]] && echo "APT-GET UNDEFINED";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf repoquery --installed --list PACKAGENAME";
	[[ 1 == $hasDpkg ]] && echo "dpkg -L PACKAGENAME";
	[[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	[[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	[[ 1 == $hasYum ]] && echo "YUM UNDEFINED";
	[[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	echo '';

	echo '# add repo url';
	[[ 1 == $hasApt ]] && echo "APT UNDEFINED";
	[[ 1 == $hasAptGet ]] && echo "APT-GET UNDEFINED";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/33/winehq.repo";
	[[ 1 == $hasDpkg ]] && echo "DPKG UNDEFINED";
	[[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	[[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	[[ 1 == $hasYum ]] && echo "YUM UNDEFINED";
	[[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	echo '';

	echo '# list package management history';
	[[ 1 == $hasApt ]] && echo "APT UNDEFINED";
	[[ 1 == $hasAptGet ]] && echo "APT-GET UNDEFINED";
	[[ 1 == $hasAptitude ]] && echo "APTITUDE UNDEFINED";
	[[ 1 == $hasDnf ]] && echo "dnf history";
	[[ 1 == $hasDnf ]] && echo "dnf history list";
	[[ 1 == $hasDnf ]] && echo "dnf history list PACKAGENAME";
	[[ 1 == $hasDpkg ]] && echo "DPKG UNDEFINED";
	[[ 1 == $hasPacman ]] && echo "PACMAN UNDEFINED";
	[[ 1 == $hasRpm ]] && echo "RPM UNDEFINED";
	[[ 1 == $hasYum ]] && echo "YUM UNDEFINED";
	[[ 1 == $hasZypper ]] && echo "ZYPPER UNDEFINED";
	echo '';

	# https://linux-audit.com/determine-file-and-related-package/
	# https://bbs.archlinux.org/viewtopic.php?id=90635
	# https://askubuntu.com/questions/481/how-do-i-find-the-package-that-provides-a-file
	echo '# discover which package a file belongs to';
	[[ 1 == $hasAptFile ]] && echo "apt-file find \$(which FILE)";
	[[ 1 == $hasAptFile ]] && echo "apt-file search \$(which FILE)";
	[[ 1 == $hasDnf ]] && echo "dnf provides --quiet \$(which FILE)";
	[[ 1 == $hasDnf ]] && echo "dnf whatprovides --quiet \$(which FILE)";
	[[ 1 == $hasDnf ]] && echo "repoquery -f \$(which FILE) # if not available, install yum-utils";
	[[ 1 == $hasDpkg ]] && echo "dpkg -S \$(which FILE)";
	[[ 1 == $hasPacman ]] && echo "pacman -Qo \$(which FILE)";
	[[ 1 == $hasPacman ]] && echo "sudo pkgfile -u && pkgfile \$(which FILE) # from the pkgtools package";
	[[ 1 == $hasRpm ]] && echo "rpm -qf \$(which FILE)";
	[[ 1 == $hasRpm ]] && echo "rpm --queryformat '%{NAME}\n' -qf \$(which FILE)";
	[[ 1 == $hasYum ]] && echo "yum whatprovides \$(which FILE)";
	[[ 1 == $hasZypper ]] && echo "zypper what-provides \$(which FILE)";
	[[ 1 == $hasZypper ]] && echo "zypper wp \$(which FILE)";
	[[ 1 == $hasZypper ]] && echo "zypper se --provides --match-exact \$(which FILE)";
	echo '';
}
function referenceDocker() {
	#
	# See:
	#	https://docs.docker.com/storage/storagedriver/
	#
	#
	#
	#
	echo '# View default docker local storage area:';
	echo 'ls -acl /var/lib/docker';
	echo '';
	echo '';
	echo '';
}
function referenceSecureDelete() {
	if [[ 'debian' != "${BASE_DISTRO}" && 'fedora' != "${BASE_DISTRO}" ]]; then
		echo "E: referenceSecureDelete() has not been updated to work with non-debian distros.";
		return -1;
	fi

	echo 'There are several tools for securely deleting files/folders under Linux.';
	echo 'Here are some examples:';
	echo '';
	echo '# secure delete a single file';
	echo 'wipe filename';
	echo '';
	echo '# secure delete a file, overwriting 200 times instead of the default 25';
	echo 'shred -n 200 file';
	echo '';
	echo '# secure delete a file, overwrite with zeros to hide overwriting; do 200 times';
	echo 'shred -zu -n 200 file';
	echo '';
	echo '';
	echo '# Required:';
	echo '# install secure-delete or srm from your package manager';
	if [[ 'fedora' != "${BASE_DISTRO}" ]]; then
		echo '# 	sudo dnf install -y srm';
	elif [[ 'debian' != "${BASE_DISTRO}" ]]; then
		echo '# 	sudo apt-get install -y secure-delete';
	fi
	echo '# remove files or directories securely';
	echo '# (-v is verbose; -z wipes using zeros for the last write to hide overwriting)';
	echo 'srm -vzr folder';
	echo 'srm -vzr folder1 folder2 folder3 ...';
	echo '';
	echo '';
}
function referenceCryptoCiphers() {
	echo 'Here are some differences of common ciphers and where they are used.';
	echo 'To see ciphers available in gpg run: gpg --version';

	echo '';
	echo '# password protected tar files. see:';
	echo '# https://www.putorius.net/how-to-create-enrcypted-password.html';
	echo '# 1. encypt archive';
	echo 'tar czvpf - file1.txt file2.pdf file3.jpg | gpg --symmetric --cipher-algo aes256 -o myarchive.tar.gz.gpg';
	echo '';
	echo '# 2. decrypt archive';
	echo 'gpg -d myarchive.tar.gz.gpg | tar xzvf -';

	echo '';
	echo '# Abbreviations';
	echo 'AES = Advanced Encryption Standard (a subset of Rijndael)';
	echo 'DES = Data Encryption Standard (deprecated in favor of AES)';
	echo 'IDEA = International Data Encryption Algorithm';

	# Sources:
	#	https://paragonie.com/blog/2019/03/definitive-2019-guide-cryptographic-key-sizes-and-algorithm-recommendations
	#	https://www.jscape.com/blog/stream-cipher-vs-block-cipher
	#	https://en.wikipedia.org/wiki/Block_size_(cryptography)
	#	https://en.wikipedia.org/wiki/International_Data_Encryption_Algorithm
	#	https://crypto.stackexchange.com/questions/31632/what-is-the-difference-between-key-size-and-block-size-for-aes
	#	https://www.linux-magazine.com/Online/Features/Protect-your-Documents-with-GPG
	#	https://www.solarwindsmsp.com/blog/aes-256-encryption-algorithm
	#	https://en.wikipedia.org/wiki/CAST-128
	#	https://en.wikipedia.org/wiki/Camellia_(cipher)
	#	https://crypto.stackexchange.com/questions/52914/cryptographic-algorithms-comparison-aes-vs-camellia
	#	http://www.differencebetween.net/technology/difference-between-aes-and-twofish
	#	https://crypto.stackexchange.com/questions/43586/aes-vs-other-types-of-encryption-such-as-twofish
	#	https://qvault.io/2019/07/09/is-aes-256-quantum-resistant/

	echo '==============================================================================================================';
	echo 'Cipher Algorithms';
	echo '==============================================================================================================';
	echo 'Algorithms should not be evaluated solely on max key size. Block size is also an important factor.';
	echo 'Blowfish has a higher max key size than AES but is worse because its blocksize is smaller than that of AES.';
	echo 'Twofish is theoretically unbreakable. AES256 can theoretically be broken but it is very impractical to do so.';
	echo 'However, AES256 is much more efficient than Twofish and thus has been more widely adopted.';
	echo 'Quantum computers are not expected to be effective against AES256.';
	echo '';
	echo 'TODO: Rank from best to worst';
	echo 'ALGORITHM      MAX KEY SIZE        BLOCK SIZE       NOTES';
	echo '--------------------------------------------------------------------------------------------------------------';
	echo 'AES256         256 bits            128 bits';
	echo 'TWOFISH        256 bits            128 bits         Roughly equiv to AES256 but slower and not as widely used';
	echo 'CAMELLIA256    256 bits            128 bits         Roughly equiv to AES256 but slower and not as widely used';
	echo 'AES192         192 bits            128 bits';
	echo 'CAMELLIA192    192 bits            128 bits';
	echo 'AES            128 bits            128 bits';
	echo 'CAMELLIA128    128 bits            128 bits';
	echo 'BLOWFISH       448 bits             64 bits          Small blocksize, High Mem Usage';
	echo '3DES           168 bits             64 bits          SLOW';
	echo 'IDEA           128 bits             64 bits';
	echo 'CAST5          128 bits             64 bits';
	echo '';
	echo '';

	echo '';
	echo '==============================================================================================================';
	echo 'Public Key Algorithms';
	echo '==============================================================================================================';
	echo 'Quantum computers are expected to be very effective against RSA 2048 (breakable in 8 hours).';
	echo '';
	echo '';
	echo '';
	echo 'TODO: Rank from best to worst';
	echo 'ALGORITHM      MAX KEY SIZE        BLOCK SIZE       NOTES';
	echo '--------------------------------------------------------------------------------------------------------------';
	echo 'RSA 4096';
	echo 'RSA 2048';

	echo 'Diffie Hellman';
	echo 'ECC';
	echo '';
	echo '';
	echo '';

	echo '';
}
#==========================================================================
# End Section: Reference functions
#==========================================================================
