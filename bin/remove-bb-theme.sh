################################################################
## Shell script : remove author information with shell,
## This script will be remove author information, namespace (use Dev). No change other application's structure anymore!
##
## Author: Weber Team!
## Copy Right: @2011 Weber Team!
################################################################

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

## BEGIN RENAME THEME
if [ -f "$SCRIPT_PATH/../database.sql" ]; then
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/ripple/master/g' $SCRIPT_PATH/../database.sql)
else
  echo -e "$COL_RED Could not found database.sql $NORMAL"
fi

### rename platform/themes to dev/themes
if [ -d $SCRIPT_PATH/../dev/themes ]; then
  $RM -rf $SCRIPT_PATH/../dev/ui && (LC_ALL=C $MV $SCRIPT_PATH/../dev/themes $SCRIPT_PATH/../dev/ui)
  echo -e "$BLUE Renamed themes > ui $NORMAL"

  if [ -d $SCRIPT_PATH/../dev/ui/ripple ]; then
    $RM -rf $SCRIPT_PATH/../dev/ui/master && (LC_ALL=C $MV $SCRIPT_PATH/../dev/ui/ripple $SCRIPT_PATH/../dev/ui/master)
    echo -e "$BLUE Renamed ripple > master $NORMAL"
  else
    echo -e "$COL_RED Could not found master $NORMAL"
  fi
else
  echo -e "$COL_RED Could not found themes $NORMAL"
fi
### rename public/themes to public/ui
if [ -d $SCRIPT_PATH/../public/themes ]; then
  $RM -rf $SCRIPT_PATH/../public/ui && (LC_ALL=C $MV $SCRIPT_PATH/../public/themes $SCRIPT_PATH/../public/ui)
  echo -e "$BLUE Renamed public/themes > ui $NORMAL"

  if [ -d $SCRIPT_PATH/../public/ui/ripple ]; then
    $RM -rf $SCRIPT_PATH/../public/ui/master && (LC_ALL=C $MV $SCRIPT_PATH/../public/ui/ripple $SCRIPT_PATH/../public/ui/master)
    echo -e "$BLUE Renamed public/ui/ripple > master $NORMAL"
  else
    echo -e "$COL_RED Could not found public/ui/ripple $NORMAL"
  fi

else
  echo -e "$COL_RED Could not found public/themes $NORMAL"
fi

if [ -d $SCRIPT_PATH/../dev/ui ]; then
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 $PERL -i -pe 's/botble\/ripple/dev\/master/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 $PERL -i -pe 's/dev\/ripple/dev\/master/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 $PERL -i -pe 's/Ripple\\/Master\\/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.json' -print0 | xargs -0 $PERL -i -pe 's/Ripple/Master/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 $PERL -i -pe 's/public\/themes/public\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 $PERL -i -pe 's/botble\/themes/dev\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.json' -print0 | xargs -0 $PERL -i -pe 's/dev\/themes/dev\/ui/g')

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe "s/'themes'/'ui'/g" $SCRIPT_PATH/../dev/libs/theme/config/general.php)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe "s/\('themes/\('ui/g" $SCRIPT_PATH/../dev/libs/theme/helpers/helpers.php)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe "s/\('themes/\('ui/g" $SCRIPT_PATH/../dev/libs/theme/src/Manager.php)
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe "s/\('themes/\('ui/g" $SCRIPT_PATH/../dev/libs/theme/src/Services/ThemeService.php)

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/Ripple\\/Master\\/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/Ripple/Master/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/ripple.js/master.js/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/package\/theme/libs\/theme/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/public\/themes/public\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/botble\/themes/dev\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/dev\/themes/dev\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/vendor\/themes/vendor\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/vendor\/packages/vendor\/libs/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.php' -print0 | xargs -0 $PERL -i -pe 's/vendor\/core\/packages/vendor\/core\/libs/g')

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $PERL -i -pe 's/\`platform\/themes/\`dev\/ui/g' $SCRIPT_PATH/../webpack.mix.js)

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 $PERL -i -pe 's/botble\/themes/dev\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 $PERL -i -pe 's/dev\/themes/dev\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 $PERL -i -pe 's/themes/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 $PERL -i -pe 's/Ripple/Master/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../dev/ui/ -type f -name '*.js' -print0 | xargs -0 $PERL -i -pe 's/ripple.js/master.js/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 $PERL -i -pe 's/public\/themes/public\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 $PERL -i -pe 's/botble\/themes/dev\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 $PERL -i -pe 's/dev\/themes/dev\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.js' -print0 | xargs -0 $PERL -i -pe 's/vendor\/core\/packages/vendor\/core\/libs/g')

  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 $PERL -i -pe 's/botble\/themes/dev\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 $PERL -i -pe 's/dev\/themes/dev\/ui/g')
  ($CD $SCRIPT_PATH/../ && LC_ALL=C $FIND $SCRIPT_PATH/../ -type f -name '*.stub' -print0 | xargs -0 $PERL -i -pe 's/public\/themes/public\/ui/g')

  ###
  if [ -f $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/RippleController.php ]; then
    $RM -f $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/RippleController.php
    (LC_ALL=C $MV $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/RippleController.php $SCRIPT_PATH/../dev/ui/master/src/Http/Controllers/MasterController.php)
    echo -e "$BLUE Renamed RippleController > MasterController $NORMAL"
  else
    echo -e "$COL_RED Could not found RippleController $NORMAL"
  fi
  ###

  if [ -f $SCRIPT_PATH/../dev/ui/master/public/js/ripple.js ]; then
    $RM -f $SCRIPT_PATH/../dev/ui/master/public/js/master.js && (LC_ALL=C $MV $SCRIPT_PATH/../dev/ui/master/public/js/ripple.js $SCRIPT_PATH/../dev/ui/master/public/js/master.js)
    echo -e "$BLUE Renamed ripple.js > master.js $NORMAL"
  else
    echo -e "$COL_RED Could not found master $NORMAL"
  fi

  if [ -f $SCRIPT_PATH/../public/ui/master/js/ripple.js ]; then
    $RM -f $SCRIPT_PATH/../public/ui/master/js/master.js && (LC_ALL=C $MV $SCRIPT_PATH/../public/ui/master/js/ripple.js $SCRIPT_PATH/../public/ui/master/js/master.js)
    echo -e "$BLUE Renamed ripple.js > master.js $NORMAL"
  else
    echo -e "$COL_RED Could not found master $NORMAL"
  fi
else
  echo -e "$COL_RED Could not found packages $NORMAL"
fi
## END RENAME THEME