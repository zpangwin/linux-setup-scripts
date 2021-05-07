#!/bin/bash
#=======================================================================================
# This is a template file with several useful snippets.
# Keep what you want and delete the rest.
# You can run this script safely without altering anything on the filesystem or OS
# Note: It will still create a *new* launcher (*.desktop) file under ~/Desktop
#=======================================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
echo "SCRIPT_DIR is $SCRIPT_DIR";

FILE_TO_OPEN="$1";
if [[ "" == "${FILE_TO_OPEN}" || ! -e "${FILE_TO_OPEN}" ]]; then
    echo "Error: no arg passed or path does not exist";
fi

FILE_NAME=$(basename "${FILE_TO_OPEN}");

FILE_URI=$(echo "${FILE_TO_OPEN}" | perl -MURI::file -e 'print URI::file->new(<STDIN>)."\n"');

LAUNCHER_NAME="${FILE_NAME}.desktop";
if [[ -e "${HOME}/Desktop/${LAUNCHER_NAME}" ]] ;then
    LAUNCHER_NAME="";
    for i in {1..100}; do
        if [[ ! -e "${HOME}/Desktop/${FILE_NAME} (${i}).desktop" ]]; then
            LAUNCHER_NAME="${FILE_NAME} (${i}).desktop";
            break;
        fi
    done;
fi
LAUNCHER_PATH="${HOME}/Desktop/${LAUNCHER_NAME}";
ICON_PATH="";

FILE_EXT=$(echo ${FILE_NAME##*.}|tr '[:upper:]' '[:lower:]');

if [[ "gif" == "${FILE_EXT}" || "jpeg" == "${FILE_EXT}" || "jpg" == "${FILE_EXT}" || "png" == "${FILE_EXT}" ]]; then
   ICON_PATH="${FILE_TO_OPEN}"
fi

IS_AV_FILE="false";
if [[ $FILE_EXT =~ ^m[kp][34v]$ || $FILE_EXT =~ ^m4[ab]$ || $FILE_EXT =~ ^wm[av]$ || "ogg" == "${FILE_EXT}" || "flac" == "${FILE_EXT}" ]]; then
    IS_AV_FILE="true";
    IS_FFMPEG_INSTALLED=$(which ffmpeg|wc -l);
    if [[ "1" == "${IS_FFMPEG_INSTALLED}" ]]; then
        EXTRACTED_THUMBS_DIR="${HOME}/.local/share/icons/extracted-thumbs";
        mkdir -p "${EXTRACTED_THUMBS_DIR}" 2>/dev/null;
        ICON_PATH="${EXTRACTED_THUMBS_DIR}/${FILE_NAME}.jpg";
        if [[ ! -f "${ICON_PATH}" ]]; then
            ffmpeg -loglevel quiet -i "${FILE_TO_OPEN}" "${ICON_PATH}" 2>&1 >/dev/null;
        fi
    fi
fi

# See documentation here:
# https://specifications.freedesktop.org/desktop-entry-spec/latest/ar01s06.html
#

echo '#!/usr/bin/env xdg-open' >> "${LAUNCHER_PATH}";
echo '[Desktop Entry]' >> "${LAUNCHER_PATH}";
echo 'Version=1.0' >> "${LAUNCHER_PATH}";
echo 'Terminal=false' >> "${LAUNCHER_PATH}";
echo 'StartupNotify=true' >> "${LAUNCHER_PATH}";
echo 'X-MultipleArgs=false' >> "${LAUNCHER_PATH}";
echo "Name=${FILE_NAME}" >> "${LAUNCHER_PATH}";

#echo 'Type=Application' >> "${LAUNCHER_PATH}";


if [[ -f "${FILE_TO_OPEN}" ]]; then
    echo 'Type=Link' >> "${LAUNCHER_PATH}";
    echo "URL=${FILE_URI}" >> "${LAUNCHER_PATH}";

    # The Exec= is not needed; I am only adding it because the documentation recommends to do so for better compatibility
    echo "Exec=xdg-open '${FILE_TO_OPEN}'" >> "${LAUNCHER_PATH}";

elif [[ -d "${FILE_TO_OPEN}" ]]; then
    echo 'Type=Directory' >> "${LAUNCHER_PATH}";
    echo "Exec=nemo '${FILE_TO_OPEN}'" >> "${LAUNCHER_PATH}";
    echo 'Icon=folder' >> "${LAUNCHER_PATH}";
fi
if [[ "" != "${ICON_PATH}" && -f "${ICON_PATH}" ]]; then
    # Note the icon will not work if it uses a quoted path. It seems to work fine with spaces and the limited number
    # of special characters that I tested with (square brackets and exclaimation point)
    echo "Icon=${ICON_PATH}" >> "${LAUNCHER_PATH}";
fi


