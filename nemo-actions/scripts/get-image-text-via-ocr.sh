#!/bin/bash

if [[ "" == "$1" || ! -f "$1" ]]; then
    exit;
fi

#prepare variables based on input
input_file_path="$1";
input_file_name="${input_file_path##*/}";
parent_dir=$(dirname "$input_file_path")
file_name_no_ext="${input_file_name%.*}";
final_output_path="${parent_dir}/${file_name_no_ext}.txt";

#attempt to prevent clobbering
if [[ -f "${final_output_path}" ]]; then
    timestamp="`date +%m%d%y%H%M`";
    final_output_path="${parent_dir}/${file_name_no_ext}-${timestamp}.txt";
fi

#make sure temp subdir exists
tmp_dir="/tmp/ocr-conversion";
if [[ ! -e "${tmp_dir}" ]]; then
    mkdir "${tmp_dir}" 2>/dev/null;
    chmod 777 "${tmp_dir}" 2>/dev/null;
fi

#prepare variables for temp files
PID=$$
output_base_name="${tmp_dir}/${file_name_no_ext}-${PID}";
pnm_file="${output_base_name}.pnm";
stretched_pnm_file="${output_base_name}-stretched.pnm";
tif_file="${output_base_name}-output600dpi.tif";
#note the extensiion will be appended automatically by tesseract
txt_file="${output_base_name}-raw-ocr-dump";

#do conversions then dump text
convert "${input_file_path}" "${pnm_file}";
cat "${pnm_file}" | pamstretch 4 > "${stretched_pnm_file}"
convert "${stretched_pnm_file}" -colorspace gray "${tif_file}" 
tesseract "${tif_file}" "${txt_file}" -l eng 
rm "${pnm_file}" "${stretched_pnm_file}" "${tif_file}"

#update var to iclude the extension added by tesseract
txt_file="${txt_file}.txt";

#Attempt to clean up junk lines:
chmod u+rw "${txt_file}";
perl -p -i -e 's/^(\W+|ee|\[s|[ \t]+)$//g' "${txt_file}";

#trim excess blank lines
cat -s "${txt_file}" > "${final_output_path}";
rm "${txt_file}"

#Fix permissions
chmod --reference="${input_file_path}" "${final_output_path}";


