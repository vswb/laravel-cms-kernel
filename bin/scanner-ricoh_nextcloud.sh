#!/bin/bash

platform='unknown'

NORMAL="\\033[0;39m"
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
CP="$($BIN/which cp)"
SSH="$($BIN/which ssh)"
CD="$($BIN/which cd)"
GIT="$($BIN/which git)"
ECHO="$($BIN/which echo)"
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
PHP="$($BIN/which php)"
# PHP="/usr/local/php80/bin/php"
PERL="$($BIN/which perl)"
CURL="$($BIN/which curl)"
HASCURL=1
DEVMODE="--no-dev"
PHPCOPTS=" -d memory_limit=-1 "
SED="$($BIN/which sed)"

### directory and file modes for cron and mirror files
FDMODE=0777
CDMODE=0700
CFMODE=600
MDMODE=0755
MFMODE=644

os=${OSTYPE//[0-9.-]*/}
if [[ "$os" == 'darwin' ]]; then
  platform='macosx'
elif [[ "$os" == 'msys' ]]; then
  platform='window'
elif [[ "$os" == 'linux' ]]; then
  platform='linux'
fi
echo -e "$ROUGE You are using $platform $NORMAL"

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
## SCRIPT_PATH=`pwd -P`
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # return /path/bin
echo -e "$VERT--> Your path: $SCRIPT_PATH $NORMAL"

read_var(){
    VAL=$(grep -v '^#' .env | grep -e "$1" | sed -e 's/.*=//' -e 's/^"//' -e 's/"$//')
    # VAL="${VAL%\"}" // will remove the suffix " or just use -e 's/^"//' -e 's/"$//'
    # VAL="${VAL#\"}" // will remove the prefix " or just use -e 's/^"//' -e 's/"$//'
    echo $VAL
}

command -v php >/dev/null || {
  $ECHO "php command not found."
  exit 1
}

## command -v $CURL >/dev/null || HASCURL=0
command -v $CURL >/dev/null || {
  $ECHO "$CURL command not found."
  exit 1
}

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

nonce=$(md5sum <<< $(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5 )
LOCKFILE=/tmp/zipping_$nonce
EMAILFILE=/tmp/zipping_$nonce.email
if [ -f "$LOCKFILE" ]; then
  # Remove lock file if script fails last time and did not run longer than 2 days due to lock file.
  $FIND "$LOCKFILE" -mtime +2 -type f -delete
  $ECHO "$(date) - Warning - process is running"
  exit 1
fi

## WEBDAVPASS: oW9gE-fLqX9-7kF2b-HNFm2-YajN6
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
WEBDAV_DRIVE_URL="https://drive.fsofts.com"
WEBDAV_BASEURL="https://drive.fsofts.com/remote.php/webdav"
WEBDAVLOGIN="printer@fsofts.com"
WEBDAVPASS="dwRdL-WsDAF-CY4tS-2zj7s-qr8mR"
BACKUP_PATH_PROJECT="Ricoh"
WEBDAV="$WEBDAV_BASEURL/$BACKUP_PATH_PROJECT/"

if [ $HASCURL == 1 ]; then
  $CURL -k -u "$WEBDAVLOGIN:$WEBDAVPASS" -X MKCOL $WEBDAV
  $ECHO -e "$VERT--> Your WebDav: $WEBDAV $NORMAL"
fi

##################### Begin upload to nextcloud webdav
if [ $HASCURL == 1 ]; then
    NEXT_WAIT_TIME=60
    SEARCH_FOLDER="/home/fsofts/tmp/*"

    for BACKUP_SOURCENAME in $(find $SEARCH_FOLDER -type f \( -name "*pdf" -o -name "*doc" -o -name "*docx" -o -name "*jpg" -o -name "*jpeg" -o -name "*tiff" \));
    do
        echo "Processing $BACKUP_SOURCENAME"
        UPLOAD_SOURCE_CMD="$CURL --progress-bar --verbose -k -u "$WEBDAVLOGIN:$WEBDAVPASS" -X PUT -T $BACKUP_SOURCENAME $WEBDAV"
        if [ -f "$BACKUP_SOURCENAME" ]; then
            $ECHO "Backup Source size: $(du -h $BACKUP_SOURCENAME | awk '{printf "%s",$1}')"

            if [ -f "$BACKUP_SOURCENAME" ]; then
                until $UPLOAD_SOURCE_CMD || [ $NEXT_WAIT_TIME -eq 14 ]; do
                sleep $(( NEXT_WAIT_TIME++ ))
                $ECHO "$(date) - ERROR - Webdav Upload was failed, will retry after 60 seconds ($UPLOAD_SOURCE_CMD)."
                done
            fi
            ## $ECHO -e "$VERT--> http://{DOMAIN_NAME}/$BACKUP_SOURCENAME $NORMAL"

            $ECHO "Checking $BACKUP_SOURCENAME"
            $ECHO -e "$VERT--> Your path: $SCRIPT_PATH $NORMAL"
            if [ -f "$BACKUP_SOURCENAME" ]; then
                $RM -f $BACKUP_SOURCENAME \;
                $ECHO "Removed $BACKUP_SOURCENAME"
            fi

            $ECHO -e "$ROUGE--> PLEASE LOGIN TO  $WEBDAV_DRIVE_URL THEN SHARE TO CLIENT THE LINK, MAKE SURE THAT THEY CAN ACCESS $NORMAL"
            $ECHO -e "$VERT--> The Link is: $WEBDAV_DRIVE_URL/index.php/apps/files/?dir=/$BACKUP_PATH_PROJECT $NORMAL"
            $ECHO -e "$ORANGE--> Done!$NORMAL"
        fi
    done;
else
    $ECHO "$(date) - ERROR - Config file could not be read."
fi
## End

exit 0
