#!/bin/bash

#### HOW TO RUN THIS SCRIPT
# PHP=/usr/local/php82/bin/php bash bin/make-deployment.sh -e d
#
####
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
HASCURL=1
DEVMODE="--no-dev"
PHPCOPTS=" -d memory_limit=-1 "
LS="$(which ls -al)"

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
## SCRIPT_PATH=`pwd -P`
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # return /path/bin
echo -e "$VERT--> Your path: $SCRIPT_PATH $NORMAL"

command -v php >/dev/null || {
  echo "php command not found."
  exit 1
}

## command -v curl >/dev/null || HASCURL=0
command -v curl >/dev/null || {
  echo "curl command not found."
  exit 1
}

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
      DEVMODE="" # default is dev mode
    fi
    if [[ "$2" == 'p' ]]; then
      APPLICATION_ENV="production"
      DEVMODE="--no-dev"
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
  *) # Default case: No more options, so break out of the loop.
    show_help # Display a usage synopsis.
    die 'ERROR: "--env" requires a non-empty option argument.'
    ;;
  esac
  shift
done

export APPLICATION_ENV="${APPLICATION_ENV}"
export APP_ENV="${APPLICATION_ENV}"
export NODE_ENV="${APPLICATION_ENV}"
export CI_ENV="${APPLICATION_ENV}"
export ENVIRONMENT="${APPLICATION_ENV}"

echo -e "$VERT--> You are uing APPLICATION_ENV: $APPLICATION_ENV $NORMAL"
echo "$(date) - Your composer devmod $DEVMODE is running"

