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

command -v $PERL >/dev/null || {
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

[ ! -d $SCRIPT_PATH/../vendor ] && $ECHO "No vendor directory found" || $RM -rf $SCRIPT_PATH/../vendor/
[ ! -d $SCRIPT_PATH/../bootstrap/cache ] && $ECHO "No cache directory found" || $RM -rf $SCRIPT_PATH/../bootstrap/cache/*.php
[ ! -f "$SCRIPT_PATH/../composer.lock" ] && $ECHO "No composer.lock directory found" || $RM -rf $SCRIPT_PATH/../composer.lock
[ ! -f "$SCRIPT_PATH/../composer.phar" ] && $ECHO "No composer.phar directory found" || $RM -rf $SCRIPT_PATH/../composer.phar

if [ -d "$SCRIPT_PATH/../lang" ]; then
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../lang/ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/version of Botble/version of Dev/g')
fi

if [ -f "$SCRIPT_PATH/../database.sql" ]; then
  ### SuperAdmin in Botble CMS
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$10\$GB\.Fw1a\/osntfrkiyX72cO5BxfgMDhg80XpdFHh5joj1udK\/cgAU6/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$\/TFkWFGqoi8ghH8FTOjM4ucqge2KXuZRZ\/4Mv3klr4ZAYxU500ctW/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$LQ4\/xO2jnhCKQwoIrhGdnepKXy\/2fOPdkkVz6v7xdGk5AxICb2BlC/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$AjaffJm\/SgRqIkEq\.Hw6lOiKhKDhvYyaTmaohTHLM9thXe1AhMt3q/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$t\.LS\.QjivLPruXccnl8B0uuy9U8V4k\.6GRcRNJ70qUwfc3\/xtI2Yu/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$K9JNFf8YtY6GqYOxtwHLhOSxFcLEVL7efcp0214\.\/Gr04\/WyNgPk2/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$K9JNFf8YtY6GqYOxtwHLhOSxFcLEVL7efcp0214\.\/Gr04\/WyNgPk2/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$b1nNB4TPBiFcNgUHpVqt5OXhHi9vPRsewXIT9dkV4527QFeeARGOm/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)

  ### SuperAdmin in Flexhome
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$HYEUN4HLrjx5mXO8M1JfBOcqH\.gXdQVl\/qqqJp\/N2d8DHFjtLhaui/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$3ouZBNvZ8yOPcxXxEKJVQuEoMGrK\/QVtpA6FRX2LZwMMAK4Vi\/0Oe/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$TIf84jZuSeuYTPOWpH7rR\.fv0zt4F4ZTDEeCkzNsum2OTvWy9Lcoe/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)

  ### SuperAdmin in Shopwise
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$10\$Y1n8whq\/bq2jjp8WC6kM6evQ2RZwOWxXxTierjBu0i8wtkQjVNHgW/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$fJN4S29g\/mCY133gMhJIRuKJgLfTQS8rwF53rTz\.eE1RmQb7bBUKa/\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\$2y\$12\$bpqcdnX08YKYYWGniJuJ\/e2zuhHdOB2Tmdxikzyn32byRuBJBvbg\./\$2y\$10\$kXdnGd6ihMDut\/f9rm8xQOXg0CG0V1VgyzBa3nrcC5rOVCgBSe7rS/g' $SCRIPT_PATH/../database.sql)

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/kyra\.orn\@ohara.info/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/okeefe\@swaniawski\.biz/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/super\@botble\.com/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/admin\@botble\.com/admin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/user\@botble\.com/user\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/valentine\.stiedemann\@funk\.com/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/alphonso22\@keebler\.info/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/lboyle\@jones\.com/admin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/toni93\@weber\.org/admin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/zokeefe\@swaniawski\.biz/admin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/admin\@botble.com - 159357/superadmin\@fsofts\.com - It\@\@246357/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble - 159357/superadmin\@fsofts\.com - It\@\@246357/g' $SCRIPT_PATH/../database.sql)

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/A young team in Vietnam/Laravel is the best/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/dev-botble/dev-laravel/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/1\.envato\.market\/LWRBY/work\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/https\:\/\/codecanyon\.net\/item\/botble-cms-php-platform-based-on-laravel-framework\/16928182/fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Database\: botble/Database\: laravel/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble CMS/Laravel CMS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/flex-home.com/laravel-realestate\.demo\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble.ticksy.com/work\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble, botble team, botble platform/development team, dev features/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/docs\.botble\.com/work\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/cms\.botble\.com/laravel-cms\.demo\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble.local/work\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble.technologies/laravel/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble Platform/Laravel CMS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/twitter\.com\/botble/twitter\.com\/laravel/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble CMS/Laravel CMS/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble-cms/laravel-cms/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/minhsang2603/toan\.lehuy/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/sangnguyen2603/toan\.lehuy/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/minsang2603/toan\.lehuy/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/sangnguyen\.info/work\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Nghia Minh/Developer Team/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble since v2.0/Laravel CMS since v2.0/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\"botble\//\"dev\//g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/84988606928/84943999819/g' $SCRIPT_PATH/../database.sql)

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble\.cms\@gmail\.com/contact\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/nghiadev\.com/work\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/The Botble/The Laravel/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/minhsang2603\@gmail\.com/contact\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/sangplus\.com/work\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Platform\\\\/Dev\\\\/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Platform\\/Dev\\/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Platform\\\\/Dev\\\\/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Platform\\/Dev\\/g' $SCRIPT_PATH/../database.sql)

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble\\\\/Dev\\\\/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble\\/Dev\\/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble\\\\/Dev\\\\/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble\\/Dev\\/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble\.com/work\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble/Laravel/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble\/cms/laravel\/cms/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\=botble/\=laravel/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Nghia Minh/Developer Team/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble Technologies/Laravel Technologies/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Sang Nguyen/Developer Team/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/support\@company\.com/contact\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/sangnguyenplus\@gmail\.com/contact\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble\.test/laravel-cms\.demo\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/shopwise\.test/laravel-ecommerce\.demo\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/flex-home\.test/laravel-realestate\.demo\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/botble/superadmin\@fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/platform\/packages/dev\/libs/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/platform\/themes/dev\/ui/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/platform\//dev\//g' $SCRIPT_PATH/../database.sql)

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble Technologies/Laravel Technologies/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/BOTBLE Teams/Developer Team/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble Fans/Developer Team/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble team/Developer Team/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble product/Laravel product/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble product/Laravel product/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/good job Botble/good job Laravel product/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/confident in Botble/confident in Laravel product/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Botble puts/Laravel Technologies puts/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/at Botble/at Laravel Technologies/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Thank you Botble/Thank you Laravel/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/flex-home\.work\.fsofts\.com/laravel-realestate\.demo\.fsofts\.com/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/shopwise-/master-/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Shopwise/Master/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/shopwise/master/g' $SCRIPT_PATH/../database.sql)
else
  echo -e "$COL_RED Could not found database.sql $NORMAL"
fi

if [ -f "$SCRIPT_PATH/../database.sql" ]; then
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Ripple/Master/g' $SCRIPT_PATH/../database.sql)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/ripple/master/g' $SCRIPT_PATH/../database.sql)
else
  echo -e "$COL_RED Could not found database.sql $NORMAL"
fi

if [ -d $SCRIPT_PATH/../dev/*/ripple ]; then
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 $PERL -i -pe 's/botble\/ripple/dev\/master/g')
  if [ -f "$SCRIPT_PATH/../database.sql" ]; then
    ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/ripple/master/g' $SCRIPT_PATH/../database.sql)
  else
    echo -e "$COL_RED Could not found database.sql $NORMAL"
  fi
else
  echo -e "$COL_RED Could not found dev/*/ripple $NORMAL"
fi

if [ -d $SCRIPT_PATH/../dev/*/shopwise ]; then
  if [ -f "$SCRIPT_PATH/../database.sql" ]; then
    ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/-shopwise-/-master-/g' $SCRIPT_PATH/../database.sql)
    ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Shopwise/Master/g' $SCRIPT_PATH/../database.sql)
    ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/shopwise/master/g' $SCRIPT_PATH/../database.sql)
  else
    echo -e "$COL_RED Could not found database.sql $NORMAL"
  fi
else
  echo -e "$COL_RED Could not found dev/*/shopwise $NORMAL"
fi

if [ -d $SCRIPT_PATH/../dev/*/flex\-home ]; then
  if [ -f "$SCRIPT_PATH/../database.sql" ]; then
    ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/flex-home/master/g' $SCRIPT_PATH/../database.sql)
    ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/Flex Home/Shop Zone/g' $SCRIPT_PATH/../database.sql)
  else
    echo -e "$COL_RED Could not found database.sql $NORMAL"
  fi
else
  echo -e "$COL_RED Could not found dev/*/flex-home $NORMAL"
fi