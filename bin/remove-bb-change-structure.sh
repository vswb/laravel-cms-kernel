################################################################
## Shell script : remove author information with shell,
## This script will be remove author information, namespace (use Dev). No change other application's structure anymore!
##
## Author: Weber Team!
## Copy Right: @2011 Weber Team!
################################################################

## B1: Download mã nguồn gốc về, giải nén, xóa folder "vendor"
## B2: Copy hết mọi thứ TRỪ folder "platform", paste qua thư mục dự án laravel-cms
## B3: Mở folder platform/core/* Copy hết mọi thứ bên trong, paste qua thư mục dự án laravel-cms/dev/core/
## B4: Mở folder platform/packages/* Copy hết mọi thứ bên trong, paste qua thư mục dự án laravel-cms/dev/libs/
## B5: Mở folder platform/plugins/* Copy hết mọi thứ bên trong, paste qua thư mục dự án laravel-cms/dev/plugins/
## B6: Copy folder platform/themes, paste qua thư mục dự án laravel-cms/dev (trước đó có thể tồn tại folder platform/ui, cần xóa đi, shell sẽ tự động replace platform/themes/[botble-theme] > platform/themes/ui)
## B7: chạy lệnh bash bin/remove-bb-change-structure.sh -e d
## B8: revert lại vài dòng quan trọng của root/composer.json và kiểm tra / tìm kiếm từ khóa botble trong toàn dụ án xem có phát sinh mới ở đâu không

## DONE

#!/bin/bash
os='unknown'

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

# Linux bin paths, change this if it can not be autodetected via which command
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
PERL="$($BIN/which perl)"
CURL="$($BIN/which curl)"
HASCURL=1
DEVMODE="--dev"
PHPCOPTS=" -d memory_limit=-1 "

### directory and file modes for cron and mirror files
FDMODE=0777
CDMODE=0700
CFMODE=600
MDMODE=0755
MFMODE=644

os=${OSTYPE//[0-9.-]*/}
if [[ "$os" == 'darwin' ]]; then
  os='macosx'
elif [[ "$os" == 'msys' ]]; then
  os='window'
elif [[ "$os" == 'linux' ]]; then
  os='linux'
fi
echo -e "$ROUGE You are using $os $NORMAL"

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
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # return /path/bin
echo -e "$VERT--> Your path: $SCRIPT_PATH $NORMAL"

# Usage info
show_help() {
  cat <<EOF
Usage: ${0##*/} [-hv] [-e APPLICATION_ENV] [development]...
    -h or --help         display this help and exit
    -e or --env APPLICATION_ENV
    -v or --verbose      verbose mode. Can be used multiple times for increased
                verbosity.
EOF
}
die() {
  printf '%s\n' "$1" >&2
  exit 1
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
verbose=0
while :; do
  case $1 in
  -e | --env)
    if [ -z "$2" ]; then
      show_help
      die 'ERROR: please specify "--e" enviroment.'
    fi
    APPLICATION_ENV="$2"
    if [[ "$2" == 'd' ]]; then
      APPLICATION_ENV="development"
    fi
    if [[ "$2" == 'p' ]]; then
      APPLICATION_ENV="production"
    fi
    shift
    break
    ;;
  -h | -\? | --help)
    show_help # Display a usage synopsis.
    exit
    ;;
  -v | --verbose)
    verbose=$((verbose + 1)) # Each -v adds 1 to verbosity.
    ;;
  --) # End of all options.
    shift
    break
    ;;
  -?*)
    printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
    ;;
  *)          # Default case: No more options, so break out of the loop.
    show_help # Display a usage synopsis.
    die 'ERROR: "--env" requires a non-empty option argument.'
    ;;
  esac
  shift
done

export APPLICATION_ENV="${APPLICATION_ENV}"

echo -e "$VERT--> You are uing APPLICATION_ENV: $APPLICATION_ENV $NORMAL"

command -v $PHP >/dev/null || {
  echo "The 'php' command not found."
  exit 1
}

command -v perl >/dev/null || {
  echo "The 'perl' command not found."
  exit 1
}
HASCURL=1

command -v curl >/dev/null || HASCURL=0

if [ -z "$1" ]; then
  DEVMODE=$1
else
  DEVMODE="--no-dev"
fi

### settings / options
PHPCOPTS="-d memory_limit=-1"

