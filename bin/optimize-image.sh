#!/usr/bin/env bash

# sudo yum install jpegoptim optipng pngquant gifsicle libwebp-tools ImageMagick
# sudo apt install jpegoptim optipng pngquant gifsicle libwebp-tools ImageMagick
# Resize        bash optimize-image.sh -s 1920
# Compress      bash optimize-image.sh -q 75 (png/jpg)
# Compress      bash optimize-image.sh -q 3 (webp)

# https://github.com/VirtuBox/img-optimize/blob/master/optimize.sh
# https://github.com/VirtuBox/img-optimize.git
# https://linuxcommando.blogspot.com/2014/09/how-to-optimize-png-images.html
# https://www.hibit.dev/posts/45/compressing-png-images-on-linux
# https://pngquant.org
# https://imagemagick.org/script/convert.php#google_vignette
# https://imagemagick.org/script/command-line-processing.php

########################################################################
## A script to prepare images (screenshots) for inclusion in articles to
## be submitted to opensource.com for publication. It does the following
##   - reduces width to meet OSDC 600 pixel limit
##   - adds a border
##   - places finished images into a "Ready" directory
AUTHOR='Visual Weber Developer Team'
CREATED='Jun 30, 2023'
UPDATED='Jun 30, 2023'
VERSION='0.1'
########################################################################

# Run following command to optimize your images
# find . -type f -iname '*.jpeg' -print0 |  xargs -0 -n 1 -P 6 /usr/bin/jpegoptim -v -f --max=80 --all-progressive --strip-all --preserve --totals --force
# find . -type f -iname '*.jpg'  -print0 |  xargs -0 -n 1 -P 6 /usr/bin/jpegoptim -v -f --max=80 --all-progressive --strip-all --preserve --totals --force

## To make file handling a little easier, I recommend using the GNOME
## extension named Screenshot Tool. It allows configuration of the
## directory location where screenshots will be saved.
## Reference: https://extensions.gnome.org/extension/1112/screenshot-tool/
## For this script, configure to save screenshots in the directory shown below:

platform='unknown'

NORMAL="\\033[0;39m"
BLINKING="\\033[5m"
VERT="\\033[1;32m"
ROUGE="\\033[1;31m"
BLUE="\\033[1;34m"
ORANGE="\\033[1;33m"
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

## Linux bin paths, change this if it can not be autodetected via which command
BIN="/usr/bin"
CWEBP="$($BIN/which cwebp)"
JPEGOPTIM="$($BIN/which jpegoptim)"
PNGQUANT="$($BIN/which pngquant)"
FFMPEG="$($BIN/which ffmpeg)"
MAGICK="$($BIN/which convert)"
CP="$($BIN/which cp)"
SSH="$($BIN/which ssh)"
CD="$($BIN/which cd)"
GIT="$($BIN/which git)"
LN="$($BIN/which ln)"
MV="$($BIN/which mv)"
RM="$($BIN/which rm)"
NGINX="/etc/init.d/nginx"
MKDIR="$($BIN/which mkdir)"
MYSQL="$($BIN/which mysql)"
MYSQLDUMP="$($BIN/which mysqldump)"
CHOWN="$($BIN/which chown)"
CHMOD="$($BIN/which chmod)"
GZIP="$($BIN/which gzip)"
ZIP="$($BIN/which zip)"
FIND="$($BIN/which find)"
TOUCH="$($BIN/which touch)"
PERL="$($BIN/which perl)"
CURL="$($BIN/which curl)"
HASCURL=1
DEVMODE="--no-dev"
PHPCOPTS=" -d memory_limit=-1 "
SED="$($BIN/which sed)"

