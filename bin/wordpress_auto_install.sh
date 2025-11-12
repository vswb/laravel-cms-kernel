#!/bin/bash

## scripts setup danh sách các dự án wordpress demo 01.08.2021

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

if hash server-tools 2>/dev/null; then
    SCRIPT_PATH="$(dirname "$(readlink -f `which server-tools`)")" ## eg: ln -s /opt/server-tools/main.sh /usr/local/bin/server-tools && server-tools
else
    SCRIPT_PATH="/opt/server-tools"
fi

# MYSQL INFORMATION
ASSIGNED_DB_USER='dev'
ASSIGNED_DB_PASSWD='1YhTZsHJSfYFyXA9'
ASSIGNED_DB_HOST='%'

MASTER_DB_USER='backup'
MASTER_DB_PASSWD='pPX1UfomePafqfTh'
MASTER_DB_HOST="127.0.0.1"
VERSION="1.0" ## Source deploy version

# GENERAL 
HOME_USER="demo"
DB_PREFIX="${HOME_USER}_wp_"

NGINX_CONF_FILE="$(awk -F= -v RS=' ' '/conf-path/ {print $2}' <<< $(nginx -V 2>&1))"
NGINX_CONF_DIR="${NGINX_CONF_FILE%/*}"
NGINX_SITES_AVAILABLE="$NGINX_CONF_DIR/sites-available"
NGINX_SITES_ENABLED="$NGINX_CONF_DIR/sites-enabled"
NGINX_USER_SITES_ENABLED="/home/$HOME_USER/nginx/vhost"
NGINX_USER_CONFIG="/home/$HOME_USER/nginx/vhost"

MAIN_DOMAIN="wordpress.demo.fsofts.com"

WEB_DIR="/home/$HOME_USER/htdocs/001_demo_wordpress"
CURRENT_DIR=$SCRIPT_PATH
TEMPLATE_DIR="$SCRIPT_PATH/template"

echo -e "$VERT--> Included : $ROUGE $SCRIPT_PATH/util.sh $VERT $NORMAL"
source "$SCRIPT_PATH/util.sh"
echo -e "$VERT--> Included : $ROUGE $SCRIPT_PATH/function.sh $VERT $NORMAL"
source "$SCRIPT_PATH/function.sh"
echo -e "$VERT--> Included : $ROUGE $SCRIPT_PATH/nginx_modsite.sh $VERT $NORMAL"
source "$SCRIPT_PATH/nginx_modsite.sh"


## BEGIN
SOURCE_PATH="/home/$HOME_USER/htdocs/wordpress_autoinstall/sources"
SQL_SCRIPT_PATH="/home/$HOME_USER/htdocs/wordpress_autoinstall/sql_scripts"