[ ! -d $SCRIPT_PATH/../vendor ] && $ECHO "No vendor directory found" || rm -rf $SCRIPT_PATH/../vendor/
[ ! -d $SCRIPT_PATH/../bootstrap/cache ] && $ECHO "No cache directory found" || rm -rf $SCRIPT_PATH/../bootstrap/cache/*.php
[ ! -f "$SCRIPT_PATH/../composer.lock" ] && $ECHO "No composer.lock directory found" || rm -rf $SCRIPT_PATH/../composer.lock
[ ! -f "$SCRIPT_PATH/../composer.phar" ] && $ECHO "No composer.phar directory found" || rm -rf $SCRIPT_PATH/../composer.phar

if [ -d "$SCRIPT_PATH/../lang" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../lang/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/version of Botble/version of Dev/g')
fi

if [ -f "$SCRIPT_PATH/../database.sql" ]; then
  ### SuperAdmin in Botble CMS
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$10\$GB\.Fw1a\/osntfrkiyX72cO5BxfgMDhg80XpdFHh5joj1udK\/cgAU6/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$\/TFkWFGqoi8ghH8FTOjM4ucqge2KXuZRZ\/4Mv3klr4ZAYxU500ctW/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$LQ4\/xO2jnhCKQwoIrhGdnepKXy\/2fOPdkkVz6v7xdGk5AxICb2BlC/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$AjaffJm\/SgRqIkEq\.Hw6lOiKhKDhvYyaTmaohTHLM9thXe1AhMt3q/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$t\.LS\.QjivLPruXccnl8B0uuy9U8V4k\.6GRcRNJ70qUwfc3\/xtI2Yu/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$K9JNFf8YtY6GqYOxtwHLhOSxFcLEVL7efcp0214\.\/Gr04\/WyNgPk2/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$K9JNFf8YtY6GqYOxtwHLhOSxFcLEVL7efcp0214\.\/Gr04\/WyNgPk2/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$b1nNB4TPBiFcNgUHpVqt5OXhHi9vPRsewXIT9dkV4527QFeeARGOm/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)

  ### SuperAdmin in Flexhome
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$HYEUN4HLrjx5mXO8M1JfBOcqH\.gXdQVl\/qqqJp\/N2d8DHFjtLhaui/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$3ouZBNvZ8yOPcxXxEKJVQuEoMGrK\/QVtpA6FRX2LZwMMAK4Vi\/0Oe/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$TIf84jZuSeuYTPOWpH7rR\.fv0zt4F4ZTDEeCkzNsum2OTvWy9Lcoe/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)

  ### SuperAdmin in Shopwise
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$10\$Y1n8whq\/bq2jjp8WC6kM6evQ2RZwOWxXxTierjBu0i8wtkQjVNHgW/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$fJN4S29g\/mCY133gMhJIRuKJgLfTQS8rwF53rTz\.eE1RmQb7bBUKa/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\$2y\$12\$bpqcdnX08YKYYWGniJuJ\/e2zuhHdOB2Tmdxikzyn32byRuBJBvbg\./\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/kyra\.orn\@ohara.info/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/okeefe\@swaniawski\.biz/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/super\@botble\.com/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/admin\@botble\.com/admin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/user\@botble\.com/user\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/valentine\.stiedemann\@funk\.com/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/alphonso22\@keebler\.info/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/lboyle\@jones\.com/admin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/toni93\@weber\.org/admin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/zokeefe\@swaniawski\.biz/admin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/admin\@botble\.com - 159357/superadmin\@fsofts\.com - It\@\@246357/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble - 159357/superadmin\@fsofts\.com - It\@\@246357/g' $SCRIPT_PATH/../database.sql)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/A young team in Vietnam/Laravel is the best/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/dev-botble/dev-laravel/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/1\.envato\.market\/LWRBY/fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/https\:\/\/codecanyon\.net\/item\/botble-cms-php-platform-based-on-laravel-framework\/16928182/fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Database\: botble/Database\: laravel/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble CMS/Laravel CMS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/flex-home\.com/laravel-realestate\.demo\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble\.ticksy\.com/docs\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble, botble team, botble platform/development team, dev features/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/docs\.botble\.com/docs\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/cms\.botble\.com/cms.\fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble.local/cms\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble\.technologies/cms.\fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble Platform/Laravel CMS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/twitter\.com\/botble/cms\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble CMS/Laravel CMS/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble-cms/laravel-cms/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/minhsang2603/toan.lehuy/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/sangnguyen2603/toan.lehuy/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/minsang2603/toan.lehuy/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/sangnguyen\.info/fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Nghia Minh/Developer Team/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble since v2.0/Laravel CMS since v2.0/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\//\"dev\//g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/84988606928/84943999819/g' $SCRIPT_PATH/../database.sql)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble.cms\@gmail\.com/contact\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/nghiadev\.com/fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/The Botble/The Laravel/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/minhsang2603\@gmail\.com/contact\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/sangplus\.com/fsofts\.com/g' $SCRIPT_PATH/../database.sql)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble\\\\/Dev\\\\/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble\\/Dev\\/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble\\\\/Dev\\\\/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble\\/Dev\\/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/license\.botble\.com/apis\.pull\.vn/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble\.com/cms\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble/Laravel/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble\/cms/laravel\/cms/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\=botble/\=laravel/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Nghia Minh/Developer Team/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble Technologies/Laravel Technologies/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Sang Nguyen/Developer Team/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/support\@company\.com/contact\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/sangnguyenplus\@gmail\.com/contact\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble.test/fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/shopwise\.test/laravel-ecommerce\.demo\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/flex-home\.test/laravel-realestate\.demo\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble Technologies/Laravel Technologies/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/BOTBLE Teams/Developer Team/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble Fans/Developer Team/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble team/Developer Team/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble product/Laravel product/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble product/Laravel product/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/good job Botble/good job Laravel product/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/confident in Botble/confident in Laravel product/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble puts/Laravel Technologies puts/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/at Botble/at Laravel Technologies/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Thank you Botble/Thank you Laravel/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/flex-home\.fsofts\.com/laravel-realestate\.demo\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/shopwise-/master-/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Shopwise/Master/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/shopwise/master/g' $SCRIPT_PATH/../database.sql)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/ripple-/master-/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Ripple/Master/g' $SCRIPT_PATH/../database.sql)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/ripple/master/g' $SCRIPT_PATH/../database.sql)
else
  echo -e "$COL_RED Could not found database.sql $NORMAL"
fi

# remove fob 
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\/fob-/\//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/FOB //g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/fob-//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/FOB //g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/fob-//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/FOB //g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/fob-//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/fob-//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/\/fob-/\//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/FOB //g')
# end remove fob 

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../public/vendor/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\[Botble/\[Dev/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../public/vendor/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\#botble/\#dev/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../public/vendor/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/botble-ecommerce/dev-ecommerce/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\[Botble/\[Dev/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/botble-ecommerce/dev-ecommerce/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/baoboine\/botble-comment/vswb\/dev-comment/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\#botble/\#dev/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/\(Botble/\(Dev/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble community/Laravel community/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/botble_cookie_newsletter/apps_cookie_newsletter/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble_cookie_consent/apps_cookie_consent/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble\/translations/vswb\/translations/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../public/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/botble_cookie_newsletter/apps_cookie_newsletter/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/dev-botble/dev-laravel/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/dev\.com/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/baoboine\/botble-comment/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/baoboine\/botble-my-style/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\@botble\/core/\@dev\/core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\@botble\/media/\@dev\/media/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/baoboine\/botble-comment/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/baoboine\/botble-my-style/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/botble-my-style/comment/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble My Style/My Style/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble core/Dev core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble Marketplace/Laravel Marketplace/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble IP Blocker/Laravel IP Blocker/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble URL/Laravel URL/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/baoboine\/botble-comment/vswb\/dev-comment/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/https\:\/\/botble\.com\/storage\/uploads\/1/https\:\/\/fsofts\.com\/images\/analytics/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/contact\@botble\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/\`botble\` - \`159357\`/superadmin\@fsofts\.com - It\@\@246357/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/\`botble\`/superadmin\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/\`159357\`/It\@\@246357/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/https\:\/\/codecanyon\.net\/user\/botble/fsofts\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/\`botble\/plugin-management\`/\`dev\/plugin-management\`/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/whats-new-in-botble-cms-33/whats-new-in-laravel-cms-33/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/https\:\/\/github\.com\/botble\/issues\/issues\/1/https\:\/\/github\.com\/vswb\/issues\/issues\/1/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/\/vendor\/botble\/menu/\/vendor\/dev\/menu/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/botble-ip-blocker/dev-ip-blocker/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Ngo Quoc Dat/Developer Team/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Archi Elite Technologies/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Archi Elite/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Tuoitresoft developers/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Friends Of Botble/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Friends of Botble/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Binjuhor from XDevLabs Team/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/binjuhor\.com/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/github\.com\/FriendsOfBotble/github\.com\/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Anh Ngo/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Nawras Bukhari/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/github\.com\/NawrasBukhari\/postpay-botble/github\.com\/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble /Core /g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\.com/fsofts\.com/g') # chú ý vị trí
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/license\.botble\.com/apis\.pull\.vn/g') # chú ý vị trí
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/botble\.com/cms\.fsofts\.com/g') # chú ý vị trí
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/ngoquocdat\.dev/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/archielite\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/1\.envato\.market\/LWRBY/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/https\:\/\/codecanyon\.net\/item\/botble-cms-php-platform-based-on-laravel-framework\/16928182/https\:\/\/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/\/botble\//\/vswb\//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/FriendsOfBotble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble plugin/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/composer require botble/composer require dev/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/marketplace.botble\.com/apis.pull.vn/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/botble\/git-commit-checker/dev\/git-commit-checker/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/github\.com\/botble/github\.com\/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/github\.com\/datlechin/github\.com\/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble Technologies/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Botble/Core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Tuoitre Soft/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/alnovate\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/https\:\/\/dev\.com/https\:\/\/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/tuoitresoft\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/Alnovate Digital/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/comment/dev\/comment/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/ticksify/dev\/ticksify/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/geo-data-detector/dev\/geo-data-detector/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/request-quote/dev\/request-quote/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/vietnam-bank-qr/dev\/vietnam-bank-qr/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/botble-vnpayment-plugin/vnpayment/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '.env' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '.env' -print0 | xargs -0 perl -i -pe 's/APP_DEBUG\=true/APP_DEBUG\=false/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '.env' -print0 | xargs -0 perl -i -pe 's/APP_ENV\=local/APP_ENV\=production/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '.env.example' -print0 | xargs -0 perl -i -pe 's/APP_ENV\=local/APP_ENV\=production/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '.env.example' -print0 | xargs -0 perl -i -pe 's/APP_DEBUG\=true/APP_DEBUG\=false/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '.env.example' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '.env.example' -print0 | xargs -0 perl -i -pe 's/docs\.botble\.com/docs.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name 'package-lock.json' -print0 | xargs -0 perl -i -pe 's/\@botble/\@dev/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name 'package-lock.json' -print0 | xargs -0 perl -i -pe 's/botble/dev/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../resources/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/repos\/botble/repos\/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/github\.com\/botble\/location/github\.com\/vswb\/locations/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/_botble_member/_dev_member/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/_botble_contact/_dev_contact/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble\/\{/Dev\/\{/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble\/example-plugin/dev\/example-plugin/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/https\:\/\/botble/https\:\/\/fsofts/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/github\.com\/botble\//github\.com\/vswb\//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/github\.com\/botble\//github\.com\/vswb\//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/github\.com\/botble\//github\.com\/vswb\//g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Martfury/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/https\:\/\/codecanyon\.net\/item\/martfury-multipurpose-laravel-ecommerce-system\/29925223/https\:\/\/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/github\.com\/FriendsOfBotble/github\.com\/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"FriendsOfBotble\"/\"Laravel CMS\"/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble\:\:log\-viewer/dev\:\:log\-viewer/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/_botble_/_apps_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Friends of Botble/Laravel CMS/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../resources/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/flex-home\.com/laravel-realestate\.demo\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/flex-home\.com/laravel-realestate\.demo\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/flex-home\.com/laravel-realestate\.demo\.fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Try to reinstall botble\/git-commit-checker package/Try to reinstall dev\/git-commit-checker package/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/docs\.botble\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/1.envato.market\/LWRBY/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Just another Botble CMS site/Just another Laravel CMS Website/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/contact\@botble\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/john.smith\@botble\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/support\@botble\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/https\:\/\/botble\.com\/go\/download-cms/mailto\:contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/https\:\/\/botble\.com/mailto\:contact\@fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble-2fa/2fa/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble-activator/laravel-activator/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble-activator-main/laravel-activator-main/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/shaqi\/botble-activator/vswb\/laravel-activator/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/BotbleCMS/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble-plugin/plugin/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble BOT/Anonymous BOT/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble_session/apps_session/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble Team/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Ex: botble/Ex: your-key/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/amazonaws\.com\/botble/amazonaws\.com\/your-key/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble Marketplace/Laravel Marketplace/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/friends-of-botble/dev/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Nghĩa Nè/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Phạm Viết Nghĩa/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/nghiane\.com/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble-2fa/2fa/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble-plugin/plugin/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\"/\"Laravel Framework\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble cms/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Facebook Reaction for Botble/Facebook Reaction for Laravel/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble platform/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble assets/Laravel Assets/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble git commit checker/Git Commit Checker/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Archi Elite Technologies/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Archi Elite/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Tuoitre Soft/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/tuoitresoft\.com/docs\.fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/archielite\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/archielite\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/archielite\.com/docs\.fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble\.ticksy\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\.ticksy\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/botble\.ticksy\.com/docs\.fsofts\.com/g')
#
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble, botble team, botble platform/development team, dev features/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble, botble team, botble platform/development team, dev features/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/botble, botble team, botble platform/development team, dev features/g')
#
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/docs\.botble\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/docs\.botble\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/docs\.botble\.com/docs\.fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/cms\.botble\.com/cms.\fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/cms\.botble\.com/cms.\fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/cms\.botble\.com/cms.\fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble.local/cms\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble.local/cms\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/botble.local/cms\.fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble Platform/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Botble Platform/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/Botble Platform/Laravel CMS/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble\.technologies/cms.\fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\.technologies/cms.\fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/botble\.technologies/cms.\fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/twitter\.com\/botble/cms\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/twitter\.com\/botble/cms\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/twitter\.com\/botble/cms\.fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/version of Botble/version of Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble-cms/laravel-cms/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble-cms/laravel-cms/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/botble-cms/laravel-cms/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/minsang2603/toan.lehuy/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/minsang2603/toan.lehuy/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/minsang2603/toan.lehuy/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/sangnguyen2603/toan.lehuy/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/sangnguyen2603/toan.lehuy/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/sangnguyen2603/toan.lehuy/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/minsang2603/toan.lehuy/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/minsang2603/toan.lehuy/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/minsang2603/toan.lehuy/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/sangnguyen\.info/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/sangnguyen\.info/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/sangnguyen\.info/fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Nghia Minh/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Nghia Minh/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/Nghia Minh/Developer Team/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble since v2.0/Laravel CMS since v2.0/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Botble since v2.0/Laravel CMS since v2.0/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/Botble since v2.0/Laravel CMS since v2.0/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/\"botble\//\"dev\//g')
#(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\//\"dev\//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/\"botble\//\"dev\//g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/84988606928/84943999819/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/84988606928/84943999819/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/84988606928/84943999819/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../resources/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/docs\.botble\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../resources/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/docs\.botble\.com/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../resources/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/docs\.botble\.com/docs\.fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe "s/'botble'/'contact\@fsofts\.com'/g")
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe "s/'botble'/'contact\@fsofts\.com'/g")
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe "s/'botble'/'contact\@fsofts\.com'/g")

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/admin\@botble\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/admin\@botble\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/admin\@botble\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/admin\@botble\.com/contact\@fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble.cms\@gmail\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble.cms\@gmail\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/botble.cms\@gmail\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/botble.cms\@gmail\.com/contact\@fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\@gmail\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\@gmail\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\@gmail\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\@gmail\.com/contact\@fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/nghiadev\.com/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/nghiadev\.com/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/nghiadev\.com/fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/The Botble/The Laravel/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/The Botble/The Laravel/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/The Botble/The Laravel/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Nghia Minh/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Nghia Minh/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/Nghia Minh/Developer Team/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble Technologies/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Botble Technologies/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/Botble Technologies/Laravel Technologies/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Sang Nguyen/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Sang Nguyen/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/Sang Nguyen/Developer Team/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/sangnguyenplus\@gmail\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/sangnguyenplus\@gmail\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/sangnguyenplus\@gmail\.com/contact\@fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/minhsang2603\@gmail\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/minhsang2603\@gmail\.com/contact\@fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/minhsang2603\@gmail\.com/contact\@fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/sangplus\.com/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/sangplus\.com/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/sangplus\.com/fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/FriendsOfBotble\\\\/Dev\\\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/FriendsOfBotble\\\\/Dev\\\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/FriendsOfBotble\\\\/Dev\\\\/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble\\\\/Dev\\\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Botble\\\\/Dev\\\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/Botble\\\\/Dev\\\\/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../resources/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/FriendsOfBotble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/FriendsOfBotble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/FriendsOfBotble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/FriendsOfBotble\\/Dev\\/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../resources/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Botble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/Botble\\/Dev\\/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.env' -print0 | xargs -0 perl -i -pe 's/Botble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.env' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel CMS/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/FriendsOfBotble\\\\/Dev\\\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/FriendsOfBotble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble\\\\/Dev\\\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble\\/Dev\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/support\@company\.com/support\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/customer\@botble\.com/customer\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/admin\@botble\.com/superadmin\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/sales\@botble\.com/sales\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/sale\@botble\.com/sales\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Shopwise/Laravel Ecommerce/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/159357/It\@\@246357/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble Technologies/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/BOTBLE Teams/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble Fans/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble team/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble Team/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble product/Laravel product/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble product/Laravel product/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/good job Botble/good job Laravel product/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/confident in Botble/confident in Laravel product/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble puts/Laravel Technologies puts/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/at Botble/at Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Thank you Botble/Thank you Laravel/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/nghiane\.com/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../database/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Flex Home/Shop Zone/g')

#region fix UUID compatible w/ laravel core
if [ -f "$SCRIPT_PATH/../dev/core/base/src/Contracts/BaseModel.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/public function newUniqueId\(\)\: \?string\;/public function newUniqueId\(\);/g" $SCRIPT_PATH/../dev/core/base/src/Contracts/BaseModel.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/public function getKeyType\(\)\: string\;/public function getKeyType\(\);/g" $SCRIPT_PATH/../dev/core/base/src/Contracts/BaseModel.php)
fi
if [ -f "$SCRIPT_PATH/../dev/core/base/src/Models/Concerns/HasUuidsOrIntegerIds.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/public function newUniqueId\(\)\: \?string/public function newUniqueId\(\)/g" $SCRIPT_PATH/../dev/core/base/src/Models/Concerns/HasUuidsOrIntegerIds.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/public function getKeyType\(\)\: string/public function getKeyType\(\)/g" $SCRIPT_PATH/../dev/core/base/src/Models/Concerns/HasUuidsOrIntegerIds.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/public function getIncrementing\(\)\: bool/public function getIncrementing\(\)/g" $SCRIPT_PATH/../dev/core/base/src/Models/Concerns/HasUuidsOrIntegerIds.php)
fi
#endregion

if [ -f "$SCRIPT_PATH/../dev/core/base/src/Supports/EmailHandler.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/public function __construct\(\)/protected string \\\$platform_path = 'dev';\n\n\tpublic function setPlatformPath\(\\\$platform_path = 'dev')\{\\\$this\-\>platform_path = \\\$platform_path; return \\\$this;\}\n\tpublic function getPlatformPath\()\{return \\\$this\-\>platform_path;\}\n\n\tpublic function __construct\(public string \\\$platform_type = 'dev'\)/g" $SCRIPT_PATH/../dev/core/base/src/Supports/EmailHandler.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/\\\$key . '.tpl'\n/\\\$key . '.tpl', \\\$this->getPlatformPath\(\)\n/g" $SCRIPT_PATH/../dev/core/base/src/Supports/EmailHandler.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/get_setting_email_template_content\(\\\$type, \\\$this\-\>module, \\\$template\)/get_setting_email_template_content\(\\\$type, \\\$this\-\>module, \\\$template, \\\$this\-\>getPlatformPath\(\)\)/g" $SCRIPT_PATH/../dev/core/base/src/Supports/EmailHandler.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/get_setting_email_template_content\(\\\$this\-\>type, \\\$this\-\>module, \\\$this\-\>template\)/get_setting_email_template_content\(\\\$this\-\>type, \\\$this\-\>module, \\\$this\-\>template, \\\$this\-\>getPlatformPath\(\)\)/g" $SCRIPT_PATH/../dev/core/base/src/Supports/EmailHandler.php)
fi
if [ -f "$SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getPath\(\?string \\\$path = null\)/getPath\(\?string \\\$path = null, \?string \\\$platform_path = \'dev\', \?string \\\$plugin_path = \'dev\/plugins\'\)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/base_path\(\'platform\/plugins\'\)/base_path\(\\\$plugin_path\)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/base_path\(\'dev\/plugins\'\)/base_path\(\\\$plugin_path\)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/base_path\(\'platform\/\'/base_path\(\\\$platform_path . '\/'/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getViewsPath\(\)\: string/getViewsPath\(string \\\$platform_path = \'dev\', string \\\$plugin_path = \'dev\/plugins\'\)\: string/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getPath\('\/resources\/views'\)/getPath\('\/resources\/views', \\\$platform_path, \\\$plugin_path)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getTranslationsPath\(\)\: string/getTranslationsPath\(string \\\$platform_path = \'dev\', string \\\$plugin_path = \'dev\/plugins\'\)\: string/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
  
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getMigrationsPath\(\)\: string/getMigrationsPath\(string \\\$platform_path = \'dev\', string \\\$plugin_path = \'dev\/plugins\'\)\: string/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getPath\(\'\/database\/migrations\'\)/getPath\(\'\/database\/migrations\', \\\$platform_path, \\\$plugin_path)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getAssetsPath\(\)\: string/getAssetsPath\(string \\\$platform_path = \'dev\', string \\\$plugin_path = \'dev\/plugins\'\)\: string/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getConfigFilePath\(string \\\$file\)/getConfigFilePath\(string \\\$file, string \\\$platform_path = \'dev\', string \\\$plugin_path = \'dev\/plugins\'\)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getPath\(\'config\/\' . \\\$file . \'.php\'\)/getPath\(\'config\/\' . \\\$file . \'.php\', \\\$platform_path, \\\$plugin_path)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getRouteFilePath\(string \\\$file\)/getRouteFilePath\(string \\\$file, string \\\$platform_path = \'dev\', string \\\$plugin_path = \'dev\/plugins\'\)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getPath\(\'routes\/\' . \\\$file . \'.php\'\)/getPath\(\'routes\/\' . \\\$file . \'.php\', \\\$platform_path, \\\$plugin_path)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getPath\('\/resources\/lang'\)/getPath\('\/resources\/lang', \\\$platform_path, \\\$plugin_path)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getPath\('public'\)/getPath\('public', \\\$platform_path, \\\$plugin_path)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/loadHelpers\(\)\: static/loadHelpers\(string \\\$platform_path = \'dev\', string \\\$plugin_path = \'dev\/plugins\'\)\: static/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getPath\('\/helpers'\)/getPath\('\/helpers', \\\$platform_path, \\\$plugin_path)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
fi

## change core_path
if [ -f "$SCRIPT_PATH/../dev/core/base/helpers/common.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/platform_path\('core'/platform_path\(\\\$core_path/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/core_path\(\?string \\\$path = null\)/core_path\(\?string \\\$path = null, string \\\$core_path = 'core'\)/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
fi
## change platform_path
if [ -f "$SCRIPT_PATH/../dev/core/base/helpers/common.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/base_path\('platform'/base_path\(\\\$platform_path/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/platform_path\(\?string \\\$path = null\)/platform_path\(\?string \\\$path = null, string \\\$platform_path = 'dev'\)/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
fi
## change package_path
if [ -f "$SCRIPT_PATH/../dev/core/base/helpers/common.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/platform_path\('packages'/platform_path\(\\\$package_path/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/package_path\(\?string \\\$path = null\)/package_path\(\?string \\\$path = null, string \\\$package_path = 'libs'\)/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
fi

if [ -f "$SCRIPT_PATH/../dev/core/setting/helpers/helpers.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/get_setting_email_template_content\(string \\\$type, string \\\$module, string \\\$templateKey\)/get_setting_email_template_content\(string \\\$type, string \\\$module, string \\\$templateKey, string \\\$platform_path = 'dev'\)/g" $SCRIPT_PATH/../dev/core/setting/helpers/helpers.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/\\\$templateKey . '.tpl'\)/\\\$templateKey . '.tpl', \\\$platform_path\)/g" $SCRIPT_PATH/../dev/core/setting/helpers/helpers.php)
fi

if [ -f "$SCRIPT_PATH/../database/seeders/UserSeeder.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble/superadmin/g' $SCRIPT_PATH/../database/seeders/UserSeeder.php)
fi
if [ -f "$SCRIPT_PATH/../dev/plugins/ecommerce/src/Database/Seeders/ReviewSeeder.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble/Laravel/g' $SCRIPT_PATH/../dev/plugins/ecommerce/src/Database/Seeders/ReviewSeeder.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/BOTBLE/Laravel/g' $SCRIPT_PATH/../dev/plugins/ecommerce/src/Database/Seeders/ReviewSeeder.php)
fi
if [ -f "$SCRIPT_PATH/../database/seeders/WidgetSeeder.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble/Dev/g' $SCRIPT_PATH/../database/seeders/WidgetSeeder.php)
fi
if [ -f "$SCRIPT_PATH/../_ide_helper.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble\\/Dev\\/g' $SCRIPT_PATH/../_ide_helper.php)
fi

if [ -f "$SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/use Dev\\\Support\\\Repositories\\\Interfaces\\\RepositoryInterface;\nuse Illuminate\\\Database\\\Eloquent\\\Model;/use Dev\\\Support\\\Repositories\\\Interfaces\\\RepositoryInterface;\nuse Dev\\\Support\\\Services\\\Cache\\\Cache;\nuse Illuminate\\\Database\\\Eloquent\\\Model;\nuse Exception;\nuse InvalidArgumentException;/g" $SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php) # add new libs

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/public function __construct\(protected RepositoryInterface \\\$repository\)\n    {/protected RepositoryInterface \\\$repository;\n\tprotected Cache \\\$cache;\n\n\tpublic function __construct\(RepositoryInterface \\\$repository, string \\\$cacheGroup = null, string \\\$modeGroup = null\)\n\t\{\n\t\t\\\$this->repository = \\\$repository\;\n\t\t\\\$this->cache = new Cache\(app\('cache'\), \\\$cacheGroup ?? get_class\(\\\$repository->getModel\(\)\), \[\], \\\$modeGroup\)\;/g" $SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php) # add new function

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/public function getDataIfExistCache\(string \\\$function, array \\\$args\)\n    {/public function getDataWithCache\(string \\\$function, array \\\$args\) { try { if \(! setting\('enable_cache_data', false\)\) { return call_user_func_array\(\[\\\$this->repository, \\\$function\], \\\$args\); } \\\$cacheKey = md5\( get_class\(\\\$this\) . \\\$function . serialize\(request\(\)->input\(\)\) . serialize\(json_encode\($args\)\) );  if \(\\\$this->cache->has\(\\\$cacheKey\)\) { return \\\$this->cache->get\(\\\$cacheKey\); }  \\\$cacheData = call_user_func_array\(\[\\\$this->repository, \\\$function\], \\\$args\);  \\\$this->cache->put\(\\\$cacheKey, \\\$cacheData\);  return \\\$cacheData; } catch \(Exception | InvalidArgumentException \\\$ex\) { info(\\\$ex->getMessage\(\)\); return call_user_func_array\(\[\\\$this->repository, \\\$function\], \\\$args\); } }\n\n\tpublic function getDataIfExistCache\(string \\\$function, array \\\$args\){\n/g" $SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php) # add new libs
fi

if [ -f "$SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/protected array \\\$config = \[\]\n    \) {/protected array \\\$config = \[\], protected ?string \\\$modeGroup = ''\n    \) {/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/'cache_time' => 10 \* 60/'cache_time' => setting\('cache_time', 60 \* 24 \* 1\) \* 60, \/\/ 1 day/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/public static function make\(string \\\$group\): static\n    {/public function getGroup\(\){ if\(\!blank\(\\\$this->modeGroup\)\){ \\\$user_id = request\(\)->user\(\)->id; if\(\!blank\(\\\$user_id\)\){  return  \\\$this->cacheGroup . '_'. \\\$this->modeGroup. '_' .\\\$user_id.'_'; } } return \\\$this->cacheGroup; }\n\n\tpublic static function make\(string \\\$group\): static {\n/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/md5\(\\\$this->cacheGroup\)/md5\(\\\$this->getGroup\(\)\)/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/\(\\\$cacheKeys, \\\$this->cacheGroup/\(\\\$cacheKeys, \\\$this->getGroup\(\)/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/\\\$cacheKeys\[\\\$this->cacheGroup\]\[\] = \\\$key;/\\\$cacheKeys\[\\\$this->getGroup\(\)\]\[\] = \\\$key;/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/unset\(\\\$cacheKeys\[\\\$this->cacheGroup/unset\(\\\$cacheKeys\[\\\$this->getGroup\(\)/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)
fi

if [ -f "$SCRIPT_PATH/../dev/core/base/src/Exceptions/Handler.php" ]; then
  rm -f $SCRIPT_PATH/../dev/core/base/src/Exceptions/Handler.php
  cp $SCRIPT_PATH/../bin/remove-bb.overwrite/dev/core/base/src/Exceptions/Handler.php $SCRIPT_PATH/../dev/core/base/src/Exceptions/Handler.php
fi

# if [ -f "$SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php" ]; then
#   rm -f $SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php
#   cp $SCRIPT_PATH/../bin/remove-bb.overwrite/dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php $SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php
# fi

# if [ -f "$SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php" ]; then
#   rm -f $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php
#   cp $SCRIPT_PATH/../bin/remove-bb.overwrite/dev/core/support/src/Services/Cache/Cache.php $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php
# fi

## Hack license +1k years
## (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe "s/return \$response\-\>setError\(\)\-\>setMessage\(\'Your license is invalid, please contact support\'\)\;/\/\/ return \$response\-\>setError\(\)\-\>setMessage\(\'Your license is invalid, please contact support.\'\)\;/g")

############################ VERY IMPORTANT: Below lines MUST BE run at the end of ABOVE process
############################ BEGIN: make sure all botble\.com domain already have replaced by fsofts\.com
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.sql' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\.com/fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\.com/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\.com/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\.com/fsofts\.com/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble\.com/cms\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\.com/cms\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/botble\.com/cms\.fsofts\.com/g')

## BEGIN: Assets & Git Commit Checker Package Processing
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/assets\"\: \"\^1\.0\"/\"dev\/assets\"\: \"\*\@dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/form-builder\"\: \"\^1\.0\"/\"dev\/form-builder\"\: \"\*\@dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/data-synchronize\"\: \"\^1\.0\"/\"dev\/data-synchronize\"\: \"\*\@dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/assets/\"dev\/assets/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/form-builder/\"dev\/form-builder/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/data-synchronize/\"dev\/data-synchronize/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble-package/\"package/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/api\"\: \"\^2\.0\.0\"/\"dev\/api\"\: \"\*\@dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/api\"\: \"\^2\.1\"/\"dev\/api\"\: \"\*\@dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/dev-tool\"\: \"\^1\.0\.2\"/\"dev\/dev-tool\"\: \"\*\@dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/dev-tool\"\: \"\^2\.0\"/\"dev\/dev-tool\"\: \"\*\@dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/dev-tool/\"dev\/dev-tool/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/git-commit-checker\"\: \"\^1\.0\"/\"dev\/git-commit-checker\"\: \"\*\@dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/git-commit-checker\"\: \"\^2\.0\"/\"dev\/git-commit-checker\"\: \"\*\@dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/git-commit-checker\"\: \"\^2\.1\"/\"dev\/git-commit-checker\"\: \"\*\@dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/git-commit-checker/\"dev\/git-commit-checker/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble-vnpayment-plugin/vnpayment/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble-2fa/2fa/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble-ip-blocker/ip-blocker/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble-plugin/plugin/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble api/dev api/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble dev tools/dev dev tools/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Botble CMS/Laravel Dev CMS/g')
## END: Assets & Git Commit Checker Package Processing

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'LICENSE' -print0 | xargs -0 perl -i -pe 's/contact\@botble\.com/contact\@fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'LICENSE' -print0 | xargs -0 perl -i -pe 's/Botble Technologies/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'LICENSE' -print0 | xargs -0 perl -i -pe 's/Friends Of Botble/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'LICENSE' -print0 | xargs -0 perl -i -pe 's/Friends of Botble/Laravel Technologies/g')

if [ -f "$SCRIPT_PATH/../composer.lock" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble\\\\/Dev\\\\/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\//\"dev\//g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/github\.com\/botble/github\.com\/vswb/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/github\.com\/repos\/botble/github\.com\/repos\/vswb/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/friendsofbotble\.com/fsofts\.com/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble\.com/cms\.fsofts\.com/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble.ticksy\.com/vswb\.ticksy\.com/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Sang Nguyen/Developer Team/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble Technologies/Laravel Technologies/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble CMS/Laravel CMS/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Botble Platform/Laravel CMS/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble/\"dev/g' $SCRIPT_PATH/../composer.lock)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/sangnguyenplus\@gmail\.com/admin\@fsofts\.com/g' $SCRIPT_PATH/../composer.lock)
fi

(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/data-synchronize/\"dev\/data-synchronize/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/get-started/\"dev\/get-started/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/installer/\"dev\/installer/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/git-commit-checker/\"dev\/git-commit-checker/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/comment/\"dev\/comment/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/api/\"dev\/api/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/menu/\"dev\/menu/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/optimize/\"dev\/optimize/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/page/\"dev\/page/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/platform/\"dev\/dev/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/shortcode/\"dev\/shortcode/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/theme\"/\"dev\/theme\"/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/theme-generator\"/\"dev\/theme-generator\"/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/plugin-management/\"dev\/plugin-management/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/dev-tool/\"dev\/dev-tool/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/plugin-generator/\"dev\/plugin-generator/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/widget-generator/\"dev\/widget-generator/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/revision/\"dev\/revision/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/sitemap/\"dev\/sitemap/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/slug/\"dev\/slug/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/seo-helper/\"dev\/seo-helper/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/widget/\"dev\/widget/g' $SCRIPT_PATH/../composer.json)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\"botble\/packages/\"dev\/libs/g' $SCRIPT_PATH/../composer.json)

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/\{-module\}/\"dev\/\{-module\}/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/audit-log/\"dev\/audit-log/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/backup/\"dev\/backup/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/block/\"dev\/block/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/blog/\"dev\/blog/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/contact/\"dev\/contact/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/custom-fields/\"dev\/custom-fields/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/gallery/\"dev\/gallery/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/language/\"dev\/language/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/language-advanced/\"dev\/language-advanced/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/member/\"dev\/member/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/request-log/\"dev\/request-log/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/get-started/\"dev\/get-started/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/installer/\"dev\/installer/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/git-commit-checker/\"dev\/git-commit-checker/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/comment/\"dev\/comment/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/dev-tool/\"dev\/dev-tool/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/api\"/\"dev\/api\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/menu\"/\"dev\/menu\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/optimize\"/\"dev\/optimize\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/page\"/\"dev\/page\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/platform\"/\"dev\/dev\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/shortcode\"/\"dev\/shortcode\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/theme\"/\"dev\/theme\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/theme-generator\"/\"dev\/theme-generator\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/plugin-management/\"dev\/plugin-management/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/dev-tool/\"dev\/dev-tool/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/plugin-generator/\"dev\/plugin-generator/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/widget-generator\"/\"dev\/widget-generator\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\/\{\-theme\}/dev\/\{\-theme\}/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/widget\"/\"dev\/widget\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/sitemap/\"dev\/sitemap/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/slug/\"dev\/slug/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/seo-helper/\"dev\/seo-helper/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/revision/\"dev\/revision/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/analytics/\"dev\/analytics/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/social-login/\"dev\/social-login/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/captcha/\"dev\/captcha/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/translation/\"dev\/translation/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/\{\-name\}/\"dev\/\{\-name\}/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/git-commit-checker/\"dev\/git-commit-checker/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/impersonate/\"dev\/impersonate/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/payment/\"dev\/payment/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/newsletter/\"dev\/newsletter/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/mollie/\"dev\/mollie/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/paystack/\"dev\/paystack/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/razorpay/\"dev\/razorpay/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/square/\"dev\/square/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/simple-slider/\"dev\/simple-slider/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/get-started/\"dev\/get-started/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/ecommerce/\"dev\/ecommerce/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/ads/\"dev\/ads/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/faq/\"dev\/faq/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/location/\"dev\/location/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/paypal/\"dev\/paypal/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/shippo/\"dev\/shippo/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/sslcommerz/\"dev\/sslcommerz/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/stripe/\"dev\/stripe/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/testimonial/\"dev\/testimonial/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/career/\"dev\/career/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/real-estate/\"dev\/real-estate/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/flex-home/\"dev\/flex-home/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/rss-feed/\"dev\/rss-feed/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/code-highlighter/\"dev\/code-highlighter/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/log-viewer/\"dev\/log-viewer/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/maintenance-mode/\"dev\/maintenance-mode/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/my-style/\"dev\/my-style/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/edit-lock/\"dev\/edit-lock/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/post-scheduler/\"dev\/post-scheduler/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"friendsofbotble\/barcode-generator/\"dev\/barcode-generator/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/wordpress-importer/\"dev\/wordpress-importer/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"friendsofbotble\/sms-gateways/\"dev\/sms-gateways/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"friendsofbotble\/sms-gateway/\"dev\/sms-gateway/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/ngoquocdat\.dev/docs\.fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Ngo Quoc Dat/Developer Team/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Friends Of Botble/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Friend Of Botble/Laravel Technologies/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.xml' -print0 | xargs -0 perl -i -pe 's/Botble Test Suite/Laravel CMS Test Suite/g')

if [ -d "$SCRIPT_PATH/../public/storage" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../public/storage/ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/botble.test/fsofts\.com/g')
fi

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"botble\/cookie-consent/\"dev\/cookie-consent/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/\"botble\/cookie-consent/\"dev\/cookie-consent/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/window\.botbleCookieConsent/window\.appsCookieConsent/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/window\.botbleCookieConsent/window\.appsCookieConsent/g')

############################ END: make sure all botble\.com domain already have replaced by fsofts\.com
#

## TOC PLUGIN
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/github\.com\/nivianh/github\.com\/vswb/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Plugin\\\\ToC\\\\/Dev\\\\ToC\\\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Plugin\\ToC\\/Dev\\ToC\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Plugin\\ToC/Dev\\ToC/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/github\.com\/nivianh\//github\.com\/vswb\//g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Plugin\\\\ToC\\\\/Dev\\\\ToC\\\\/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/github\.com\/nivianh\//github\.com\/vswb\//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/github\.com\/nivianh/github\.com\/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/nivianh\/toc/platform\/toc/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Anh Ngo/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Bao Boi/Laravel Technologies/g')
## END TOC PLUGIN

## FOB COMMENT PLUGIN
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/github\.com\/baoboine\//github\.com\/vswb\//g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/github\.com\/baoboine\/botble-comment/github\.com\/vswb/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/fob-comment/comment/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/fob-comment/comment/g')
## END FOB COMMENT PLUGIN

## REMOVE JS
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../storage/ -type f -print0 | xargs -0 perl -i -pe 's/workspace\/botble/workspace\/laravel-cms/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../storage/ -type f -print0 | xargs -0 perl -i -pe 's/botble.test/fsofts\.com/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble.widget/apps\.widget/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/BotbleVariables\./AppVars\./g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/BotbleVariables/AppVars/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble\.show/Apps\.show/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble\.hide/Apps\.hide/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble\.handle/Apps\.handle/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Botble\.init/Apps\.init/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_URL\./APP_MEDIA_URL\./g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/filter_table_id\=botble/filter_table_id\=dev/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/class\=Botble/class\=Dev/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble_footprints_cookie/dev_footprints_cookie/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble_footprints_cookie_data/dev_footprints_cookie_data/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/typeof Botble/typeof Apps/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/core/ -type f -name '*.blade.php' -print0 | xargs -0 perl -i -pe 's/settings.license.verify.index/kernel.api.v1.license.verify/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/core/ -type f -name '*.blade.php' -print0 | xargs -0 perl -i -pe 's/settings.license.verify/kernel.api.v1.license.verify/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/'license.check'/'kernel.api.v1.license.check'/g" $SCRIPT_PATH/../dev/core/base/resources/views/components/layouts/base.blade.php)

# kiểm tra kỹ các vấn đề về JS chỗ này.
if [ -f $SCRIPT_PATH/../dev/core/base/public/js/core.js ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble\-/dev\-/g' $SCRIPT_PATH/../dev/core/base/public/js/core.js)
else
  echo -e "$COL_RED Could not found dev/core/base/public/js/core.js $NORMAL"
fi
if [ -f $SCRIPT_PATH/../dev/core/base/resources/js/core.js ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble\-/dev\-/g' $SCRIPT_PATH/../dev/core/base/resources/js/core.js)
else
  echo -e "$COL_RED Could not found dev/core/base/resources/js/core.js $NORMAL"
fi
if [ -f $SCRIPT_PATH/../dev/plugins/code-highlighter/src/CodeHighlighter.php ]; then
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/botble.min.css/code-highlighter.min.css/g' $SCRIPT_PATH/../dev/plugins/code-highlighter/src/CodeHighlighter.php)
else
  echo -e "$COL_RED Could not found dev/core/base/resources/js/core.js $NORMAL"
fi

if [ -f $SCRIPT_PATH/../dev/plugins/code-highlighter/public/libraries/hljs/botble.min.css ]; then
  
  (LC_ALL=C mv $SCRIPT_PATH/../dev/plugins/code-highlighter/public/libraries/hljs/botble.min.css $SCRIPT_PATH/../dev/plugins/code-highlighter/public/libraries/hljs/code-highlighter.min.css)
  echo -e "$BLUE Renamed botble.min.css > code-highlighter.min.css $NORMAL"
else
  echo -e "$COL_RED Could not found botble.min.css $NORMAL"
fi

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/typeof Botble/typeof Apps/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/user\/botble\/portfolio/user\/vswb\/portfolio/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/Botble Media/Apps Media/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/BotbleVariables\./AppVars\./g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/BotbleVariables/AppVars/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/export default class Botble/export default class Apps/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/import Botble from/import Apps from/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/class Botble/class Apps/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/new Botble/new Apps/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/window\.botbleCookieNewsletter/window\.appsCookieNewsletter/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/window\.Botble \= Botble/window\.Apps \= Apps/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/window\.Botble/window\.Apps/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/Botble\;/Apps\;/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/Botble\.show/Apps\.show/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/Botble\.hide/Apps\.hide/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/Botble\.handle/Apps\.handle/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/Botble\./Apps\./g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_URL\./APP_MEDIA_URL\./g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/Botble ckeditor/Laravel ckeditor/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/Created by Botble/Created by Laravel/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/user\/john-smith/user\/fsofts/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/user\/botble\/portfolio/user\/vswb\/portfolio/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/window\.Botble \= Botble/window\.Apps \= Apps/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/window\.Botble/window\.Apps/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/Botble\.show/Apps\.show/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/Botble\.hide/Apps\.hide/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/Botble\.handle/Apps\.handle/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/Botble\./Apps\./g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_URL\./APP_MEDIA_URL\./g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.vue' -print0 | xargs -0 perl -i -pe 's/BotbleVariables\./AppVars\./g')

## END REMOVE JS

## REMOVE RV MEDIA
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/RvMedia\"/AppMedia\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/RvMedia\:\:/AppMedia\:\:/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RvMedia\:\:/AppMedia\:\:/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rvMedia\:\:/AppMedia\:\:/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RvMediaFacade\:\:/AppMediaFacade\:\:/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/class RvMediaFacade/class AppMediaFacade/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/class RvMedia/class AppMedia/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/use RvMedia\;/use AppMedia\;/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Platform\\Media\\RvMediaFacade/Dev\\Media\\AppMediaFacade/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Platform\\Media\\RvMedia/Dev\\Media\\AppMedia/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RvMedia/AppMedia/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_CONFIG/APP_MEDIA_CONFIG/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_WATERMARK_/APP_MEDIA_WATERMARK_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_UPLOAD_CHUNK/APP_MEDIA_UPLOAD_CHUNK/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_DEFAULT/APP_MEDIA_DEFAULT/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_SIDEBAR/APP_MEDIA_SIDEBAR/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_DOCUMENT_/APP_MEDIA_DOCUMENT_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_ALLOWED/APP_MEDIA_ALLOWED/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv_media_handle_upload/app_media_handle_upload/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv_media_modal/app_media_modal/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/\#rv_media_/\#app_media_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/id\=\"rv_media_/id\=\"app_media_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/id\=\"rv_action_/id\=\"app_action_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv-action/app-action/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv-media/app-media/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv-dropdown/app-dropdown/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv-clipboard/app-clipboard/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv-modals/app-modals/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv-upload/app-upload/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv-table/app-table/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv-form/app-form/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/rv-btn/app-btn/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/window\.rvMedia\./window\.appMedia\./g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/window\.rvMedia/window\.appMedia/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/fn\.rvMedia/fn\.appMedia/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\.rvMedia/\.appMedia/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\= rvMedia/\= appMedia/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\$rvMediaContainer/\$appMediaContainer/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rvMediaContainer/appMediaContainer/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rvMedia\;/appMedia;/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/class rvMedia/class appMedia/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/new rvMedia/new appMedia/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/new RvMediaStandAlone/new AppMediaStandAlone/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/window\.RvMediaStandAlone/window\.AppMediaStandAlone/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_CONFIG/APP_MEDIA_CONFIG/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_WATERMARK_/APP_MEDIA_WATERMARK_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_UPLOAD_CHUNK/APP_MEDIA_UPLOAD_CHUNK/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_DEFAULT/APP_MEDIA_DEFAULT/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_SIDEBAR/APP_MEDIA_SIDEBAR/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_DOCUMENT_/APP_MEDIA_DOCUMENT_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv_media_handle_upload/app_media_handle_upload/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv_media_modal/app_media_modal/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\#rv_media_/\#app_media_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\#rv_action/\#app_action/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv_action/app_action/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv_media_/app_media_/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv-action/app-action/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv-media/app-media/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv-dropdown/app-dropdown/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv-clipboard/app-clipboard/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv-modals/app-modals/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv-upload/app-upload/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv-table/app-table/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv-form/app-form/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/rv-btn/app-btn/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/\#rv_media_/\#app_media_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/\#rv_media_/\#app_media_/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/rv-media/app-media/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/rv-media/app-media/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/rv_action/app_action/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/rv_action/app_action/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/rv-dropdown/app-dropdown/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/rv-dropdown/app-dropdown/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/rv-clipboard/app-clipboard/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/rv-clipboard/app-clipboard/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/rv-modals/app-modals/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/rv-modals/app-modals/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/rv-upload/app-upload/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/rv-upload/app-upload/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/rv-table/app-table/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/rv-table/app-table/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/rv-form/app-form/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/rv-form/app-form/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/rv-btn/app-btn/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.css' -print0 | xargs -0 perl -i -pe 's/rv-btn/app-btn/g')

## Must run at the of block
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_URL/APP_MEDIA_URL/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/RV_MEDIA_URL/APP_MEDIA_URL/g')
## END REMOVE RV MEDIA

if [ -f $SCRIPT_PATH/../dev/core/media/src/RvMedia.php ]; then
  rm -f $SCRIPT_PATH/../dev/core/media/src/AppMedia.php
  (LC_ALL=C mv $SCRIPT_PATH/../dev/core/media/src/RvMedia.php $SCRIPT_PATH/../dev/core/media/src/AppMedia.php)
  echo -e "$BLUE Renamed RvMedia > AppMedia $NORMAL"
else
  echo -e "$COL_RED Could not found RvMedia $NORMAL"
fi

if [ -f $SCRIPT_PATH/../dev/core/media/src/Facades/RvMedia.php ]; then
  rm -f $SCRIPT_PATH/../dev/core/media/src/Facades/AppMediaFacade.php
  (LC_ALL=C mv $SCRIPT_PATH/../dev/core/media/src/Facades/RvMedia.php $SCRIPT_PATH/../dev/core/media/src/Facades/AppMedia.php)
  echo -e "$BLUE Renamed Facades/RvMedia > Facades/AppMedia $NORMAL"
else
  echo -e "$COL_RED Could not found Facades/RvMedia $NORMAL"
fi
## END REMOVE RV MEDIA

## ABSOLUTE PATH PROCESSING
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/\`platform\/core/\`dev\/core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/\`platform\/plugins/\`dev\/plugins/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\`platform\/core/\`dev\/core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\`platform\/plugins/\`dev\/plugins/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\`platform\/themes/\`dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\`platform\/packages/\`dev\/libs/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/platform\/core/dev\/core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/platform\/plugins/dev\/plugins/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/platform\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/platform\/packages/dev\/libs/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe "s/'packages'/'libs'/g")
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/platform\/\$/dev\/\$/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/platform\/core/dev\/core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/platform\/plugins/dev\/plugins/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/platform\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/platform\/packages/dev\/libs/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/platform\/\$/dev\/\$/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/platform\/\*/dev\/\*/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.yml' -print0 | xargs -0 perl -i -pe 's/platform\/core/dev\/core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.yml' -print0 | xargs -0 perl -i -pe 's/platform\/plugins/dev\/plugins/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.yml' -print0 | xargs -0 perl -i -pe 's/platform\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.yml' -print0 | xargs -0 perl -i -pe 's/platform\/packages/dev\/libs/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/platform\/core/dev\/core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/platform\/plugins/dev\/plugins/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/platform\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/platform\/packages/dev\/libs/g')

