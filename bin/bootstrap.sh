#!/bin/bash

# PHP=/opt/homebrew/Cellar/php@7.4/7.4.33_7/bin/php bash bin/bootstrap.sh -e d
# PHP=/usr/local/php82/bin/php bash bin/bootstrap.sh -e d

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
LS="$(which ls )"

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

## Lưu ý path trong subshell sẽ mất khi ra ngoài parent path
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # directory changed in the subshell, and return /path/bin
echo -e "$VERT--> Your path bin: $SCRIPT_PATH $NORMAL"

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
  *)          # Default case: No more options, so break out of the loop.
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

nonce=$(md5sum <<<$(ip route get 8.8.8.8 | awk '{print $NF; exit}')$(hostname) | cut -c1-5)
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

################ FOR LARAVEL
if [ -f "$SCRIPT_PATH/../artisan" ]; then

  rm -rf $SCRIPT_PATH/../storage/framework/cache/data/*
  rm -rf $SCRIPT_PATH/../storage/framework/sessions/*
  rm -rf $SCRIPT_PATH/../storage/framework/testing/*
  rm -rf $SCRIPT_PATH/../storage/framework/views/*.php
  rm -rf $SCRIPT_PATH/../storage/app/*
  rm -rf $SCRIPT_PATH/../storage/debugbar/*
  rm -rf $SCRIPT_PATH/../bootstrap/cache/*.php

  [ ! -d "$SCRIPT_PATH/../storage/framework/cache/data" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/framework/cache/data || echo $SCRIPT_PATH/../storage/framework/cache/data
  [ ! -d "$SCRIPT_PATH/../storage/framework/sessions" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/framework/sessions
  [ ! -d "$SCRIPT_PATH/../storage/framework/testing" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/framework/testing
  [ ! -d "$SCRIPT_PATH/../storage/framework/views" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/framework/views
  [ ! -d "$SCRIPT_PATH/../storage/logs" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/logs
  [ ! -d "$SCRIPT_PATH/../storage/app" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/app
  [ ! -d "$SCRIPT_PATH/../storage/debugbar" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../storage/debugbar
  [ ! -d "$SCRIPT_PATH/../bootstrap/cache" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../bootstrap/cache

  if ! [ -f "$SCRIPT_PATH/../storage/framework/.gitignore" ]; then
    touch $SCRIPT_PATH/../storage/framework/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../storage/framework/.gitignore
  fi
  if ! [ -f "$SCRIPT_PATH/../storage/logs/.gitignore" ]; then
    touch $SCRIPT_PATH/../storage/logs/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../storage/logs/.gitignore
  fi
  if ! [ -f "$SCRIPT_PATH/../storage/app/.gitignore" ]; then
    touch $SCRIPT_PATH/../storage/app/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../storage/app/.gitignore
  fi
  if ! [ -f "$SCRIPT_PATH/../storage/debugbar/.gitignore" ]; then
    touch $SCRIPT_PATH/../storage/debugbar/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../storage/debugbar/.gitignore
  fi
  if ! [ -f "$SCRIPT_PATH/../bootstrap/cache/.gitignore" ]; then
    touch $SCRIPT_PATH/../bootstrap/cache/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../bootstrap/cache/.gitignore
  fi
  if ! [ -f "$SCRIPT_PATH/../public/storage/.gitignore" ]; then
    touch $SCRIPT_PATH/../public/storage/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../public/storage/.gitignore
  fi

  if ! [ -f "$SCRIPT_PATH/../.env" ]; then
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/APP_DEBUG\=true/APP_DEBUG\=false/g' $SCRIPT_PATH/../.env)
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/APP_ENV\=local/APP_ENV\=production/g' $SCRIPT_PATH/../.env)
  fi
  if ! [ -f "$SCRIPT_PATH/../.env.example" ]; then
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/APP_DEBUG\=true/APP_DEBUG\=false/g' $SCRIPT_PATH/../.example)
    (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe 's/APP_ENV\=local/APP_ENV\=production/g' $SCRIPT_PATH/../.example)
  fi
fi

################ FOR Zend Framework & Doctrine
if [ -d "$SCRIPT_PATH/../data" ]; then
  ## [ ! -d "$SCRIPT_PATH/../public/themes/webapp/data/captcha"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../public/themes/webapp/data/captcha && touch $SCRIPT_PATH/../public/themes/webapp/data/captcha/index.html
  ## [ ! -d "$SCRIPT_PATH/../public/themes/webapp/data/pdf"  ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../public/themes/webapp/data/pdf && touch $SCRIPT_PATH/../public/themes/webapp/data/pdf/index.html

  rm -rf $SCRIPT_PATH/../data/cache/*
  rm -rf $SCRIPT_PATH/../data/Doctrine*
  rm -rf $SCRIPT_PATH/../composer.lock

  [ ! -d "$SCRIPT_PATH/../data/cache" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/cache && touch $SCRIPT_PATH/../data/cache/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/cache/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/config" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/config && touch $SCRIPT_PATH/../data/config/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/config/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/tmp" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/tmp && touch $SCRIPT_PATH/../data/tmp/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/tmp/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/logs" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/logs && touch $SCRIPT_PATH/../data/logs/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/logs/.gitignore

  [ ! -d "$SCRIPT_PATH/../data/DoctrineModule" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineModule && touch $SCRIPT_PATH/../data/DoctrineModule/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/DoctrineModule/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineORMModule" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineORMModule && touch $SCRIPT_PATH/../data/DoctrineORMModule/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/DoctrineORMModule/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineORMModule/Hydrator" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineORMModule/Hydrator && touch $SCRIPT_PATH/../data/DoctrineORMModule/Hydrator/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/DoctrineORMModule/Hydrator/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineORMModule/Proxy" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineORMModule/Proxy && touch $SCRIPT_PATH/../data/DoctrineORMModule/Proxy/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/DoctrineORMModule/Proxy/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineMongoODMModule" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineMongoODMModule && touch $SCRIPT_PATH/../data/DoctrineMongoODMModule/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/DoctrineMongoODMModule/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineMongoODMModule/Hydrator" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineMongoODMModule/Hydrator && touch $SCRIPT_PATH/../data/DoctrineMongoODMModule/Hydrator/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/DoctrineMongoODMModule/Hydrator/.gitignore
  [ ! -d "$SCRIPT_PATH/../data/DoctrineMongoODMModule/Proxy" ] && mkdir -m $FDMODE -p $SCRIPT_PATH/../data/DoctrineMongoODMModule/Proxy && touch $SCRIPT_PATH/../data/DoctrineMongoODMModule/Proxy/.gitignore && echo -e "*\n"$'\r' >$SCRIPT_PATH/../data/DoctrineMongoODMModule/Proxy/.gitignore
fi

## find $SCRIPT_PATH/../ -type d -exec touch {}/index.html \;

## get last composer
if [ -f "$SCRIPT_PATH/../composer.phar" ]; then
  $PHP $PHPCOPTS $SCRIPT_PATH/../composer.phar self-update
  $PHP $PHPCOPTS $SCRIPT_PATH/../composer.phar --version
  $PHP $PHPCOPTS $SCRIPT_PATH/../composer.phar diagnose
else
  # if [ $HASCURL == 1 ]; then
  #   echo "Install with cURL\n"
  #   # (cd $SCRIPT_PATH/../ && curl -sS https://getcomposer.org/installer | $PHP) # using subshell
  #   cd $SCRIPT_PATH/../ && {
  #     curl -sS https://getcomposer.org/installer | $PHP
  #     cd -
  #   }
  # else
    echo "Install with PHP\n"
    $PHP $PHPCOPTS -r "copy('https://getcomposer.org/installer', '$SCRIPT_PATH/../composer-setup.php');"
    $PHP $PHPCOPTS $SCRIPT_PATH/../composer-setup.php --install-dir=$SCRIPT_PATH/../ --filename=composer.phar
    $PHP $PHPCOPTS -r "unlink('$SCRIPT_PATH/../composer-setup.php');"
  # fi
fi

# $PHP $PHPCOPTS composer.phar config -g https://packagist.org
$PHP $PHPCOPTS composer.phar config --global process-timeout 9000

git config --global core.compression 9
git config --global http.postBuffer 1048576000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
# git config --global --add safe.directory /storage

## install or update with composer
if [ -f "$SCRIPT_PATH/../composer.lock" ]; then
  (cd $SCRIPT_PATH/../ && COMPOSER_PROCESS_TIMEOUT=0 $PHP $PHPCOPTS composer.phar $DEVMODE update  -o -a --no-interaction) ## -vvv --ignore-platform-reqs --prefer-source --no-interaction
else
  (cd $SCRIPT_PATH/../ && COMPOSER_PROCESS_TIMEOUT=0 $PHP $PHPCOPTS composer.phar $DEVMODE install -o -a --no-interaction --no-cache) ## -vvv --ignore-platform-reqs --prefer-source --no-interaction
fi

################ FOR LARAVEL
if [ -f "$SCRIPT_PATH/../artisan" ]; then
  (
    cd $SCRIPT_PATH/../
    $PHP $PHPCOPTS artisan cms:publish:assets
  )
  (
    cd $SCRIPT_PATH/../
    $PHP $PHPCOPTS artisan cms:theme:assets:publish
  )
  (
    cd $SCRIPT_PATH/../
    $PHP $PHPCOPTS artisan config:clear
    $PHP $PHPCOPTS artisan cache:clear
    $PHP $PHPCOPTS composer.phar dumpautoload
  )
fi
################ FOR SYMFONY
if [ -f "$SCRIPT_PATH/../app/console" ]; then
  (
    cd $SCRIPT_PATH/../
    $PHP $PHPCOPTS app/console cache:clear
    $PHP $PHPCOPTS composer.phar dumpautoload
  )
fi

# Ignore Symbolic links
# (cd $SCRIPT_PATH && find $SCRIPT_PATH/../ -type l | sed -e s'/^\.\///g' >> $SCRIPT_PATH/../.gitignore)

################ FOR LARAVEL
if [ -f "$SCRIPT_PATH/../artisan" ]; then
  chmod -R $FDMODE $SCRIPT_PATH/../storage/ && chmod $FDMODE $SCRIPT_PATH/../bootstrap/cache/
  echo -e "$BLUE All paths created $NORMAL"
fi

################ FOR Zend Framework & Doctrine
if [ -d "$SCRIPT_PATH/../data" ]; then
  chmod -R $FDMODE $SCRIPT_PATH/../data/ && chmod $FDMODE $SCRIPT_PATH/../data/cache/
  echo -e "$BLUE All paths created $NORMAL"
fi
