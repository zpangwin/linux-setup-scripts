#!/bin/bash

if [[ "" == "$1" || ! -f "$1" ]]; then
    notify-send "Unable to extract mp3 audio; no file specified"
    exit;
fi

fullPathToFile="$1";
fullPathToFileWithoutExt="${fullPathToFile%.*}";
fileNameWithoutPath=$(basename "$fullPathToFile");
fileNameWithoutPathOrExt="${fileNameWithoutPath%.*}";

#check if more than 8306688 bytes (8mb × 1014 kb/mb × 1024 b/kb)
displayBigFileNoticiation="false";
fileSizeInBytes=$(/usr/bin/stat -c%s "${fullPathToFile}" 2>/dev/null);


if [[ "" != "${fileSizeInBytes}" && $fileSizeInBytes -ge 8306688 ]]; then
    displayBigFileNoticiation="true";
fi

notify-send "Extracting mp3 audio from $fileNameWithoutPath"
if [[ "true" == "${displayBigFileNoticiation}" ]]; then
    notify-send "Due to the filesize, Extracting audio for ${fileNameWithoutPath} may take some time. Another notification will appear after this is complete."
fi

ffmpeg -i "${fullPathToFile}" -vn -acodec libmp3lame -ac 2 -ab 160k -ar 48000 "${fullPathToFileWithoutExt}.mp3";

notify-send "Finished extracting audio to ${fileNameWithoutPathOrExt}.mp3"

