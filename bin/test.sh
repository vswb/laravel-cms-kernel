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

# if [ -f "$SCRIPT_PATH/../dev/core/base/src/Supports/EmailHandler.php" ]; then
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/public function __construct\(\)/protected string \\\$platform_path = 'dev';\n\n\tpublic function setPlatformPath\(\\\$platform_path = 'dev')\{\\\$this\-\>platform_path = \\\$platform_path; return \\\$this;\}\n\tpublic function getPlatformPath\()\{return \\\$this\-\>platform_path;\}\n\n\tpublic function __construct\(public string \\\$platform_type = 'dev'\)/g" $SCRIPT_PATH/../dev/core/base/src/Supports/EmailHandler.php)
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/\\\$key . '.tpl'\n/\\\$key . '.tpl', \\\$this->getPlatformPath\(\)\n/g" $SCRIPT_PATH/../dev/core/base/src/Supports/EmailHandler.php)
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/get_setting_email_template_content\(\\\$type, \\\$this\-\>module, \\\$template\)/get_setting_email_template_content\(\\\$type, \\\$this\-\>module, \\\$template, \\\$this\-\>getPlatformPath\(\)\)/g" $SCRIPT_PATH/../dev/core/base/src/Supports/EmailHandler.php)
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/get_setting_email_template_content\(\\\$this\-\>type, \\\$this\-\>module, \\\$this\-\>template\)/get_setting_email_template_content\(\\\$this\-\>type, \\\$this\-\>module, \\\$this\-\>template, \\\$this\-\>getPlatformPath\(\)\)/g" $SCRIPT_PATH/../dev/core/base/src/Supports/EmailHandler.php)
# fi

# if [ -f "$SCRIPT_PATH/../dev/core/setting/helpers/helpers.php" ]; then
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/get_setting_email_template_content\(string \\\$type, string \\\$module, string \\\$templateKey\)/get_setting_email_template_content\(string \\\$type, string \\\$module, string \\\$templateKey, string \\\$platform_path = 'dev'\)/g" $SCRIPT_PATH/../dev/core/setting/helpers/helpers.php)
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/\\\$templateKey . '.tpl'\)/\\\$templateKey . '.tpl', \\\$platform_path\)/g" $SCRIPT_PATH/../dev/core/setting/helpers/helpers.php)
# fi

