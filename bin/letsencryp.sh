#!/bin/bash
#!/bin/bash

# VARIABLES
NORMAL="\\033[0;39m"
VERT="\\033[1;32m"
ROUGE="\\033[1;31m"
BLEU="\\033[1;34m"
ORANGE="\\033[1;33m"

KEY_RESET=$(tput sgr0)

FONT_BOLD=$(tput bold)
FONT_UNDERLINE=$(tput sgr 0 1)

COL_RED=$(tput setaf 1)
COL_GREEN=$(tput setaf 76)
COL_YELLOW=$(tput setaf 33)
COL_BLUE=$(tput setaf 38)
COL_MAGENTA=$(tput setaf 35)
COL_CYAN=$(tput setaf 36)
COL_PURPLE=$(tput setaf 171)
COL_TAN=$(tput setaf 3)

# Linux bin paths, change this if it can not be autodetected via which command
BIN="/usr/bin"
CP="$($BIN/which cp)"
CD="$($BIN/which cd)"
GIT="$($BIN/which git)"
LN="$($BIN/which ln)"
MV="$($BIN/which mv)"
NGINX="$($BIN/which nginx)"
MKDIR="$($BIN/which mkdir)"
MYSQL="$($BIN/which mysql)"
MYSQLDUMP="$($BIN/which mysqldump)"
CHOWN="$($BIN/which chown)"
CHMOD="$($BIN/which chmod)"
GZIP="$($BIN/which gzip)"
TOUCH="$($BIN/which touch)"
ZIP="$($BIN/which zip)"
FIND="$($BIN/which find)"
RM="$($BIN/which rm)"
TAR="$($BIN/which tar)"
WGET="$($BIN/which wget)"
CURL="$($BIN/which curl)"
SED="$($BIN/which sed)"
UNZIP="$($BIN/which unzip)"
PERL="$($BIN/which perl)"
WP="$($BIN/which wp)"
CLEAR="$($BIN/which clear)"
DOS2UNIX="$($BIN/which dos2unix)"
CERTBOT="$($BIN/which certbot)"
COMPOSER="$($BIN/which composer)"
PHP="$($BIN/which php)"
BASH="$($BIN/which bash)"

## SCRIPT_PATH="/home/$HOME_USER/server-tools"
## SCRIPT_PATH="$(pwd -P)"
## SCRIPT_PATH="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" ## NOT WORK WITH SYMLINK, eg: bash /opt/server-tools/main.sh

if hash server-tools 2>/dev/null; then
    SCRIPT_PATH="$(dirname "$(readlink -f `which server-tools`)")" ## eg: ln -s /opt/server-tools/main.sh /usr/local/bin/server-tools && server-tools
else
    SCRIPT_PATH="/home/thacoauto/nginx"
fi

## exec 3>&1 4>&2
## trap 'exec 2>&4 1>&3' 0 1 2 3
## exec 1>$SCRIPT_PATH/log.out 2>&1

echo -e "$VERT--> Your shell script path: $ROUGE $SCRIPT_PATH $VERT $NORMAL"
echo -e "$ORANGE--> Enter your domain $NORMAL"

read entry
while :
do
    if [[ -z $entry ]]
    then
        echo -e "$ORANGE--> Enter your domain $NORMAL"
        read entry
    else
        [[ -e $entry ]]
        domain="${entry}.test.thaco.website"
        echo -e "$VERT--> OK ! You are installing SSL on $ROUGE $domain $NORMAL"
        
        if [ -f "/home/thacoauto/nginx/vhost/${entry}.test.conf" ]
        then
            echo -e "$COL_RED--> Vhost ${entry}.test.conf đã tồn tại $NORMAL"
            exit
        fi
        sudo $CP /home/thacoauto/nginx/vhost/000_vhost.sample /home/thacoauto/nginx/vhost/${entry}.test.conf
        sudo $SED -i "s/{DOMAIN}/$domain/g" /home/thacoauto/nginx/vhost/${entry}.test.conf
        sudo systemctl reload nginx
        echo -e "$VERT--> Copy và chạy 02 lệnh bên dưới, chú y, trong khi thao tác máy chủ web sẽ ngưng 1-5P $NORMAL"
        echo -e "$VERT--> 01: sudo fuser -k 80/tcp && sudo fuser -k 443/tcp $NORMAL"
        # echo -e "$VERT--> 02: sudo systemctl stop nginx && sudo certbot --authenticator standalone --installer nginx -d $domain --server https://acme-v02.api.letsencrypt.org/directory $NORMAL"
        echo -e "$VERT--> 02: sudo certbot  --authenticator standalone --installer nginx -d $domain $NORMAL"

        echo -e "$VERT\n--> Nếu quá trình thao tác có lỗi phát sinh, chạy tiếp 02 lệnh sau: $NORMAL"
        echo -e "$VERT--> 01: sudo fuser -k 80/tcp && sudo fuser -k 443/tcp $NORMAL"
        echo -e "$VERT--> 02: sudo systemctl start nginx && sudo systemctl status nginx $NORMAL"
        break        
    fi
done

