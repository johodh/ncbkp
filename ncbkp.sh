#!/bin/bash
############################################################
# creates a backup of nextcloud data, config and database  #
# sends it to a safe place using rsync over ssh            #
#                                                          #
# this script should run as http/www-data user as they own #
# relevant paths. also it's required by nextcloud occ      #   
############################################################

# change these paths to suit your needs
NC_WEBROOT=""
NC_DATA=""
NC_CONFIG_PATH=""

OCC="${NC_WEBROOT}/occ"
SCRIPTLOG="/tmp/ncbkp.log"
RSYNCLOG="/tmp/ncbkp.rsync.log"
DB_BKP_PATH="/tmp/nextcloud-db-`date +%Y-%m-%d_%H-%M`.bkp"

# rsync/ssh
RSYNC_TARGET="user@host:~"
KEYFILE="/path/to/ssh_key"

timestamp=`date +[%Y-%m-%d+%H:%M:%S] | sed 's/+/ /g'`

function log
{
	if test $1 = "e"; then event="[error]:"
	elif test $1 = "s"; then event="[success]:"
	else event="";
	fi
	echo $timestamp $event $2 >> $SCRIPTLOG
}

function failcheck
{
if [ $1 != 0 ]; then 
	log e "$3 of $2 failed. details in $3 log."
else log s "$3 of $2 successful. details in $3 log."
fi
}

# test paths and dependencies
if [ ! -d $NC_WEBROOT ]; then log e "webroot path $NC_WEBROOT doesn't exist" && break=1; fi
if [ ! -d $NC_DATA ]; then log e "data path $NC_DATA doesn't exist" && break=1; fi
if [ ! -d $NC_CONFIG_PATH ]; then log e "config path $NC_CONFIG_PATH doesn't exist" && break=1; fi
if [ ! -f ${OCC} ]; then log e "${OCC} doesn't exist" && break=1; fi

which rsync 2> /dev/null
if [ $? != 0 ]; then log e "rsync not found" && break=1; fi

if [ ! -z $break ]; then exit 0; fi

# fetch database type and credentials
# TODO: right now only supports mysql

NC_CONFIG=${NC_WEBROOT}/config/config.php
DB_TYPE=$(cat $NC_CONFIG | grep dbtype | awk '{print $3}' | tr -d "',")
DB_HOST=$(cat $NC_CONFIG | grep dbhost | awk '{print $3}' | tr -d "',")
DB_NAME=$(cat $NC_CONFIG | grep dbname | awk '{print $3}' | tr -d "',")
DB_USER=$(cat $NC_CONFIG | grep dbuser | awk '{print $3}' | tr -d "',")
DB_PASS=$(cat $NC_CONFIG | grep dbpass | awk '{print $3}' | tr -d "',")

if test $DB_TYPE != "mysql"; then log e "could not determine database type. database not backed up." && db_backup=0; fi

# enable nextcloud maintenance mode
enabled=$(${OCC} maintenance:mode --on | grep -o -e enabled)
if [ -z $enabled ]; then 
	log e "maintenance mode not enabled" && exit 0
else log s "maintenance mode enabled"; fi
sleep 5

# send nextcloud data directory to target with rsync
rsync -AaPxv --delete --log-file=$RSYNCLOG -e "ssh -i $KEYFILE" $NC_DATA $RSYNC_TARGET 
failcheck $? $NC_DATA "rsync"

# send nextcloud config directory to target with rsync
rsync -AaPxv --delete --log-file=$RSYNCLOG -e "ssh -i $KEYFILE" $NC_CONFIG_PATH $RSYNC_TARGET 
failcheck $? $NC_CONFIG_PATH "rsync"

# backup database to file
mysqldump --single-transaction -h ${DB_HOST} -u ${DB_USER} -p"${DB_PASS}" $DB_NAME > $DB_BKP_PATH
failcheck $? $DB_NAME "mysqldump"

# send database with rsync
rsync -AaPxv --log-file=$RSYNCLOG -e "ssh -i $KEYFILE" $DB_BKP_PATH $RSYNC_TARGET
failcheck $? database "rsync"

timestamp=`date +[%Y-%m-%d+%H:%M:%S] | sed 's/+/ /g'`

# disable nextcloud maintenance mode 
disabled=$(${OCC} maintenance:mode --off | grep -o -e disabled)
if [ -z $disabled ]; then log e "maintenance mode might not have been disabled after backup"
else log s "maintenance mode disabled after backup"; fi