## do not move below line's position
if [ -d $SCRIPT_PATH/../dev/libs/dev-tool ]; then
  (cd $SCRIPT_PATH/../dev/libs/dev-tool && LC_ALL=C find $SCRIPT_PATH/../dev/libs/dev-tool -type f -name '*.php' -print0 | xargs -0 perl -i -pe "s/'packages'/'libs'/g")
else
  echo -e "$COL_RED Could not found packages $NORMAL"
fi
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe "s/packages\/theme/libs\/theme/g")
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe "s/packages\/data-synchronize/libs\/data-synchronize/g")
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe "s/packages\/api/libs\/api/g")
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe "s/'packages\./'libs./g")
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe "s/'packages\//'libs\//g")

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe "s/packages\/theme/libs\/theme/g")
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/platform\/core/dev\/core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/platform\/plugins/dev\/plugins/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/platform\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/platform\/packages/dev\/libs/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/platform\/core/dev\/core/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/platform\/plugins/dev\/plugins/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/platform\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/platform\/packages/dev\/libs/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/botble\/dev-tool/dev\/dev-tool/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/public\/themes/public\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/sms-gateways/dev\/sms-gateways/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/botble\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/dev\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/vendor\/themes/vendor\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/vendor\/packages/vendor\/libs/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/vendor\/core\/packages/vendor\/core\/libs/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/public\/themes/public\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/dev\/themes/dev\/ui/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/comment/dev\/comment/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/sms-gateways/dev\/sms-gateways/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/sms-gateway/dev\/sms-gateway/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/pwa/dev\/pwa/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/google-maps-geocoding/dev\/google-maps-geocoding/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/barcode-generator/dev\/barcode-generator/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/ticksify/dev\/ticksify/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/geo-data-detector/dev\/geo-data-detector/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/request-quote/dev\/request-quote/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/vietnam-bank-qr/dev\/vietnam-bank-qr/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/email-log/dev\/email-log/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/comment/dev\/comment/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/sms-gateways/dev\/sms-gateways/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/sms-gateway/dev\/sms-gateway/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/pwa/dev\/pwa/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/google-maps-geocoding/dev\/google-maps-geocoding/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/barcode-generator/dev\/barcode-generator/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/ticksify/dev\/ticksify/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/geo-data-detector/dev\/geo-data-detector/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/request-quote/dev\/request-quote/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/vietnam-bank-qr/dev\/vietnam-bank-qr/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/email-log/dev\/email-log/g')