for source in "$SOURCE_PATH"/*.zip
do
	SOURCE_FILENAME=$(basename $source)
	PROJECT_NAME=$(echo $SOURCE_FILENAME | rev | cut -f 2- -d '.' | rev)
	SITE_DIR=$PROJECT_NAME
	DOCUMENT_ROOT="$WEB_DIR/$PROJECT_NAME";
	
	DOMAIN_NAME="$MAIN_DOMAIN/$PROJECT_NAME"
	DOMAIN_NAME_SHORT="$PROJECT_NAME"

	# [ ! -f "$SOURCE_PATH/$PROJECT_NAME.autorun" ] && continue
	# [ -d "$WEB_DIR/$PROJECT_NAME" ] && continue # skip it
	# [ ! -f "$SQL_SCRIPT_PATH/$PROJECT_NAME.sql" ] && continue
	if [ ! -f "$SQL_SCRIPT_PATH/$PROJECT_NAME.sql" ]
	then
		continue # skip it
	fi
	if [ ! -f "$SOURCE_PATH/$PROJECT_NAME.autorun" ]
	then
		continue # skip it
	fi
	(cd $SOURCE_PATH && $RM -f $SOURCE_PATH/$PROJECT_NAME.autorun) 
	(cd $WEB_DIR && $RM -Rf $WEB_DIR/$PROJECT_NAME)

	## step 1
	$MKDIR -p $DOCUMENT_ROOT;
	yes | cp -r $source $DOCUMENT_ROOT;

	echo $SOURCE_FILENAME;
	echo $PROJECT_NAME;
	echo $DOCUMENT_ROOT;
	echo -e $source;
	echo -e "\n";

	## step 2
	# DBNAME_SHORT=$(echo $PROJECT_NAME | $SED -e 's/\./_/g' -e 's/-/_/g' -e 's/ /_/g')
	# DBNAME="$DB_PREFIX${DBNAME_SHORT,,}"
	# DBUSER="userdb.$HOME_USER.${DBNAME_SHORT,,}"
	# DBPWD=$(genpasswd 16)

	DBNAME_SHORT=$(echo $PROJECT_NAME | $SED -e 's/\./_/g' -e 's/-/_/g' -e 's/ /_/g')
	DBNAME="$DB_PREFIX${DBNAME_SHORT,,}"
	DBUSER="demo"
	DBPWD="Abc@1234"

	_arrow "Mysql User is: $ROUGE $DBUSER "
	_arrow "Mysql password is: $ROUGE $DBPWD "

	# drop
	_arrow "Creating database $ROUGE $DBNAME $VERT ... "
	_arrow "DROP DATABASE IF EXISTS $DBNAME"
	$MYSQL -u $MASTER_DB_USER -h $MASTER_DB_HOST -p$MASTER_DB_PASSWD -Bse "DROP DATABASE IF EXISTS \`$DBNAME\`;"

	# create new database
	_arrow "Creating database $ROUGE $DBNAME $VERT ... "
	_arrow "CREATE DATABASE IF NOT EXISTS $DBNAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
	$MYSQL -u $MASTER_DB_USER -h $MASTER_DB_HOST -p$MASTER_DB_PASSWD -Bse "CREATE DATABASE IF NOT EXISTS \`$DBNAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

	# grant for new Mysql User
	_arrow "Grant for new Mysql User $ROUGE $DBUSER@$ASSIGNED_DB_HOST $VERT ... "
	$MYSQL -u $MASTER_DB_USER -h $MASTER_DB_HOST -p$MASTER_DB_PASSWD -Bse "GRANT ALL PRIVILEGES ON \`$DBNAME\`.* TO '$DBUSER'@'$ASSIGNED_DB_HOST' identified by '$DBPWD';FLUSH PRIVILEGES;"

	# grant for default Mysql User
	_arrow "Grant for default Mysql User $ROUGE $ASSIGNED_DB_USER@$ASSIGNED_DB_HOST $VERT ... "
	$MYSQL -u $MASTER_DB_USER -h $MASTER_DB_HOST -p$MASTER_DB_PASSWD -Bse "GRANT ALL PRIVILEGES ON \`$DBNAME\`.* TO '$ASSIGNED_DB_USER'@'$ASSIGNED_DB_HOST';FLUSH PRIVILEGES;"

	$MYSQL --init-command="SET SESSION FOREIGN_KEY_CHECKS=0;" -u $MASTER_DB_USER -h $MASTER_DB_HOST -p$MASTER_DB_PASSWD $DBNAME < $SQL_SCRIPT_PATH/$PROJECT_NAME.sql;
	# $MYSQL -u $MASTER_DB_USER -h $MASTER_DB_HOST -p$MASTER_DB_PASSWD $DBNAME -e "UPDATE bz_users SET  bz_users.user_pass = '\$P\$BmOsOaD2kzFxQ38jP\/T2g567HD02TT1' WHERE bz_users.ID = 1;";
	# $MYSQL -u $MASTER_DB_USER -h $MASTER_DB_HOST -p$MASTER_DB_PASSWD $DBNAME -e "UPDATE bz_users SET  bz_users.user_email = 'sysadmin@fsofts.com' WHERE bz_users.ID = 1;";
	# $MYSQL -u $MASTER_DB_USER -h $MASTER_DB_HOST -p$MASTER_DB_PASSWD $DBNAME -e "UPDATE bz_users SET  bz_users.user_login = 'sysadmin@fsofts.com' WHERE bz_users.ID = 1;";

	if [ $? != "0" ]
	then
	  _arrow "Database create $ROUGE failed $VERT $ROUGE $DBNAME "
	  _safeExit
	else
	  _arrow "Database created $ROUGE $DBNAME "
	fi

	## step 3
	_warning "Install wordpress into $DOCUMENT_ROOT"
	_warning "Current PATH $(pwd)"
	pwd -P
	# init wp-config.php
	echo -e "$CP $TEMPLATE_DIR/wp-config.php.wordpress.autoinstall.template $DOCUMENT_ROOT/wp-config.php"
	$CP $TEMPLATE_DIR/wp-config.php.wordpress.autoinstall.template $DOCUMENT_ROOT/wp-config.php
	# replace information
	$SED -i "s/{DBPWD}/$DBPWD/g" $DOCUMENT_ROOT/wp-config.php
	$SED -i "s/{DBUSER}/$DBUSER/g" $DOCUMENT_ROOT/wp-config.php
	$SED -i "s/{DBNAME}/$DBNAME/g" $DOCUMENT_ROOT/wp-config.php
	# $SED -i "s/{DB_PREFIX}/$PROJECT_NAME/g" $DOCUMENT_ROOT/wp-config.php
	$SED -i "s/{DB_PREFIX}/wp/g" $DOCUMENT_ROOT/wp-config.php
	$SED -i "s/{DOMAIN_NAME}/$DOMAIN_NAME/g" $DOCUMENT_ROOT/wp-config.php
	$SED -i "s/{DOMAIN_NAME_SHORT}/$DOMAIN_NAME_SHORT/g" $DOCUMENT_ROOT/wp-config.php

	# Grab our Salt Keys
	echo -e "Grab our Salt Keys: "
	$PERL -i -pe'
	BEGIN {
	  @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
	  push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
	  sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
	}
	s/put your unique phrase here/salt()/ge
	' $DOCUMENT_ROOT/wp-config.php
	##
	(cd $DOCUMENT_ROOT && $RM -Rf $DOCUMENT_ROOT/wp-config.sample.php)
	(cd $DOCUMENT_ROOT && $CP $DOCUMENT_ROOT/wp-config.php $DOCUMENT_ROOT/wp-config.security.php)

	## correct project information again then push to git repository
	initParams && checkResult

	## step 4
	# init source code, database
	_arrow "OK ! You are installing your project based on wordpress "
	# (cd $DOCUMENT_ROOT && $CURL -v -O https://wordpress.org/latest.tar.gz && $TAR -zxvf latest.tar.gz && $MV $DOCUMENT_ROOT/wordpress/* $DOCUMENT_ROOT/)
	(cd $DOCUMENT_ROOT && $TAR -zxvf "$WEB_DIR/latest.tar.gz" -C $DOCUMENT_ROOT/ && $MV $DOCUMENT_ROOT/wordpress/* $DOCUMENT_ROOT/)
	## (cd $DOCUMENT_ROOT && $CLEAR)

	## removing odd datas
  	(cd $DOCUMENT_ROOT && $MV $DOCUMENT_ROOT/wp-content $DOCUMENT_ROOT/apps.origin)
  	(cd $DOCUMENT_ROOT && $MKDIR -p $DOCUMENT_ROOT/apps)	
	(cd $DOCUMENT_ROOT && $UNZIP -o $DOCUMENT_ROOT/$SOURCE_FILENAME -d $DOCUMENT_ROOT/apps)


	(cd $DOCUMENT_ROOT && $RM -Rf $DOCUMENT_ROOT/wordpress)
	(cd $DOCUMENT_ROOT && $RM -Rf $DOCUMENT_ROOT/apps/themes/twentysixteen)
	(cd $DOCUMENT_ROOT && $RM -Rf $DOCUMENT_ROOT/apps/themes/twentyseventeen)
	(cd $DOCUMENT_ROOT && $RM -Rf $DOCUMENT_ROOT/apps/themes/twentyfifteen)
	(cd $DOCUMENT_ROOT && $RM -Rf $DOCUMENT_ROOT/apps/themes/twentytwentyone)
	(cd $DOCUMENT_ROOT && $RM -f $DOCUMENT_ROOT/latest.tar.gz)
	(cd $DOCUMENT_ROOT && $RM -Rf $DOCUMENT_ROOT/apps.origin)
	(cd $DOCUMENT_ROOT && $RM -f $DOCUMENT_ROOT/$PROJECT_NAME.zip)
	(cd $DOCUMENT_ROOT && ls -al)

	##
	(cd $DOCUMENT_ROOT && $MKDIR $DOCUMENT_ROOT/apps/uploads && $CHMOD -R 0777 $DOCUMENT_ROOT/apps/uploads)
	## (cd $DOCUMENT_ROOT && $CP $TEMPLATE_DIR/easy-wp-smtp.zip $DOCUMENT_ROOT/apps/plugins/)
	## (cd $DOCUMENT_ROOT/apps/plugins/ && $UNZIP easy-wp-smtp.zip && cd $DOCUMENT_ROOT)
	## (cd $DOCUMENT_ROOT && $RM -f $DOCUMENT_ROOT/apps/plugins/easy-wp-smtp.zip)
	## (cd $DOCUMENT_ROOT && $CLEAR)

	# download the WordPress core files
	## $WP core download
	## (cd $DOCUMENT_ROOT && $CHMOD +x $DOCUMENT_ROOT/wp-cli.phar)
	# (cd $DOCUMENT_ROOT && $WP core install --path="$DOCUMENT_ROOT" --allow-root --url="http://$DOMAIN_NAME" --title="$DOMAIN_NAME" --admin_user="sysadmin@fsofts.com" --admin_password="Viweb@@1234" --admin_email="sysadmin@fsofts.com")
	# set pretty urls
	# (cd $DOCUMENT_ROOT && $WP rewrite structure '/%postname%/' --path="$DOCUMENT_ROOT" --hard --allow-root)
	# (cd $DOCUMENT_ROOT && $WP rewrite flush --path="$DOCUMENT_ROOT" --hard --allow-root)
	# delete akismet and hello dolly
	# (cd $DOCUMENT_ROOT && $WP plugin delete akismet --allow-root --path="$DOCUMENT_ROOT")
	# (cd $DOCUMENT_ROOT && $WP plugin delete hello --allow-root --path="$DOCUMENT_ROOT")
	# (cd $DOCUMENT_ROOT && $WP plugin install easy-wp-smtp --activate --allow-root --path="$DOCUMENT_ROOT")
	# (cd $DOCUMENT_ROOT && $WP plugin install wp-email-smtp --activate --allow-root --path="$DOCUMENT_ROOT")
	## (cd $DOCUMENT_ROOT && $WP plugin install search-replace --activate --allow-root --path="$DOCUMENT_ROOT")
	##(cd $DOCUMENT_ROOT && $WP plugin install types --activate --allow-root --path="$DOCUMENT_ROOT")
	# (cd $DOCUMENT_ROOT && $WP transient delete --all --allow-root --path="$DOCUMENT_ROOT")
	# (cd $DOCUMENT_ROOT && $WP theme install $SCRIPT_PATH/template/comingsoon.zip --activate --allow-root --path="$DOCUMENT_ROOT")

	(cd $DOCUMENT_ROOT && ls -al)
	(cd $DOCUMENT_ROOT && $CHOWN -R $HOME_USER:$HOME_USER $DOCUMENT_ROOT)

	## step 5
	USER_VHOST_FILE="$NGINX_USER_CONFIG/$DOMAIN_NAME_SHORT.wordpress"

	# Now we need to copy the virtual host template
	echo -e "$CP $TEMPLATE_DIR/virtual_host.wordpress.autoinstall.template $USER_VHOST_FILE"
	yes | $CP $TEMPLATE_DIR/virtual_host.wordpress.autoinstall.template $USER_VHOST_FILE
	$SED -i "s/{DOMAIN_NAME_SHORT}/$DOMAIN_NAME_SHORT/g" $USER_VHOST_FILE

	(cd $NGINX_USER_CONFIG && ls -al)
	(cd $NGINX_USER_CONFIG && $CHOWN -R $HOME_USER:$HOME_USER $NGINX_USER_CONFIG)

	# _arrow "OK ! Installation is complete. Your username/password is listed below:"
	# echo -e "$ORANGE-----> WP Username: $ROUGE sysadmin@fsofts.com"
	# echo -e "$ORANGE-----> WP Password: $ROUGE Viweb@@1234"
done