nonce=$(md5sum <<< $(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5 )
LOCKFILE=/tmp/zipping_$nonce
EMAILFILE=/tmp/zipping_$nonce.email
if [ -f "$LOCKFILE" ]; then
  # Remove lock file if script fails last time and did not run longer than 2 days due to lock file.
  find "$LOCKFILE" -mtime +2 -type f -delete
  echo "$(date) - Warning - process is running"
  exit 1
fi
## touch $LOCKFILE
## touch $EMAILFILE

################ FOR SYMFONY
if [ -f "$SCRIPT_PATH/../app/console" ]; then
  rm -rf $SCRIPT_PATH/../app/cache/*
  rm -rf $SCRIPT_PATH/../composer.lock

  [ ! -d "$SCRIPT_PATH/../app/cache/ip_data" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/cache/ip_data
  [ ! -f "$SCRIPT_PATH/../app/cache/ip_data/.gitignore" ] && touch $SCRIPT_PATH/../app/cache/ip_data/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/cache/ip_data/.gitignore

  [ ! -d "$SCRIPT_PATH/../app/cache/prod" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/cache/prod
  [ ! -f "$SCRIPT_PATH/../app/cache/prod/.gitignore" ] && touch $SCRIPT_PATH/../app/cache/prod/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/cache/prod/.gitignore

  [ ! -d "$SCRIPT_PATH/../app/cache/prod/annotations" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/cache/prod/annotations
  [ ! -f "$SCRIPT_PATH/../app/cache/prod/annotations/.gitignore" ] && touch $SCRIPT_PATH/../app/cache/prod/annotations/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/cache/prod/annotations/.gitignore

  [ ! -d "$SCRIPT_PATH/../app/cache/prod/data" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/cache/prod/data
  [ ! -f "$SCRIPT_PATH/../app/cache/prod/data/.gitignore" ] && touch $SCRIPT_PATH/../app/cache/prod/data/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/cache/prod/data/.gitignore

  [ ! -d "$SCRIPT_PATH/../app/cache/prod/doctrine" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/cache/prod/doctrine
  [ ! -f "$SCRIPT_PATH/../app/cache/prod/doctrine/.gitignore" ] && touch $SCRIPT_PATH/../app/cache/prod/doctrine/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/cache/prod/doctrine/.gitignore

  [ ! -d "$SCRIPT_PATH/../app/cache/prod/doctrine/cache" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/cache/prod/doctrine/cache
  [ ! -f "$SCRIPT_PATH/../app/cache/prod/doctrine/cache/.gitignore" ] && touch $SCRIPT_PATH/../app/cache/prod/doctrine/cache/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/cache/prod/doctrine/cache/.gitignore

  [ ! -d "$SCRIPT_PATH/../app/cache/prod/doctrine/cache/file_system" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/cache/prod/doctrine/cache/file_system
  [ ! -f "$SCRIPT_PATH/../app/cache/prod/doctrine/cache/file_system/.gitignore" ] && touch $SCRIPT_PATH/../app/cache/prod/doctrine/cache/file_system/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/cache/prod/doctrine/cache/file_system/.gitignore

  [ ! -d "$SCRIPT_PATH/../app/cache/prod/doctrine/orm" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/cache/prod/doctrine/orm
  [ ! -f "$SCRIPT_PATH/../app/cache/prod/doctrine/orm/.gitignore" ] && touch $SCRIPT_PATH/../app/cache/prod/doctrine/orm/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/cache/prod/doctrine/orm/.gitignore

  [ ! -d "$SCRIPT_PATH/../app/cache/prod/doctrine/orm/Proxies" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/cache/prod/doctrine/orm/Proxies
  [ ! -f "$SCRIPT_PATH/../app/cache/prod/doctrine/orm/Proxies/.gitignore" ] && touch $SCRIPT_PATH/../app/cache/prod/doctrine/orm/Proxies/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/cache/prod/doctrine/orm/Proxies/.gitignore

  [ ! -d "$SCRIPT_PATH/../app/cache/run" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/cache/run
  [ ! -f "$SCRIPT_PATH/../app/cache/run/.gitignore" ] && touch $SCRIPT_PATH/../app/cache/run/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/cache/run/.gitignore

  [ ! -d "$SCRIPT_PATH/../app/logs" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../app/logs
  [ ! -f "$SCRIPT_PATH/../app/logs/.gitignore" ] && touch $SCRIPT_PATH/../app/logs/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../app/logs/.gitignore

  [ ! -d "$SCRIPT_PATH/../translations" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../translations
  [ ! -f "$SCRIPT_PATH/../translations/.gitignore" ] && touch $SCRIPT_PATH/../translations/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../translations/.gitignore
fi

################ FOR LARAVEL
if [ -f "$SCRIPT_PATH/../artisan" ]; then
  rm -rf $SCRIPT_PATH/../storage/framework/cache/data/*
  #  rm -rf $SCRIPT_PATH/../storage/framework/sessions
  #  rm -rf $SCRIPT_PATH/../storage/framework/testing
  rm -rf $SCRIPT_PATH/../storage/framework/views/*.php
  rm -rf $SCRIPT_PATH/../storage/logs/*.log
  rm -rf $SCRIPT_PATH/../bootstrap/cache/*.php
  rm -rf $SCRIPT_PATH/../composer.lock

  [ ! -d "$SCRIPT_PATH/../storage/framework/cache/data" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/framework/cache/data || echo $SCRIPT_PATH/../storage/framework/cache/data
  #  [ -f "$SCRIPT_PATH/../storage/framework/cache/.gitignore" ] && echo  "Found: storage/framework/cache/.gitignore" || $TOUCH $SCRIPT_PATH/../storage/framework/cache/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../storage/framework/cache/.gitignore

  [ ! -d "$SCRIPT_PATH/../storage/framework/sessions" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/framework/sessions
  #  [ -f "$SCRIPT_PATH/../storage/framework/sessions/.gitignore" ] && echo  "Found: storage/framework/sessions/.gitignore" || $TOUCH $SCRIPT_PATH/../storage/framework/sessions/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../storage/framework/sessions/.gitignore

  [ ! -d "$SCRIPT_PATH/../storage/framework/testing" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/framework/testing
  #  [ -f "$SCRIPT_PATH/../storage/framework/testing/.gitignore" ] && echo  "Found: storage/framework/testing/.gitignore" || $TOUCH $SCRIPT_PATH/../storage/framework/testing/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../storage/framework/testing/.gitignore

  [ ! -d "$SCRIPT_PATH/../storage/framework/views" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/framework/views
  [ -f "$SCRIPT_PATH/../storage/framework/views/.gitignore" ] && echo  "Found: storage/framework/views/.gitignore" || $TOUCH $SCRIPT_PATH/../storage/framework/views/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../storage/framework/views/.gitignore

  [ ! -d "$SCRIPT_PATH/../storage/logs" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/logs
  [ -f "$SCRIPT_PATH/../storage/logs/.gitignore" ] && echo  "Found: storage/logs/.gitignore" || $TOUCH $SCRIPT_PATH/../storage/logs/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../storage/logs/.gitignore

  [ ! -d "$SCRIPT_PATH/../bootstrap/cache" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../bootstrap/cache
  [ -f "$SCRIPT_PATH/../bootstrap/cache/.gitignore" ] && echo  "Found: bootstrap/cache/.gitignore" || $TOUCH $SCRIPT_PATH/../bootstrap/cache/.gitignore && echo -e "*\n!.gitignore"$'\r' >$SCRIPT_PATH/../bootstrap/cache/.gitignore
fi

################ FOR Zend Framework & Doctrine
if [ -d "$SCRIPT_PATH/../data" ]; then
  ## [ ! -d "$SCRIPT_PATH/../public/themes/webapp/data/captcha"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../public/themes/webapp/data/captcha && touch $SCRIPT_PATH/../public/themes/webapp/data/captcha/index.html
  ## [ ! -d "$SCRIPT_PATH/../public/themes/webapp/data/pdf"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../public/themes/webapp/data/pdf && touch $SCRIPT_PATH/../public/themes/webapp/data/pdf/index.html

  rm -rf $SCRIPT_PATH/../data/cache/*
  rm -rf $SCRIPT_PATH/../data/Doctrine*
  rm -rf $SCRIPT_PATH/../composer.lock

	[ ! -d "$SCRIPT_PATH/../data/cache"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/cache && touch $SCRIPT_PATH/../data/cache/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/cache/.gitignore
	[ ! -d "$SCRIPT_PATH/../data/config"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/config && touch $SCRIPT_PATH/../data/config/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/config/.gitignore
	[ ! -d "$SCRIPT_PATH/../data/tmp"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/tmp && touch $SCRIPT_PATH/../data/tmp/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/tmp/.gitignore
	[ ! -d "$SCRIPT_PATH/../data/logs"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/logs && touch $SCRIPT_PATH/../data/logs/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/logs/.gitignore

  [ ! -d "$SCRIPT_PATH/../data/DoctrineModule"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineModule && touch $SCRIPT_PATH/../data/DoctrineModule/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/DoctrineModule/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineORMModule"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineORMModule && touch $SCRIPT_PATH/../data/DoctrineORMModule/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/DoctrineORMModule/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineORMModule/Hydrator"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineORMModule/Hydrator && touch $SCRIPT_PATH/../data/DoctrineORMModule/Hydrator/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/DoctrineORMModule/Hydrator/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineORMModule/Proxy"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineORMModule/Proxy && touch $SCRIPT_PATH/../data/DoctrineORMModule/Proxy/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/DoctrineORMModule/Proxy/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineMongoODMModule"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineMongoODMModule && touch $SCRIPT_PATH/../data/DoctrineMongoODMModule/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/DoctrineMongoODMModule/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineMongoODMModule/Hydrator"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineMongoODMModule/Hydrator && touch $SCRIPT_PATH/../data/DoctrineMongoODMModule/Hydrator/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/DoctrineMongoODMModule/Hydrator/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineMongoODMModule/Proxy"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineMongoODMModule/Proxy && touch $SCRIPT_PATH/../data/DoctrineMongoODMModule/Proxy/.gitignore && echo -e "*\n!.gitignore"$'\r' > $SCRIPT_PATH/../data/DoctrineMongoODMModule/Proxy/.gitignore
fi