if [ -f "$SCRIPT_PATH/../dev/plugins/request-quote/resources/email-templates/admin-notification.tpl" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/plugins\/fob-/plugins\//g" $SCRIPT_PATH/../dev/plugins/request-quote/resources/email-templates/admin-notification.tpl)
fi
if [ -f "$SCRIPT_PATH/../dev/plugins/request-quote/resources/email-templates/customer-confirmation.tpl" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/plugins\/fob-/plugins\//g" $SCRIPT_PATH/../dev/plugins/request-quote/resources/email-templates/customer-confirmation.tpl)
fi

(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/'themes'/'ui'/g" $SCRIPT_PATH/../dev/libs/theme/config/general.php)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/\('themes/\('ui/g" $SCRIPT_PATH/../dev/libs/theme/helpers/helpers.php)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/\('themes/\('ui/g" $SCRIPT_PATH/../dev/libs/theme/src/Manager.php)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/\('themes/\('ui/g" $SCRIPT_PATH/../dev/libs/theme/src/Services/ThemeService.php)

(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/\`platform\/themes/\`dev\/ui/g' $SCRIPT_PATH/../webpack.mix.js)
(cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/'themes'/'ui'/g" $SCRIPT_PATH/../webpack.mix.js)

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/public\/themes/public\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/botble\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/dev\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/vendor\/core\/packages/vendor\/core\/libs/g')

(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/botble\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/dev\/themes/dev\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/public\/themes/public\/ui/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 perl -i -pe 's/botble\/botble/vswb/g')

if [ -f $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/platform\//dev\//g' $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
else
  echo -e "$COL_RED Could not found LoadAndPublishDataTrait.php $NORMAL"
fi

if [ -f $SCRIPT_PATH/../dev/core/acl/src/Models/Role.php ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/'packages'/'libs'/g" $SCRIPT_PATH/../dev/core/acl/src/Models/Role.php)
else
  echo -e "$COL_RED Could not found dev/core/acl/src/Models/Role.php $NORMAL"
fi

if [ -f $SCRIPT_PATH/../dev/core/base/src/Supports/Helper.php ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/'packages'/'libs'/g" $SCRIPT_PATH/../dev/core/base/src/Supports/Helper.php)
else
  echo -e "$COL_RED Could not found dev/core/base/src/Supports/Helper.php $NORMAL"
fi

if [ -f $SCRIPT_PATH/../dev/libs/assets/config/assets.php ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/packages\/bootstrap\/css\/bootstrap.min.css/public\/ui\/master\/plugins\/bootstrap\/css\/bootstrap.min.css/g' $SCRIPT_PATH/../dev/libs/assets/config/assets.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/vendor\/core\/packages\/modernizr\/modernizr.min.js/public\/vendor\/core\/core\/base\/libraries\/modernizr\/modernizr.min.js/g' $SCRIPT_PATH/../dev/libs/assets/config/assets.php)
else
  echo -e "$COL_RED Could not found assets.php $NORMAL"
fi

if [ -d $SCRIPT_PATH/../dev/packages ]; then
  rm -rf $SCRIPT_PATH/../dev/libs && (LC_ALL=C mv $SCRIPT_PATH/../dev/packages $SCRIPT_PATH/../dev/libs)
  echo -e "$BLUE Renamed packages > libs $NORMAL"
else
  echo -e "$COL_RED Could not found packages $NORMAL"
fi
## END ABSOLUTE PATH PROCESSING

echo -e "$COL_RED BEGIN THEME GENERAL PROCESSING $NORMAL"
## 1. BEGIN THEME GENERAL PROCESSING
if [ -d $SCRIPT_PATH/../lang/vendor/packages ]; then
  echo -e "$BLUE The 'lang/vendor/packages' is existed, renaming lang/vendor/packages to lang/vendor/libs $NORMAL"
  rm -rf $SCRIPT_PATH/../lang/vendor/libs && (LC_ALL=C mv $SCRIPT_PATH/../lang/vendor/packages $SCRIPT_PATH/../lang/vendor/libs)
  echo -e "$BLUE Renamed lang:vendor/packages > lang:vendor/libs $NORMAL"
else
  echo -e "$COL_RED Could not found public:vendor/packages $NORMAL"
fi
if [ -d $SCRIPT_PATH/../public/vendor/core/packages ]; then
  echo -e "$BLUE The 'public/vendor/core/packages' is existed, renaming public/vendor/core/packages to public/vendor/core/libs $NORMAL"
  rm -rf $SCRIPT_PATH/../public/vendor/core/libs && (LC_ALL=C mv $SCRIPT_PATH/../public/vendor/core/packages $SCRIPT_PATH/../public/vendor/core/libs)
  echo -e "$BLUE Renamed public:vendor/core/packages > public:vendor/core/libs $NORMAL"
else
  echo -e "$COL_RED Could not found public:vendor/core/packages $NORMAL"
fi

if [ -d $SCRIPT_PATH/../public/themes ]; then
  echo -e "$BLUE The 'public/themes' is existed, renaming public/themes to public/ui $NORMAL"
  rm -rf $SCRIPT_PATH/../public/ui && (LC_ALL=C mv $SCRIPT_PATH/../public/themes $SCRIPT_PATH/../public/ui)
  echo -e "$BLUE Renamed public:themes > public:ui $NORMAL"
else
  echo -e "$COL_RED Could not found public:themes $NORMAL"
fi
if [ -d $SCRIPT_PATH/../dev/themes ]; then
  echo -e "$BLUE The 'dev/themes' is existed, remove dev/ui first then renaming dev/themes to dev/ui $NORMAL"
  rm -rf $SCRIPT_PATH/../dev/ui && (LC_ALL=C mv $SCRIPT_PATH/../dev/themes $SCRIPT_PATH/../dev/ui)
  echo -e "$BLUE Renamed dev:themes > dev:ui $NORMAL"
else
  echo -e "$COL_RED Could not found dev:themes $NORMAL"
fi

if [ -d $SCRIPT_PATH/../dev/ui ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/package\/theme/libs\/theme/g')

  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/botble\/themes/dev\/ui/g')
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/dev\/themes/dev\/ui/g')
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\`public\/themes/\`public\/ui/g')
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/\`platform\/themes/\`dev\/ui/g')
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/themes/ui/g')

else
  echo -e "$COL_RED Could not found dev/ui $NORMAL"
fi
## END THEME GENERAL PROCESSING

## 1.1 BEGIN RENAME THEME RIPPLE
if [ -d $SCRIPT_PATH/../public/*/ripple ]; then
  echo -e "$BLUE The 'public/*/ripple' is existed, remove public/*/master first then renaming public/*/ripple to public/*/master $NORMAL"
  rm -rf $SCRIPT_PATH/../public/ui/master && (LC_ALL=C mv $SCRIPT_PATH/../public/ui/ripple $SCRIPT_PATH/../public/ui/master)
  echo -e "$BLUE Renamed public:ui:ripple > public:ui:master $NORMAL"
else
  echo -e "$COL_RED Could not found public/*/ripple $NORMAL"
fi

if [ -d $SCRIPT_PATH/../dev/*/ripple ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\/ripple/dev\/master/g')
  if [ -f "$SCRIPT_PATH/../database.sql" ]; then
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/ripple/master/g' $SCRIPT_PATH/../database.sql)
  else
    echo -e "$COL_RED Could not found database.sql $NORMAL"
  fi

  if [ -d $SCRIPT_PATH/../dev/*/ripple ]; then
    echo -e "$BLUE The 'dev/*/ripple' is existed, remove dev/*/master and renaming dev/*/ripple to dev/*/master $NORMAL"
    rm -rf $SCRIPT_PATH/../dev/ui/master && (LC_ALL=C mv $SCRIPT_PATH/../dev/ui/ripple $SCRIPT_PATH/../dev/ui/master)
    echo -e "$BLUE Renamed dev:ui:ripple > dev:ui:master $NORMAL"
  else
    echo -e "$COL_RED Could not found dev:*:ripple $NORMAL"
  fi

  if [ -d $SCRIPT_PATH/../dev/ui ]; then
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\/ripple/dev\/master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/dev\/ripple/dev\/master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Ripple\\/Master\\/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Ripple/Master/g')

    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Ripple\\/Master\\/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Ripple/Master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/ripple.js/master.js/g')

    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/Ripple/Master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/ripple.js/master.js/g')

    ###
    if [ -f $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/RippleController.php ]; then
      rm -f $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/MasterController.php && (LC_ALL=C mv $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/RippleController.php $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/MasterController.php)
      echo -e "$BLUE Renamed RippleController > MasterController $NORMAL"
    else
      echo -e "$COL_RED Could not found RippleController $NORMAL"
    fi
    ###

    if [ -f $SCRIPT_PATH/../dev/ui/master/public/js/ripple.js ]; then
      rm -f $SCRIPT_PATH/../dev/ui/master/public/js/master.js && (LC_ALL=C mv $SCRIPT_PATH/../dev/ui/master/public/js/ripple.js $SCRIPT_PATH/../dev/ui/master/public/js/master.js)
      echo -e "$BLUE Renamed dev/ui/master/public/js/ripple.js > master.js $NORMAL"
    else
      echo -e "$COL_RED Could not found master $NORMAL"
    fi
    if [ -f $SCRIPT_PATH/../dev/ui/master/assets/js/ripple.js ]; then
      rm -f $SCRIPT_PATH/../dev/ui/master/assets/js/master.js && (LC_ALL=C mv $SCRIPT_PATH/../dev/ui/master/assets/js/ripple.js $SCRIPT_PATH/../dev/ui/master/assets/js/master.js)
      echo -e "$BLUE Renamed dev/ui/master/assets/js/ripple.js > master.js $NORMAL"
    else
      echo -e "$COL_RED Could not found master $NORMAL"
    fi

    if [ -f $SCRIPT_PATH/../public/ui/master/js/ripple.js ]; then
      rm -f $SCRIPT_PATH/../public/ui/master/js/master.js && (LC_ALL=C mv $SCRIPT_PATH/../public/ui/master/js/ripple.js $SCRIPT_PATH/../public/ui/master/js/master.js)
      echo -e "$BLUE Renamed public/ui/master/js/ripple.js > master.js $NORMAL"
    else
      echo -e "$COL_RED Could not found master $NORMAL"
    fi
  else
    echo -e "$COL_RED Could not found dev/ui $NORMAL"
  fi
else
  echo -e "$COL_RED Could not found dev/*/ripple $NORMAL"
fi
## END RENAME THEME RIPPLE

## 1.2 BEGIN RENAME THEME SHOPWISE
if [ -d $SCRIPT_PATH/../public/*/shopwise ]; then
  echo -e "$BLUE The 'public/*/shopwise' is existed, remove public/*/master first then renaming public/*/shopwise to public/*/master $NORMAL"
  rm -rf $SCRIPT_PATH/../public/ui/master && (LC_ALL=C mv $SCRIPT_PATH/../public/ui/shopwise $SCRIPT_PATH/../public/ui/master)
  echo -e "$BLUE Renamed public:ui:shopwise > public:ui:master $NORMAL"
else
  echo -e "$COL_RED Could not found public/*/shopwise $NORMAL"
fi

if [ -d $SCRIPT_PATH/../dev/*/shopwise ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\/shopwise/dev\/master/g')
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/Shopwise/Master/g')
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.scss' -print0 | xargs -0 perl -i -pe 's/Bestwebcreator/Master/g')

  if [ -f "$SCRIPT_PATH/../database.sql" ]; then
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/-shopwise-/-master-/g' $SCRIPT_PATH/../database.sql)
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Shopwise/Master/g' $SCRIPT_PATH/../database.sql)
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/shopwise/master/g' $SCRIPT_PATH/../database.sql)
  else
    echo -e "$COL_RED Could not found database.sql $NORMAL"
  fi

  if [ -d $SCRIPT_PATH/../dev/*/shopwise ]; then
    echo -e "$BLUE The 'dev/*/shopwise' is existed, remove dev/*/master and renaming dev/*/shopwise to dev/*/master $NORMAL"
    rm -rf $SCRIPT_PATH/../dev/ui/master && (LC_ALL=C mv $SCRIPT_PATH/../dev/ui/shopwise $SCRIPT_PATH/../dev/ui/master)
    echo -e "$BLUE Renamed dev:ui:shopwise > dev:ui:master $NORMAL"
  else
    echo -e "$COL_RED Could not found dev:*:shopwise $NORMAL"
  fi

  if [ -d $SCRIPT_PATH/../dev/ui ]; then
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\/shopwise/dev\/master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/dev\/shopwise/dev\/master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Shopwise\\/Master\\/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Shopwise/Master/g')

    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Shopwise\\/Master\\/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Shopwise/Master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/shopwise.js/master.js/g')

    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/Shopwise/Master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/shopwise.js/master.js/g')

    ###
    if [ -f $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/ShopwiseController.php ]; then
      rm -f $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/MasterController.php && (LC_ALL=C mv $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/ShopwiseController.php $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/MasterController.php)
      echo -e "$BLUE Renamed ShopwiseController > MasterController $NORMAL"
    else
      echo -e "$COL_RED Could not found ShopwiseController $NORMAL"
    fi
    ###

    if [ -f $SCRIPT_PATH/../dev/ui/master/public/js/shopwise.js ]; then
      rm -f $SCRIPT_PATH/../dev/ui/master/public/js/master.js && (LC_ALL=C mv $SCRIPT_PATH/../dev/ui/master/public/js/shopwise.js $SCRIPT_PATH/../dev/ui/master/public/js/master.js)
      echo -e "$BLUE Renamed shopwise.js > master.js $NORMAL"
    else
      echo -e "$COL_RED Could not found master $NORMAL"
    fi

    if [ -f $SCRIPT_PATH/../public/ui/master/js/shopwise.js ]; then
      rm -f $SCRIPT_PATH/../public/ui/master/js/master.js && (LC_ALL=C mv $SCRIPT_PATH/../public/ui/master/js/shopwise.js $SCRIPT_PATH/../public/ui/master/js/master.js)
      echo -e "$BLUE Renamed shopwise.js > master.js $NORMAL"
    else
      echo -e "$COL_RED Could not found master $NORMAL"
    fi
  else
    echo -e "$COL_RED Could not found packages $NORMAL"
  fi
else
  echo -e "$COL_RED Could not found dev/*/shopwise $NORMAL"
fi
## END RENAME THEME SHOPWISE

## 1.3 BEGIN RENAME THEME FLEXHOME
if [ -d $SCRIPT_PATH/../public/*/flex\-home ]; then
  echo -e "$BLUE The 'public/*/flex-home' is existed, remove public/*/master first then renaming public/*/flex-home to public/*/master $NORMAL"
  rm -rf $SCRIPT_PATH/../public/ui/master && (LC_ALL=C mv $SCRIPT_PATH/../public/ui/flex-home $SCRIPT_PATH/../public/ui/master)
  echo -e "$BLUE Renamed public:ui:flex-home > public:ui:master $NORMAL"
else
  echo -e "$COL_RED Could not found public/*/flex-home $NORMAL"
fi
if [ -d $SCRIPT_PATH/../dev/*/flex\-home ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\/flex-home/dev\/master/g')

  if [ -f "$SCRIPT_PATH/../database.sql" ]; then
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/flex-home/master/g' $SCRIPT_PATH/../database.sql)
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/Flex Home/Shop Zone/g' $SCRIPT_PATH/../database.sql)
  else
    echo -e "$COL_RED Could not found database.sql $NORMAL"
  fi

  if [ -d $SCRIPT_PATH/../dev/*/flex\-home ]; then
    echo -e "$BLUE The 'dev/*/flex-home' is existed, remove dev/*/master and renaming dev/*/flex-home to dev/*/master $NORMAL"
    rm -rf $SCRIPT_PATH/../dev/ui/master && (LC_ALL=C mv $SCRIPT_PATH/../dev/ui/flex-home $SCRIPT_PATH/../dev/ui/master)
    echo -e "$BLUE Renamed dev:ui:flex-home > dev:ui:master $NORMAL"
  else
    echo -e "$COL_RED Could not found dev:ui:flex-home $NORMAL"
  fi

  if [ -d $SCRIPT_PATH/../dev/ui ]; then
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/botble\/flex-home/dev\/master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/dev\/flex-home/dev\/master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/FlexHome\\\\/Master\\\\/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Flex Home/Shop Zone/g')

    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/FlexHome\\\\/Master\\\\/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/FlexHome\\/Master\\/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/FlexHome/Master/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Flex Home/Shop Zone/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/flex-home.js/master.js/g')
    (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 perl -i -pe 's/flex-home.js/master.js/g')

    ###
    if [ -f $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/FlexHomeController.php ]; then
      rm -f $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/MasterController.php && (LC_ALL=C mv $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/FlexHomeController.php $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/MasterController.php)
      echo -e "$BLUE Renamed FlexHomeController > MasterController $NORMAL"
    else
      echo -e "$COL_RED Could not found FlexHomeController $NORMAL"
    fi
    ###

    if [ -f $SCRIPT_PATH/../dev/ui/master/public/js/flex-home.js ]; then
      rm -f $SCRIPT_PATH/../dev/ui/master/public/js/master.js && (LC_ALL=C mv $SCRIPT_PATH/../dev/ui/master/public/js/flex-home.js $SCRIPT_PATH/../dev/ui/master/public/js/master.js)
      echo -e "$BLUE Renamed flex-home.js > master.js $NORMAL"
    else
      echo -e "$COL_RED Could not found master $NORMAL"
    fi

    if [ -f $SCRIPT_PATH/../public/ui/master/js/flex-home.js ]; then
      rm -f $SCRIPT_PATH/../public/ui/master/js/master.js && (LC_ALL=C mv $SCRIPT_PATH/../public/ui/master/js/flex-home.js $SCRIPT_PATH/../public/ui/master/js/master.js)
      echo -e "$BLUE Renamed flex-home.js > master.js $NORMAL"
    else
      echo -e "$COL_RED Could not found master $NORMAL"
    fi
  else
    echo -e "$COL_RED Could not found packages $NORMAL"
  fi
else
  echo -e "$COL_RED Could not found dev/*/flex-home $NORMAL"
fi
## END RENAME THEME FLEXHOME

## REPLACE AUTH / MAIN CONTACT ON PLUGIN
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/\"author\"\: \"Laravel Technologies\"/\"author\"\: \"Laravel Technologies\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/\"author\"\: \"Laravel CMS\"/\"author\"\: \"Laravel Technologies\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/\"url\"\: \"https\:\/\/fsofts\.com\"/\"url\"\: \"mailto\:toan\@visualweber\.com\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/\"url\"\: \"https\:\/\/github\.com\/vswb"/\"url\"\: \"mailto\:toan\@visualweber\.com\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/\"url\"\: \"https\:\/\/cms\.fsofts\.com\"/\"url\"\: \"mailto\:toan\@visualweber\.com\"/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/Developer Team/Laravel Technologies/g')
(cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/Bao Boi/Laravel Technologies/g')
## END REPLACE AUTH / MAIN CONTACT ON PLUGIN

## (cd $SCRIPT_PATH/../ && LC_ALL=C $ZIP -r botble.zip . -x \*.buildpath/\* \*.idea/\* \*.project/\* \*nbproject/\* \*.git/\* \*.svn/\* \*.gitignore\* \*.gitattributes\* \*.md \*.MD \*.log \*.tar.gz \*.gz \*.tar \*.rar \*.DS_Store \*.lock \*desktop.ini vhost-nginx.conf \*.tmp \*.bat bin/delivery.sh bin/remove-botble.sh readme.html composer.lock wp-config.secure.php \*.yml\* \*.editorconfig\* \*.rnd\*)

### Begin AppMedia & WebP support
if [ -f "$SCRIPT_PATH/../dev/core/media/helpers/common.php" ]; then
replacement=$(cat <<'PHP'
/* Prefer .webp if exists for jpg/jpeg/png */
        \$result = AppMedia::getImageUrl(\$url, \$size, \$relativePath, \$default);
        \$originalUrl = \$result !== null ? (string) \$result : null;
        
        if (\$originalUrl === null) {
            return null;
        }
        
        if (function_exists('apps_get_image_url_webp')) {
            \$webpUrl = apps_get_image_url_webp(\$originalUrl);
            return \$webpUrl !== null ? (string) \$webpUrl : \$originalUrl;
        }
        return \$originalUrl;
PHP
)

  cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s|return AppMedia\:\:getImageUrl\(\\\$url, \\\$size, \\\$relativePath, \\\$default\);|$replacement|g" $SCRIPT_PATH/../dev/core/media/helpers/common.php
fi
### ====
if [ -f "$SCRIPT_PATH/../dev/core/media/helpers/common.php" ]; then
replacement=$(cat <<'PHP'
/* Prefer .webp if exists for jpg/jpeg/png */
        \$result = AppMedia::getImageUrl(\$image, \$size, \$relativePath, AppMedia::getDefaultImage());
        \$originalUrl = \$result !== null ? (string) \$result : null;
        
        if (\$originalUrl === null) {
            return null;
        }
        
        if (function_exists('apps_get_image_url_webp')) {
            \$webpUrl = apps_get_image_url_webp(\$originalUrl);
            return \$webpUrl !== null ? (string) \$webpUrl : \$originalUrl;
        }
        return \$originalUrl;
PHP
)

  cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s|return AppMedia\:\:getImageUrl\(\\\$image, \\\$size, \\\$relativePath, AppMedia::getDefaultImage\(\)\);|$replacement|g" $SCRIPT_PATH/../dev/core/media/helpers/common.php
fi
### ====
if [ -f "$SCRIPT_PATH/../dev/core/media/src/AppMedia.php" ]; then
replacement=$(cat <<'PHP'
/* Prefer .webp if exists for jpg/jpeg/png */
if (!empty(\$path)) {
    [\$purePath, \$query] = array_pad(explode('?', \$path, 2), 2, null);
    \$ext = strtolower(pathinfo(\$purePath, PATHINFO_EXTENSION));

    if (in_array(\$ext, ['jpg', 'jpeg', 'png'], true)) {
        \$webpPath = substr(\$purePath, 0, -strlen(\$ext)) . 'webp';

        if (Storage::exists(\$webpPath)) {
            \$path = \$webpPath . (\$query ? ('?' . \$query) : '');
        }
    }
}
\$doSpacesEnabled = \$this->getMediaDriver() === 'do_spaces' && (int) setting('media_do_spaces_cdn_enabled');
if (\$doSpacesEnabled) {
PHP
)

  cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s|if \(\\\$this->getMediaDriver\(\) === 'do_spaces' \&\& \(int\) setting\('media_do_spaces_cdn_enabled'\)\) \{|$replacement|g" $SCRIPT_PATH/../dev/core/media/src/AppMedia.php
fi

### ====
if [ -f "$SCRIPT_PATH/../dev/libs/theme/src/AssetContainer.php" ]; then
replacement=$(cat <<'PHP'
\$originPath = \$this->getCurrentPath\(\) . \$uri;
\$path = \$originPath;
/* Prefer .webp if exists for jpg/jpeg/png */
\$parsedPath = strtok(\$path, '?'); // strip query if any
\$ext = strtolower(pathinfo(\$parsedPath, PATHINFO_EXTENSION));
if (in_array(\$ext, ['jpg', 'jpeg', 'png'])) {
    \$webpPath = substr(\$parsedPath, 0, -strlen(\$ext)) . 'webp';
    if (File::exists(public_path(ltrim(\$webpPath, '/')))) {
        // keep query string if present on original \$path
        \$query = strstr(\$path, '?');
        \$path = \$webpPath . (\$query ?: '');
    }
}
PHP
)

  cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s|\\\$path = \\\$this->getCurrentPath\(\) . \\\$uri;|$replacement|g" $SCRIPT_PATH/../dev/libs/theme/src/AssetContainer.php
fi
### End AppMedia & WebP support