os=${OSTYPE//[0-9.-]*/}
if [[ "$os" == 'darwin' ]]; then
    platform='macosx'
elif [[ "$os" == 'msys' ]]; then
    platform='window'
elif [[ "$os" == 'linux' ]]; then
    platform='linux'
fi
echo -e "${VERT}You are using $platform ${NORMAL}"

[ -z "$PHP" ] && PHP="$(which php)"

###
## SOURCE="${BASH_SOURCE[0]}"
## while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
##   DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
##   SOURCE="$(readlink "$SOURCE")"
##   [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
## done
## DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
## cd $DIR
## SCRIPT_PATH=`pwd -P` # return wrong path if you are calling this script with wrong location
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # return ...path/bin
echo -e "${VERT}--> Your installed path: ${SCRIPT_PATH}${NORMAL}"

# begin asking for path of images
echo -e "What is the path of images you want to optimize ?${NORMAL}"
echo -e "Enter the images path:"
read -r path
while :; do
    if [[ -z $path ]]; then
        echo -e "--> Please enter your path, such as:${ROUGE} ${SCRIPT_PATH}${NORMAL}"
        read -r path
    else
        [[ -e $path ]]
        SCRIPT_PATH="${path}"
        SCRIPT_PATH=${SCRIPT_PATH##*( )}
        break # break the for looop
    fi
done

# SCREENSHOTS=${SCREENSHOTS:-"$SCRIPT_PATH/../public/storage"}    # return ...path/bin/../public/storage/
SCREENSHOTS=${SCREENSHOTS:-"$SCRIPT_PATH"} # return ...path/bin/../public/storage/
READY=${SCREENSHOTS}                       # READY=${READY:-"$SCREENSHOTS/../"}
BORDER=${BORDER:-black}
VERBOSE=0
MAXWIDTH=1921
# end asking for path of images

# Begin Prevent multi execution on same directory
lock=$(echo -n "${SCRIPT_PATH}" | md5sum | cut -d" " -f1)
if [ -f "/tmp/$lock" ]; then
    echo -e "${ROUGE}--> Locked: /tmp/$lock${NORMAL}, please remove this locked file before running your script"
    exit 1
else
    touch "/tmp/$lock"
    echo -e "${ROUGE}--> Locked: /tmp/$lock${NORMAL}"
fi
# End Prevent multi execution on same directory

# begin conditions
if [ ! -d "${SCRIPT_PATH}" ]; then
    echo -e "${BLINKING}${ROUGE}$SCREENSHOTS${NORMAL} is not a directory"
    exit 1
fi

if [ -z "$(ls -A ${SCREENSHOTS})" ]; then
    echo -e "${BLINKING}${ROUGE}${NORMAL}No images found."
    exit 1
else
    mkdir -p "${READY}" || true
fi
# end conditions

##### BEGIN YOUR FUNCTIONS
set -e ## exit on most errors
create_dir() {
    mkdir -p "${SCREENSHOTS}" || true
}

echo -e "--> Path installed :${ROUGE} ${SCREENSHOTS}${NORMAL}"

command -v sips >/dev/null || {
    echo -e "${ROUGE}--> sips command not found.${NORMAL}"
    # exit
}
command -v stat >/dev/null || {
    echo -e "${ROUGE}--> stat command not found.${NORMAL}"
    # exit
}
command -v ffmpeg >/dev/null || {
    echo -e "${ROUGE}--> MP4 "ffmpeg" command not found.${NORMAL}"
    echo -e "${ROUGE}--> CENTOS: sudo yum install epel-release ${NORMAL}"
    # echo -e "${ROUGE}--> CENTOS: sudo yum localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm ${NORMAL}"
    echo -e "${ROUGE}--> CENTOS: sudo yum install ffmpeg ffmpeg-devel ${NORMAL}"
    # exit
}
command -v identify >/dev/null || {
    echo -e "${ROUGE}--> identify command not found.${NORMAL}"
    echo -e "${ROUGE}--> CENTOS: sudo yum install jpegoptim optipng pngquant gifsicle libwebp-tools ImageMagick ${NORMAL}"
    echo -e "${ROUGE}--> UBUNTU: sudo apt install jpegoptim optipng pngquant gifsicle webp imagemagick ${NORMAL}"
    exit
}
command -v convert >/dev/null || {
    echo -e "${ROUGE}--> RESIZE "convert" command not found.${NORMAL}"
    echo -e "${ROUGE}--> CENTOS: sudo yum install jpegoptim optipng pngquant gifsicle libwebp-tools ImageMagick ${NORMAL}"
    echo -e "${ROUGE}--> UBUNTU: sudo apt install jpegoptim optipng pngquant gifsicle webp imagemagick ${NORMAL}"
    exit
}
command -v jpegoptim >/dev/null || {
    echo -e "${ROUGE}--> JPG/JPEG "jpegoptim" command not found.${NORMAL}"
    echo -e "${ROUGE}--> CENTOS: sudo yum install jpegoptim optipng pngquant gifsicle libwebp-tools ImageMagick ${NORMAL}"
    echo -e "${ROUGE}--> UBUNTU: sudo apt install jpegoptim optipng pngquant gifsicle webp imagemagick ${NORMAL}"
    exit
}
command -v pngquant >/dev/null || {
    echo -e "${ROUGE}--> PNG "pngquant" command not found.${NORMAL}"
    echo -e "${ROUGE}--> CENTOS: sudo yum install jpegoptim optipng pngquant gifsicle libwebp-tools ImageMagick ${NORMAL}"
    echo -e "${ROUGE}--> UBUNTU: sudo apt install jpegoptim optipng pngquant gifsicle webp imagemagick ${NORMAL}"
    exit
}
command -v cwebp >/dev/null || {
    echo -e "${ROUGE}--> WEBP "cwebp" command not found.${NORMAL}"
    echo -e "${ROUGE}--> CENTOS: sudo yum install jpegoptim optipng pngquant gifsicle libwebp-tools ImageMagick ${NORMAL}"
    echo -e "${ROUGE}--> UBUNTU: sudo apt install jpegoptim optipng pngquant gifsicle webp imagemagick ${NORMAL}"
    exit
}

asking_path() {
    echo -e "${BLUE}== asking_path is running ${NORMAL}"
    # begin asking for path
    local OPTIND OPTARG OPTERR p opt
    while getopts ":p:" opt; do
        case "${opt}" in
        p)
            MAXWIDTH="$OPTARG"
            MAXWIDTH=${MAXWIDTH##*( )}
            echo -e "Processing option '-s ${MAXWIDTH}' with max-width is '${OPTARG} pixel' argument"
            ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ -z "$MAXWIDTH" ]; then
        echo -e "Enter the max-width percent, eg) 1920, 1080 ...:"
        read -r maxwidth
        while :; do
            if [[ -z $maxwidth ]]; then
                echo -e "${ROUGE}--> Please enter your max-width, such as:${ROUGE} 1920${NORMAL}"
                read -r maxwidth
            else
                [[ -e $maxwidth ]]
                MAXWIDTH="${maxwidth}"
                MAXWIDTH=${MAXWIDTH##*( )}
                break # break the for looop
            fi
        done
    fi
    # end asking for maxwidth
}

asking_maxsize() {
    echo -e "${BLUE}== asking_maxsize is running, maximum default is 1921 pixel ${NORMAL}"
    # begin asking for maxwidth
    local OPTIND OPTARG OPTERR s opt
    while getopts ":s:" opt; do
        case "${opt}" in
        s)
            MAXWIDTH="$OPTARG"
            MAXWIDTH=${MAXWIDTH##*( )}
            echo -e "Processing option '-s ${MAXWIDTH}' with max-width is '${OPTARG} pixel' argument"
            ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ -z "$MAXWIDTH" ]; then
        echo -e "Enter the max-width percent, eg) 1920, 1080 ...:"
        read -r maxwidth
        while :; do
            if [[ -z $maxwidth ]]; then
                echo -e "${ROUGE}--> Please enter your max-width, such as:${ROUGE} 1920${NORMAL}"
                read -r maxwidth
            else
                [[ -e $maxwidth ]]
                MAXWIDTH="${maxwidth}"
                MAXWIDTH=${MAXWIDTH##*( )}
                break # break the for looop
            fi
        done
    fi
    # end asking for maxwidth
}

asking_quality() {
    echo -e "${BLUE}== asking_quality is running${NORMAL}"
    # begin asking for quality
    local OPTIND OPTARG OPTERR q opt
    while getopts ":q:" opt; do
        case "${opt}" in
        q)
            COMPRESS_QUALITY="$OPTARG"
            COMPRESS_QUALITY=${COMPRESS_QUALITY##*( )}
            echo -e "Processing option '-q ${COMPRESS_QUALITY}' with '${OPTARG}%' argument"
            ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ -z "$COMPRESS_QUALITY" ]; then
        echo -e "Enter the quality percent, eg) 75, 85 (default: 75):"
        read -r quality
        
        # Nếu user không nhập gì, dùng default
        if [[ -z $quality ]]; then
            COMPRESS_QUALITY=75
            echo -e "${VERT}--> Using default quality: 75${NORMAL}"
        else
            # Validate number
            if [[ "$quality" =~ ^[0-9]+$ ]] && [ "$quality" -ge 1 ] && [ "$quality" -le 100 ]; then
                COMPRESS_QUALITY="${quality}"
                COMPRESS_QUALITY=${COMPRESS_QUALITY##*( )}
            else
                echo -e "${ROUGE}❌ Invalid quality! Using default: 75${NORMAL}"
                COMPRESS_QUALITY=75
            fi
        fi
    fi
    # end asking for quality
}

image_resize() {
    echo -e "${BLUE}== image_resize is running${NORMAL}"
    # verify that file is an image file, and then get dimensions
    # webp đôi khi cho ra định dạng image/webp và application/octet-stream, vì vấn đề của thư viện imagemagic khi upload

    FILE_NAMEA=$(basename "${1}")
    FILE_NAMEB="${FILE_NAMEA%.*}"
    FILE_DIR="$(dirname "${1}")"
    
    # kiểm tra file webp có hợp lệ không
    if [[ "${1}" =~ \.webp$ ]]; then
        if ! dwebp "$1" -o /dev/null >/dev/null 2>&1; then
            echo "⚠️ Skipping invalid WebP file: $1"
            return
        fi
    fi

    if file "${1}" | grep -qE 'image|bitmap' && file --mime-type -b "${1}" | grep -qE 'image|bitmap'; then
        [[ $VERBOSE -gt 0 ]] && echo "${1} is an image"
        W=$(identify -format %w "${1}")
        MIME=$(identify -format %e "${1}")
    elif file "${1}" | grep -qE 'RIFF' && file --mime-type -b "${1}" | grep -qE 'octet'; then
        [[ $VERBOSE -gt 0 ]] && echo "${1} is an image"
        W=$(identify -format %w "${1}")
        W=$(echo $W | rev | cut -d " " -f1 | rev)

        MIME=$(identify -format %e "${1}")
        MIME=$(echo $MIME | rev | cut -d " " -f1 | rev) #https://stackoverflow.com/questions/3162385/how-to-split-a-string-in-shell-and-get-the-last-field

    else
        echo -e "File ${1} is not an image."
        W=0
        return
    fi

    # resize and border if need
    echo -e "File ${1}"
    echo -e "$W x $MAXWIDTH"

    if [ "$W" -gt "$MAXWIDTH" ]; then
        echo -e "Width <= MaxWidth, reducing now"
        [[ $VERBOSE -gt 0 ]] && echo "${1} is ${W} - reducing"
        $MAGICK -resize "${MAXWIDTH}" \
            "${1}" \
            "${1}"

        # $MAGICK -resize "${MAXWIDTH}" \
        #     -bordercolor $BORDER \
        #     -border 1 \
        #     "${1}" \
        #     "${READY}"/"${1}"

        # compress
        $MAGICK -verbose -quality 75 "${1}" "${FILE_DIR}/${FILE_NAMEB}.$MIME" || true
    else
        echo -e "Width <= MaxWidth, nothing to do"
        # $MAGICK -bordercolor $BORDER \
        #     -border 1 \
        #     "${1}" \
        #     "${READY}"/"${1}"
    fi
}

compress_jpg() {
    echo -e "${BLUE}== compress_jpg is running${NORMAL}"
    echo -e "${BLUE}It may take a while${NORMAL}"
    # verify that file is an image file, and then get dimensions
    # consider output of file -b --mime-type

    # ⭐ Set default quality if not provided
    if [ -z "$COMPRESS_QUALITY" ]; then
        COMPRESS_QUALITY=80
        echo -e "${ORANGE}⚠️ Quality not set, using default: 80${NORMAL}"
    fi

    FILE_NAMEA=$(basename "${1}")
    FILE_NAMEB="${FILE_NAMEA%.*}"
    FILE_DIR="$(dirname "${1}")"

    if file "${1}" | grep -qE 'image|bitmap' && file --mime-type -b "${1}" | grep -qE 'image|bitmap'; then
        [[ $VERBOSE -gt 0 ]] && echo "${1} is an image"
        MIME=$(identify -format %e "${1}")

        FILE_SIZE=$(du -k "${1}" | cut -f1)
        # FILE_SIZE=$(stat -f%z "${1}") # only macos
        # FILE_SIZE=$(stat --printf="%s" "${1}") # only unix

    elif file "${1}" | grep -qE 'RIFF' && file --mime-type -b "${1}" | grep -qE 'octet'; then
        [[ $VERBOSE -gt 0 ]] && echo "${1} is an image"
        MIME=$(identify -format %e "${1}")
        MIME=$(echo $MIME | rev | cut -d " " -f1 | rev) #https://stackoverflow.com/questions/3162385/how-to-split-a-string-in-shell-and-get-the-last-field

        FILE_SIZE=$(du -k "${1}" | cut -f1)
        # FILE_SIZE=$(stat -f%z "${1}") # only macos
        # FILE_SIZE=$(stat --printf="%s" "${1}") # only unix
    else
        echo -e "File ${1} is not an image."
        FILE_SIZE=0

        return
    fi

    echo -e "File Dir $FILE_DIR"
    echo -e "File $FILE_NAMEA"
    echo -e "File $FILE_NAMEB"
    echo -e "File ${1}"
    echo -e "MimeType is $MIME"
    echo -e "FileSize is ${FILE_SIZE} Kb"

    # compress
    if [ $FILE_SIZE -gt 0 ] && [ $FILE_SIZE -gt 250 ]; then
        if [ "$MIME" == "jpg" ] || [ "$MIME" == "jpeg" ]; then
            $JPEGOPTIM -v -f --max=${COMPRESS_QUALITY} --all-progressive --strip-all --preserve --totals --force "${1}" || true
        fi
    fi
}
compress_png() {
    echo -e "${BLUE}== compress_png is running${NORMAL}"
    echo -e "${BLUE}It may take a while${NORMAL}"
    # verify that file is an image file, and then get dimensions
    # consider output of file -b --mime-type

    # ⭐ Set default quality if not provided
    if [ -z "$COMPRESS_QUALITY" ]; then
        COMPRESS_QUALITY=75
        echo -e "${ORANGE}⚠️ Quality not set, using default: 75${NORMAL}"
    fi

    FILE_NAMEA=$(basename "${1}")
    FILE_NAMEB="${FILE_NAMEA%.*}"
    FILE_DIR="$(dirname "${1}")"

    if file "${1}" | grep -qE 'image|bitmap' && file --mime-type -b "${1}" | grep -qE 'image|bitmap'; then
        [[ $VERBOSE -gt 0 ]] && echo "${1} is an image"
        MIME=$(identify -format %e "${1}")

        FILE_SIZE=$(du -k "${1}" | cut -f1)
        # FILE_SIZE=$(stat -f%z "${1}") # only macos
        # FILE_SIZE=$(stat --printf="%s" "${1}") # only unix

    elif file "${1}" | grep -qE 'RIFF' && file --mime-type -b "${1}" | grep -qE 'octet'; then
        [[ $VERBOSE -gt 0 ]] && echo "${1} is an image"
        MIME=$(identify -format %e "${1}")
        MIME=$(echo $MIME | rev | cut -d " " -f1 | rev) #https://stackoverflow.com/questions/3162385/how-to-split-a-string-in-shell-and-get-the-last-field

        FILE_SIZE=$(du -k "${1}" | cut -f1)
        # FILE_SIZE=$(stat -f%z "${1}") # only macos
        # FILE_SIZE=$(stat --printf="%s" "${1}") # only unix
    else
        echo -e "File ${1} is not an image."
        FILE_SIZE=0

        return
    fi

    echo -e "File Dir $FILE_DIR"
    echo -e "File $FILE_NAMEA"
    echo -e "File $FILE_NAMEB"
    echo -e "File ${1}"
    echo -e "MimeType is $MIME"
    echo -e "FileSize is ${FILE_SIZE} Kb"

    # --speed [number] --quality min-max
    if [ $FILE_SIZE -gt 0 ] && [ $FILE_SIZE -gt 250 ]; then
        if [ "$MIME" == "png" ]; then
            $PNGQUANT --verbose --quality ${COMPRESS_QUALITY} "${1}" --ext .$MIME --force || true
            # compress
            $MAGICK -verbose -quality ${COMPRESS_QUALITY} "${1}" "${FILE_DIR}/${FILE_NAMEB}.$MIME" || true
        fi
    fi
}
compress_webp() {
    echo -e "${BLUE}== compress_webp is running${NORMAL}"
    # verify that file is an image file, and then get dimensions
    # consider output of file -b --mime-type
    # webp đôi khi cho ra định dạng image/webp và application/octet-stream, vì vấn đề của thư viện imagemagic khi upload

    # ⭐ Set default quality if not provided
    if [ -z "$COMPRESS_QUALITY" ]; then
        COMPRESS_QUALITY=75
        echo -e "${ORANGE}⚠️ Quality not set, using default: 75${NORMAL}"
    fi

    FILE_NAMEA=$(basename "${1}")
    FILE_NAMEB="${FILE_NAMEA%.*}"
    FILE_DIR="$(dirname "${1}")"

    # ⭐ Validate WebP file trước khi compress
    if [[ "${1}" =~ \.webp$ ]] || [[ "${1}" =~ \.WEBP$ ]]; then
        if ! dwebp "$1" -o /dev/null >/dev/null 2>&1; then
            echo -e "${ROUGE}⚠️ Skipping invalid/corrupted WebP file: $1${NORMAL}"
            return
        fi
    fi

    if file "${1}" | grep -qE 'image|bitmap' && file --mime-type -b "${1}" | grep -qE 'image|bitmap'; then
        [[ $VERBOSE -gt 0 ]] && echo "${1} is an image"
        MIME=$(identify -format %e "${1}")

        FILE_SIZE=$(du -k "${1}" | cut -f1)
        # FILE_SIZE=$(stat -f%z "${1}") # only macos
        # FILE_SIZE=$(stat --printf="%s" "${1}") # only unix

    elif file "${1}" | grep -qE 'RIFF' && file --mime-type -b "${1}" | grep -qE 'octet'; then
        [[ $VERBOSE -gt 0 ]] && echo "${1} is an image"
        MIME=$(identify -format %e "${1}")
        MIME=$(echo $MIME | rev | cut -d " " -f1 | rev) #https://stackoverflow.com/questions/3162385/how-to-split-a-string-in-shell-and-get-the-last-field

        FILE_SIZE=$(du -k "${1}" | cut -f1)
        # FILE_SIZE=$(stat -f%z "${1}") # only macos
        # FILE_SIZE=$(stat --printf="%s" "${1}") # only unix

    else
        echo -e "File ${1} is not an image."
        FILE_SIZE=0

        return
    fi

    echo -e "File Dir $FILE_DIR"
    echo -e "File $FILE_NAMEA"
    echo -e "File $FILE_NAMEB"
    echo -e "File ${1}"
    echo -e "MimeType is $MIME"
    echo -e "FileSize is ${FILE_SIZE} Kb"

    # compress
    if [ $FILE_SIZE -gt 0 ] && [ $FILE_SIZE -gt 250 ]; then
        # compress only
        if [ "$MIME" == "webp" ]; then
            # Tạo file temp để tránh corrupt file gốc nếu compress fail
            TEMP_FILE="${FILE_DIR}/${FILE_NAMEB}_temp.webp"
            
            if $CWEBP -progress -v -q ${COMPRESS_QUALITY} -mt "${1}" -o "$TEMP_FILE" 2>&1; then
                # Verify file output hợp lệ
                if dwebp "$TEMP_FILE" -o /dev/null >/dev/null 2>&1; then
                    mv "$TEMP_FILE" "${FILE_DIR}/${FILE_NAMEB}.webp"
                    echo -e "${VERT}✅ Compressed successfully: ${FILE_DIR}/${FILE_NAMEB}.webp${NORMAL}"
                else
                    echo -e "${ROUGE}❌ Output file corrupted, keeping original${NORMAL}"
                    rm -f "$TEMP_FILE"
                fi
            else
                echo -e "${ROUGE}❌ Compression failed for: $1${NORMAL}"
                rm -f "$TEMP_FILE"
            fi
        fi
    fi
}
compress_gif() {
    # https://www.nexcess.net/help/how-to-optimize-jpegs-pngs-and-gifs-from-the-cli/
    # gifsicle --batch --optimize samplefile1.gif samplefile2.gif samplefile3.gif
    exit
}

compress_video() {
    # https://shotstack.io/learn/compress-video-ffmpeg/
    # ffmpeg -i input.mp4 \
    # -c:v libx264 -preset slow -crf 28 -profile:v high -level 4.1 \
    # -movflags +faststart \
    # -c:a aac -b:a 128k \
    # -vf "scale='min(1280,iw)':-2" \
    # output_safe.mp4
    echo -e "${BLUE}== compress_video is running${NORMAL}"
    # verify that file is an image file, and then get dimensions
    # consider output of file -b --mime-type
    # webp đôi khi cho ra định dạng image/webp và application/octet-stream, vì vấn đề của thư viện imagemagic khi upload

    FILE_NAMEA=$(basename "${1}")
    FILE_NAMEB="${FILE_NAMEA%.*}"
    FILE_DIR="$(dirname "${1}")"

    # ---- đảm bảo ffmpeg tồn tại ----
    FFMPEG=${FFMPEG:-ffmpeg}

    echo "FFMPEG path: $FFMPEG"

    # ---- kiểm tra MIME & FILE_SIZE an toàn ----
    MIME=$(file --mime-type -b "$1")
    FILE_SIZE=$(du -k "$1" | cut -f1)

    [[ $VERBOSE -gt 0 ]] && echo "File Dir: $FILE_DIR"
    [[ $VERBOSE -gt 0 ]] && echo "File Name: $FILE_NAMEA"
    [[ $VERBOSE -gt 0 ]] && echo "MimeType: $MIME"
    [[ $VERBOSE -gt 0 ]] && echo "FileSize: ${FILE_SIZE} Kb"

    # ---- convert chỉ khi là video & > 2MB ----
    if [[ "$MIME" == video/* ]] && [ "$FILE_SIZE" -gt 2048 ]; then
        OUTPUT="$FILE_DIR/${FILE_NAMEB}_compressed.mp4"
        echo "Compressing $1 -> $OUTPUT ..."
        $FFMPEG -i "${1}" \
            -c:v libx264 -preset slow -crf 28 -profile:v high -level 4.1 \
            -movflags +faststart \
            -c:a aac -b:a 128k \
            -vf "scale='min(1280,iw)':-2" \
            "$OUTPUT"

        if [ -f "$OUTPUT" ]; then
            echo "Done: $OUTPUT"
        else
            echo "Failed: $1"
        fi
    else
        echo "Skipping $1 (not video or file too small)"
    fi
}

convert_image_to_webp() {
    echo -e "${BLUE}== convert_image_to_webp is running${NORMAL}"

    # 🧩 Default binary
    CWEBP_BIN="${CWEBP:-cwebp}"

    # ⭐ Set default quality if not provided
    if [ -z "$COMPRESS_QUALITY" ]; then
        COMPRESS_QUALITY=75
        echo -e "${ORANGE}⚠️ Quality not set, using default: 75${NORMAL}"
    fi

    FILE_NAMEA=$(basename "${1}")
    FILE_NAMEB="${FILE_NAMEA%.*}"
    FILE_DIR="$(dirname "${1}")"

    if file "${1}" | grep -qE 'image|bitmap' && file --mime-type -b "${1}" | grep -qE 'image|bitmap'; then
        MIME=$(identify -format %e "${1}")
        MIME=$(echo "$MIME" | tr '[:upper:]' '[:lower:]')
        FILE_SIZE=$(du -k "${1}" | cut -f1)
    elif file "${1}" | grep -qE 'RIFF' && file --mime-type -b "${1}" | grep -qE 'octet'; then
        MIME=$(identify -format %e "${1}")
        MIME=$(echo "$MIME" | rev | cut -d " " -f1 | rev)
        MIME=$(echo "$MIME" | tr '[:upper:]' '[:lower:]')
        FILE_SIZE=$(du -k "${1}" | cut -f1)
    else
        echo -e "File ${1} is not an image."
        return
    fi

    echo -e "File Dir $FILE_DIR"
    echo -e "File $FILE_NAMEA"
    echo -e "File $FILE_NAMEB"
    echo -e "File ${1}"
    echo -e "MimeType is $MIME"
    echo -e "FileSize is ${FILE_SIZE} Kb"

    if [ "$FILE_SIZE" -eq 0 ]; then
        echo -e "${ROUGE}❌ File size is 0, skipping${NORMAL}"
        return
    fi

    if [ "$FILE_SIZE" -le 250 ]; then
        echo -e "${ORANGE}⚠️ File < 250KB (${FILE_SIZE}KB), converting anyway...${NORMAL}"
    fi

    # convert to webp
    if [[ "$MIME" =~ ^(jpg|jpeg|png|gif)$ ]]; then
        OUTPUT_FILE="${FILE_DIR}/${FILE_NAMEB}.webp"

        # Skip if output exists and is newer than input
        if [ -f "$OUTPUT_FILE" ] && [ "$OUTPUT_FILE" -nt "${1}" ]; then
            echo -e "${ORANGE}⏭️ Already converted and up-to-date: $OUTPUT_FILE${NORMAL}"
            return
        fi

        # Prefer gif2webp for animated GIFs if available
        if [ "$MIME" = "gif" ]; then
            FRAMES=$(identify -format %n "${1}" 2>/dev/null || echo 1)
            if [ "$FRAMES" -gt 1 ] && command -v gif2webp >/dev/null 2>&1; then
                echo -e "${BLUE}🔄 Converting animated GIF → WebP (quality: ${COMPRESS_QUALITY})...${NORMAL}"
                if gif2webp -q "$COMPRESS_QUALITY" "${1}" -o "$OUTPUT_FILE" 2>&1; then
                    if [ -f "$OUTPUT_FILE" ]; then
                        echo -e "${VERT}✅ Created: $OUTPUT_FILE${NORMAL}"
                    else
                        echo -e "${ROUGE}❌ Failed to create output file${NORMAL}"
                    fi
                else
                    echo -e "${ROUGE}❌ gif2webp failed for: ${1}${NORMAL}"
                    rm -f "$OUTPUT_FILE"
                fi
                return
            fi
        fi

        echo -e "${BLUE}🔄 Converting ${MIME} → WebP (quality: ${COMPRESS_QUALITY})...${NORMAL}"

        # Choose preset based on input type
        PRESET_ARGS=""
        if [ "$MIME" = "jpg" ] || [ "$MIME" = "jpeg" ]; then
            PRESET_ARGS="-preset photo -m 6"
        elif [ "$MIME" = "png" ]; then
            PRESET_ARGS="-preset picture -m 6"
        else
            PRESET_ARGS="-m 5"
        fi

        if "$CWEBP_BIN" -v -progress -q "$COMPRESS_QUALITY" $PRESET_ARGS "${1}" -o "$OUTPUT_FILE" -mt 2>&1; then
            # Validate if dwebp exists
            if command -v dwebp >/dev/null 2>&1; then
                if [ -f "$OUTPUT_FILE" ] && dwebp "$OUTPUT_FILE" -o /dev/null >/dev/null 2>&1; then
                    OUTPUT_SIZE=$(du -k "$OUTPUT_FILE" | cut -f1)
                    echo -e "${VERT}✅ Created: $OUTPUT_FILE (${OUTPUT_SIZE}KB)${NORMAL}"
                else
                    echo -e "${ROUGE}❌ Output file corrupted or invalid${NORMAL}"
                    rm -f "$OUTPUT_FILE"
                fi
            else
                # dwebp not found; trust cwebp result
                OUTPUT_SIZE=$(du -k "$OUTPUT_FILE" | cut -f1)
                echo -e "${VERT}✅ Created: $OUTPUT_FILE (${OUTPUT_SIZE}KB) [no dwebp validate]${NORMAL}"
            fi
        else
            echo -e "${ROUGE}❌ Conversion failed for: ${1}${NORMAL}"
            rm -f "$OUTPUT_FILE"
        fi
    else
        echo -e "${ORANGE}⚠️ Unsupported MIME type: $MIME (only jpg/jpeg/png/gif)${NORMAL}"
    fi
}

convert_video_to_webm() {
    echo -e "${BLUE}== convert_video_to_webm is running${NORMAL}"
    # verify that file is an image file, and then get dimensions
    # consider output of file -b --mime-type
    # webp đôi khi cho ra định dạng image/webp và application/octet-stream, vì vấn đề của thư viện imagemagic khi upload

    FILE_NAMEA=$(basename "${1}")
    FILE_NAMEB="${FILE_NAMEA%.*}"
    FILE_DIR="$(dirname "${1}")"

    if file "${1}" | grep -qE 'video|mp4' && file --mime-type -b "${1}" | grep -qE 'video|mp4'; then
        [[ $VERBOSE -gt 0 ]] && echo "${1} is an video"
        MIME=$(identify -format %e "${1}")

        FILE_SIZE=$(du -k "${1}" | cut -f1)
        # FILE_SIZE=$(stat -f%z "${1}") # only macos
        # FILE_SIZE=$(stat --printf="%s" "${1}") # only unix

    elif file "${1}" | grep -qE 'cai-gi-do' && file --mime-type -b "${1}" | grep -qE 'cai-gi-do'; then
        [[ $VERBOSE -gt 0 ]] && echo "${1} is an video"
        MIME=$(identify -format %e "${1}")
        MIME=$(echo $MIME | rev | cut -d " " -f1 | rev) #https://stackoverflow.com/questions/3162385/how-to-split-a-string-in-shell-and-get-the-last-field

        FILE_SIZE=$(du -k "${1}" | cut -f1)
        # FILE_SIZE=$(stat -f%z "${1}") # only macos
        # FILE_SIZE=$(stat --printf="%s" "${1}") # only unix

    else
        echo -e "File ${1} is not an video."
        FILE_SIZE=0

        return
    fi

    echo -e "File Dir $FILE_DIR"
    echo -e "File $FILE_NAMEA"
    echo -e "File $FILE_NAMEB"
    echo -e "File ${1}"
    echo -e "MimeType is $MIME"
    echo -e "FileSize is ${FILE_SIZE} Kb"

    # convert
    if [ $FILE_SIZE -gt 0 ] && [ $FILE_SIZE -gt 2048 ]; then
        if [ "$MIME" == "mov" ] || [ "$MIME" == "mp4" ]; then
            $FFMPEG -i "${1}" "$FILE_NAMEB.webm" || true
        fi
    fi
}

##### END YOUR FUNCTIONS

# BEGIN MAIN PROGRAM: put at the end of file
while :; do
    echo -e "\nInstallation Script\n"
    echo -e "   1 - Resize"
    echo -e "   2 - ${ROUGE}JPG${NORMAL} compress"
    echo -e "   3 - ${ROUGE}PNG${NORMAL} compress"
    echo -e "   4 - ${ROUGE}WEBP${NORMAL} compress"
    echo -e "   5 - ${ROUGE}Video${NORMAL} compress using FFMPEG"
    echo -e "   6 - ${ROUGE}Convert image to WEBP${NORMAL} using FFMPEG"
    echo -e "   7 - ${ROUGE}Convert video to WEBM${NORMAL} using FFMPEG"
    echo -e "   h - Help"
    echo -e "   q - Quit!"
    echo -e "\n${BLINKING}--> Your Choice? :${NORMAL}"

    read reponse
    case ${reponse} in
    1)
        command -v jpegoptim >/dev/null || {
            echo -e "jpegoptim command not found."
            exit 1
        }
        asking_maxsize "$@"

        echo ${SCREENSHOTS}
        echo -e "${ROUGE} ${SCREENSHOTS} ${NORMAL}"
        # Find all (recursively) types of imagery JPG
        find ${SCREENSHOTS} \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.JPG" -o -iname "*.JPEG" -o -iname "*.PNG" -o -iname "*.WEBP" \) -print0 |
            while read -d $'\0' -r image; do
                # read w h < <(sips -g pixelWidth -g pixelHeight "$image" |
                #     awk '/Width:/{w=$2} /Height:/{h=$2} END{print w " " h}')
                # echo $image $w $h
                echo -e "${ROUGE}image_resize ============================================================${NORMAL}"
                image_resize "${image}"
            done # | awk '{w=$(NF-1); h=$(NF); if(!seen[w SUBSEP h]++)print $0}' # If you only want to output each image size once, ignoring second and subsequent images with identical dimensions, you can add some awk at the end like this:

        echo -ne '\n'
        (rm "/tmp/$lock" && exit 1)
        ;;
    2)
        command -v jpegoptim >/dev/null || {
            echo -e "jpegoptim command not found."
            exit 1
        }
        asking_quality "$@"

        # Find all (recursively) types of imagery JPG
        find ${SCREENSHOTS} \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.JPG" -o -iname "*.JPEG" \) -print0 |
            while read -d $'\0' -r image; do
                # read w h < <(sips -g pixelWidth -g pixelHeight "$image" |
                #     awk '/Width:/{w=$2} /Height:/{h=$2} END{print w " " h}')
                # echo $image $w $h
                echo -e "${ROUGE}compress_jpg ============================================================${NORMAL}"
                compress_jpg "${image}"
            done # | awk '{w=$(NF-1); h=$(NF); if(!seen[w SUBSEP h]++)print $0}' # If you only want to output each image size once, ignoring second and subsequent images with identical dimensions, you can add some awk at the end like this:

        echo -ne '\n'
        (rm "/tmp/$lock" && exit 1)
        ;;
    3)
        command -v pngquant >/dev/null || {
            echo -e "pngquant command not found."
            exit 1
        }
        asking_quality "$@"

        # Find all (recursively) types of imagery PNG
        find ${SCREENSHOTS} \( -iname "*.png" -o -iname "*.PNG" \) -print0 |
            while read -d $'\0' -r image; do
                # read w h < <(sips -g pixelWidth -g pixelHeight "$image" |
                #     awk '/Width:/{w=$2} /Height:/{h=$2} END{print w " " h}')
                # echo $image $w $h
                echo -e "${ROUGE}compress_png ============================================================${NORMAL}"
                compress_png "${image}"
            done # | awk '{w=$(NF-1); h=$(NF); if(!seen[w SUBSEP h]++)print $0}' # If you only want to output each image size once, ignoring second and subsequent images with identical dimensions, you can add some awk at the end like this:

        echo -ne '\n'
        (rm "/tmp/$lock" && exit 1)
        ;;
    4)
        command -v cwebp >/dev/null || {
            echo -e "cwebp command not found."
            exit 1
        }
        asking_quality "$@"

        # Find all (recursively) types of imagery WEBP
        find ${SCREENSHOTS} \( -iname "*.webp" -o -iname "*.WEBP" \) -print0 |
            while read -d $'\0' -r image; do
                # read w h < <(sips -g pixelWidth -g pixelHeight "$image" |
                #     awk '/Width:/{w=$2} /Height:/{h=$2} END{print w " " h}')
                # echo $image $w $h
                echo -e "${ROUGE}compress_webp ============================================================${NORMAL}"
                compress_webp "${image}"
            done # | awk '{w=$(NF-1); h=$(NF); if(!seen[w SUBSEP h]++)print $0}' # If you only want to output each image size once, ignoring second and subsequent images with identical dimensions, you can add some awk at the end like this:

        echo -ne '\n'
        (rm "/tmp/$lock" && exit 1)
        ;;
    5)
        command -v ffmpeg >/dev/null || {
            echo -e "ffmpeg command not found."
            exit 1
        }

        # Find all (recursively) types of imagery JPG
        while IFS= read -r -d '' image; do
            echo -e "${ROUGE}compress_video ============================================================${NORMAL}"
            compress_video "$image"
        done < <(find "${SCREENSHOTS}" \( -iname "*.mp4" -o -iname "*.mov" \) -print0)

        echo -ne '\n'
        (rm "/tmp/$lock" && exit 1)
        ;;
    6)
        command -v cwebp >/dev/null || {
            echo -e "cwebp command not found."
            exit 1
        }

        # Find all (recursively) types of imagery JPG
        find ${SCREENSHOTS} \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 |
            while read -d $'\0' -r image; do
                # read w h < <(sips -g pixelWidth -g pixelHeight "$image" |
                #     awk '/Width:/{w=$2} /Height:/{h=$2} END{print w " " h}')
                # echo $image $w $h
                echo -e "${ROUGE}convert_image_to_webp ============================================================${NORMAL}"
                convert_image_to_webp "${image}"
            done # | awk '{w=$(NF-1); h=$(NF); if(!seen[w SUBSEP h]++)print $0}' # If you only want to output each image size once, ignoring second and subsequent images with identical dimensions, you can add some awk at the end like this:

        echo -ne '\n'
        (rm "/tmp/$lock" && exit 1)
        ;;
    7)
        command -v ffmpeg >/dev/null || {
            echo -e "ffmpeg command not found."
            exit 1
        }

        # Find all (recursively) types of imagery JPG
        find ${SCREENSHOTS} \( -iname "*.mp4" -o -iname "*.mov" \) -print0 |
            while read -d $'\0' -r image; do
                # read w h < <(sips -g pixelWidth -g pixelHeight "$image" |
                #     awk '/Width:/{w=$2} /Height:/{h=$2} END{print w " " h}')
                # echo $image $w $h
                echo -e "${ROUGE}convert_video_to_webm ============================================================${NORMAL}"
                convert_video_to_webm "${image}"
            done # | awk '{w=$(NF-1); h=$(NF); if(!seen[w SUBSEP h]++)print $0}' # If you only want to output each image size once, ignoring second and subsequent images with identical dimensions, you can add some awk at the end like this:

        echo -ne '\n'
        (rm "/tmp/$lock" && exit 1)
        ;;
    q) (rm "/tmp/$lock" && exit 1) ;;
    *) (rm "/tmp/$lock" && exit 1) ;;
    esac
done
# END MAIN PROGRAM