# ## change core_path
# if [ -f "$SCRIPT_PATH/../dev/core/base/helpers/common.php" ]; then
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/platform_path\('core'/platform_path\(\\\$core_path/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/core_path\(\?string \\\$path = null\)/core_path\(\?string \\\$path = null, string \\\$core_path = 'core'\)/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
# fi
# ## change platform_path
# if [ -f "$SCRIPT_PATH/../dev/core/base/helpers/common.php" ]; then
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/base_path\('platform'/base_path\(\\\$platform_path/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/platform_path\(\?string \\\$path = null\)/platform_path\(\?string \\\$path = null, string \\\$platform_path = 'dev'\)/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
# fi
# ## change package_path
# if [ -f "$SCRIPT_PATH/../dev/core/base/helpers/common.php" ]; then
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/platform_path\('packages'/platform_path\(\\\$package_path/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/package_path\(\?string \\\$path = null\)/package_path\(\?string \\\$path = null, string \\\$package_path = 'libs'\)/g" $SCRIPT_PATH/../dev/core/base/helpers/common.php)
# fi

if [ -f "$SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php" ]; then
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/getPath\(\?string \\\$path = null\)/getPath\(\?string \\\$path = null, \?string \\\$platform_path = \'dev\', \?string \\\$plugin_path = \'dev\/plugins\'\)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)

  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/base_path\(\'platform\/plugins\'\)/base_path\(\\\$plugin_path\)/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)
  (cd $SCRIPT_PATH/../ && LC_ALL=C perl -i -pe "s/base_path\('platform\/\'/base_path\(\\\$platform_path . '\/'/g" $SCRIPT_PATH/../dev/core/base/src/Traits/LoadAndPublishDataTrait.php)

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

# if [ -f "$SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php" ]; then
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/use Dev\\\Support\\\Repositories\\\Interfaces\\\RepositoryInterface;\nuse Illuminate\\\Database\\\Eloquent\\\Model;/use Dev\\\Support\\\Repositories\\\Interfaces\\\RepositoryInterface;\nuse Dev\\\Support\\\Services\\\Cache\\\Cache;\nuse Illuminate\\\Database\\\Eloquent\\\Model;\nuse Exception;\nuse InvalidArgumentException;/g" $SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php) # add new libs

#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/public function __construct\(protected RepositoryInterface \\\$repository\)\n    {/protected RepositoryInterface \\\$repository;\n\tprotected Cache \\\$cache;\n\n\tpublic function __construct\(RepositoryInterface \\\$repository, string \\\$cacheGroup = null, string \\\$modeGroup = null\)\n\t\{\n\t\t\\\$this->repository = \\\$repository\;\n\t\t\\\$this->cache = new Cache\(app\('cache'\), \\\$cacheGroup ?? get_class\(\\\$repository->getModel\(\)\), \[\], \\\$modeGroup\)\;/g" $SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php) # add new function

#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/public function getDataIfExistCache\(string \\\$function, array \\\$args\)\n    {/public function getDataWithCache\(string \\\$function, array \\\$args\) { try { if \(! setting\('enable_cache_data', false\)\) { return call_user_func_array\(\[\\\$this->repository, \\\$function\], \\\$args\); } \\\$cacheKey = md5\( get_class\(\\\$this\) . \\\$function . serialize\(request\(\)->input\(\)\) . serialize\(json_encode\($args\)\) );  if \(\\\$this->cache->has\(\\\$cacheKey\)\) { return \\\$this->cache->get\(\\\$cacheKey\); }  \\\$cacheData = call_user_func_array\(\[\\\$this->repository, \\\$function\], \\\$args\);  \\\$this->cache->put\(\\\$cacheKey, \\\$cacheData\);  return \\\$cacheData; } catch \(Exception | InvalidArgumentException \\\$ex\) { info(\\\$ex->getMessage\(\)\); return call_user_func_array\(\[\\\$this->repository, \\\$function\], \\\$args\); } }\n\n\tpublic function getDataIfExistCache\(string \\\$function, array \\\$args\){\n/g" $SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php) # add new libs
# fi

# if [ -f "$SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php" ]; then
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/protected array \\\$config = \[\]\n    \) {/protected array \\\$config = \[\], protected ?string \\\$modeGroup = ''\n    \) {/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)

#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/'cache_time' => 10 \* 60/'cache_time' => setting\('cache_time', 60 \* 24 \* 1\) \* 60, \/\/ 1 day/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)

#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/public static function make\(string \\\$group\): static\n    {/public function getGroup\(\){ if\(\!blank\(\\\$this->modeGroup\)\){ \\\$user_id = request\(\)->user\(\)->id; if\(\!blank\(\\\$user_id\)\){  return  \\\$this->cacheGroup . '_'. \\\$this->modeGroup. '_' .\\\$user_id.'_'; } } return \\\$this->cacheGroup; }\n\n\tpublic static function make\(string \\\$group\): static {\n/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/md5\(\\\$this->cacheGroup\)/md5\(\\\$this->getGroup\(\)\)/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)

#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/\(\\\$cacheKeys, \\\$this->cacheGroup/\(\\\$cacheKeys, \\\$this->getGroup\(\)/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)

#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/\\\$cacheKeys\[\\\$this->cacheGroup\]\[\] = \\\$key;/\\\$cacheKeys\[\\\$this->getGroup\(\)\]\[\] = \\\$key;/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)

#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/unset\(\\\$cacheKeys\[\\\$this->cacheGroup/unset\(\\\$cacheKeys\[\\\$this->getGroup\(\)/g" $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php)
# fi

# if [ -f "$SCRIPT_PATH/../dev/core/base/src/Exceptions/Handler.php" ]; then
#   rm -f $SCRIPT_PATH/../dev/core/base/src/Exceptions/Handler.php
#   cp $SCRIPT_PATH/../bin/remove-bb.overwrite/dev/core/base/src/Exceptions/Handler.php $SCRIPT_PATH/../dev/core/base/src/Exceptions/Handler.php
# fi

# if [ -f "$SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php" ]; then
#   rm -f $SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php
#   cp $SCRIPT_PATH/../bin/remove-bb.overwrite/dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php $SCRIPT_PATH/../dev/core/support/src/Repositories/Caches/CacheAbstractDecorator.php
# fi

# if [ -f "$SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php" ]; then
#   rm -f $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php
#   cp $SCRIPT_PATH/../bin/remove-bb.overwrite/dev/core/support/src/Services/Cache/Cache.php $SCRIPT_PATH/../dev/core/support/src/Services/Cache/Cache.php
# fi


# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '.env.example' -print0 | xargs -0 perl -i -pe 's/docs.botble.com/docs.fsofts.com/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name 'package-lock.json' -print0 | xargs -0 perl -i -pe 's/\@botble/\@dev/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name 'package-lock.json' -print0 | xargs -0 perl -i -pe 's/botble/dev/g')

# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/core/ -type f -name '*.blade.php' -print0 | xargs -0 perl -i -pe 's/settings.license.verify.index/kernel.api.v1.license.verify/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/core/ -type f -name '*.blade.php' -print0 | xargs -0 perl -i -pe 's/settings.license.verify/kernel.api.v1.license.verify/g')

#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/'license.check'/'kernel.api.v1.license.check'/g" $SCRIPT_PATH/../dev/core/base/resources/views/components/layouts/base.blade.php)

# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\@gmail.com/contact\@fsofts.com/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"friendsofbotble\/sms-gateways/\"dev\/sms-gateways/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/\"friendsofbotble\/sms-gateway/\"dev\/sms-gateway/g')

# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/comment/dev\/comment/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/sms-gateways/dev\/sms-gateways/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/sms-gateway/dev\/sms-gateway/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/pwa/dev\/pwa/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/google-maps-geocoding/dev\/google-maps-geocoding/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/comment/dev\/comment/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/barcode-generator/dev\/barcode-generator/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/ticksify/dev\/ticksify/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/geo-data-detector/dev\/geo-data-detector/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/request-quote/dev\/request-quote/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/vietnam-bank-qr/dev\/vietnam-bank-qr/g')

# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/comment/dev\/comment/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/sms-gateways/dev\/sms-gateways/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/sms-gateway/dev\/sms-gateway/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/pwa/dev\/pwa/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/google-maps-geocoding/dev\/google-maps-geocoding/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/comment/dev\/comment/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/barcode-generator/dev\/barcode-generator/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/ticksify/dev\/ticksify/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/geo-data-detector/dev\/geo-data-detector/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/request-quote/dev\/request-quote/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/friendsofbotble\/vietnam-bank-qr/dev\/vietnam-bank-qr/g')

# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/github.com\/FriendsOfBotble/github.com\/vswb/g')


# if [ -f "$SCRIPT_PATH/../dev/plugins/request-quote/resources/email-templates/admin-notification.tpl" ]; then
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/plugins\/fob-/plugins\//g" $SCRIPT_PATH/../dev/plugins/request-quote/resources/email-templates/admin-notification.tpl)
# fi
# if [ -f "$SCRIPT_PATH/../dev/plugins/request-quote/resources/email-templates/customer-confirmation.tpl" ]; then
#   (cd $SCRIPT_PATH/../ && LC_ALL=C perl -0777 -i -pe "s/plugins\/fob-/plugins\//g" $SCRIPT_PATH/../dev/plugins/request-quote/resources/email-templates/customer-confirmation.tpl)
# fi

## TOC PLUGIN
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../ -type f -name '*.md' -print0 | xargs -0 perl -i -pe 's/github\.com\/nivianh/github\.com\/vswb/g')

# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Plugin\\\\ToC\\\\/Dev\\\\ToC\\\\/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Plugin\\ToC\\/Dev\\ToC\\/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/Plugin\\ToC/Dev\\ToC/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.php' -print0 | xargs -0 perl -i -pe 's/github\.com\/nivianh\//github\.com\/vswb\//g')

# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Plugin\\\\ToC\\\\/Dev\\\\ToC\\\\/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/github\.com\/nivianh\//github\.com\/vswb\//g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/github\.com\/nivianh/github\.com\/vswb/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/nivianh\/toc/platform\/toc/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name '*.json' -print0 | xargs -0 perl -i -pe 's/Anh Ngo/Laravel Technologies/g')
# ## END TOC PLUGIN


## REPLACE AUTH / MAIN CONTACT ON PLUGIN
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/\"author\"\: \"Laravel Technologies\"/\"author\"\: \"Laravel Technologies\"/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/\"author\"\: \"Laravel CMS\"/\"author\"\: \"Laravel Technologies\"/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/\"url\"\: \"https\:\/\/fsofts\.com\"/\"url\"\: \"mailto\:toan\@visualweber\.com\"/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/\"url\"\: \"https\:\/\/github\.com\/vswb"/\"url\"\: \"mailto\:toan\@visualweber\.com\"/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/\"url\"\: \"https\:\/\/cms\.fsofts\.com\"/\"url\"\: \"mailto\:toan\@visualweber\.com\"/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/Developer Team/Laravel Technologies/g')
# (cd $SCRIPT_PATH/../ && LC_ALL=C find $SCRIPT_PATH/../dev/ -type f -name 'plugin.json' -print0 | xargs -0 perl -i -pe 's/Bao Boi/Laravel Technologies/g')
## END REPLACE AUTH / MAIN CONTACT ON PLUGIN

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