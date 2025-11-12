#!/bin/bash

# find "${1}" -maxdepth 1 -mindepth 1 -type d -exec zip -r "{}.zip" "{}" \;

# https://unix.stackexchange.com/questions/68489/command-to-zip-multiple-directories-into-individual-zip-files
# for i in */public_html/; do zip -r "${i%/public_html/}.zip" "$i"; done
# for i in */; do zip -r "${i%/}.zip" "$i"; done

cd /media/disk1/backup.ip161.sources/web2shop/domains/ && \
    for i in */public_html/; do (echo $i && cd $i && zip -r4uy ../../"${i%/public_html/}.zip" . -x wp-config.php && echo "${i%/public_html/}.zip" && cd -); done