################################################################
## Shell script : Script Name: CSS/JS Path Replacer #
## Description: Iterates through all directories to replace strings found in CSS and JS files. #
##      Place this bash script in the directory where the files reside. #
##      For example: /resources. #
## Author: Weber Team!
## Copy Right: @2011 Weber Team!
################################################################

#!/bin/bash

# Take the search string.
read -p "Enter the search string: " search

# Take the replace string.
read -p "Enter the replace string: " replace

FILES="./**/*.php ./**/*.html ./**/*.md"
SEARCH_FOLDER="./*"

for filename in $(find $SEARCH_FOLDER -type f \( -name "*php" -o -name "*html" \));
do
    echo "Processing $filename file..."
    if [ -f "$filename" ]; then
        if [[ $search != "" && $replace != "" ]]; then
            sed -i "s/$search/$replace/gi" $filename
        fi
    fi
done;

grep -rnw $SEARCH_FOLDER -e "$search" --include=*.*
