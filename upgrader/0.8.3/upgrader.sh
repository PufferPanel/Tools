#!/bin/bash
# Upgrades from 0.8.2 to 0.8.3

red=$(tput setf 4)
directory="/srv/PufferPanel/"
mysqlhost="localhost"

function validateCommand() {
    if [ $? -ne 0 ]; then
        echo -e "${red}An error occured while installing, halting"
        exit 1
    fi
}

while getopts ":u:p:h:d:" opt; do
    case "$opt" in
    u)
        mysqluser=$OPTARG
        ;;
    p)
        mysqlpass=$OPTARG
        ;;
    h)
        mysqlhost=$OPTARG
        ;;
    d)
        directory=$OPTARG
        ;;
    *)
        echo "Usage: ./upgrader.sh -u <user> -p <password> [-d <directory>]"
        echo "-u        | Root MySQL User, or MySQL user with elevated permissions for modifying tables."
        echo "-p        | Password for the MySQL User Account"
        echo "-d        | Directory which PufferPanel is installed in. Defaults to /srv/PufferPanel/"
        exit 0
        ;;
    esac
done

temp=$(mktemp -d)
validateCommand

echo "Performing actions inside temporary directory (${temp})"
cd temp
validateCommand

echo "
USE pufferpanel;

-- Update our Tables
ALTER TABLE servers DROP COLUMN pack;
ALTER TABLE servers ADD block_io smallint(6) unsigned DEFAULT NULL AFTER cpu_limit;
ALTER TABLE plugins ADD default_startup text AFTER description;

-- Update Settings for New Email Methods
UPDATE acp_settings SET setting_ref = 'transport_email' WHERE setting_ref = 'sendmail_email';
UPDATE acp_settings SET setting_ref = 'transport_method' WHERE setting_ref = 'sendmail_method';

-- Clean Up
DELETE FROM acp_settings WHERE setting_ref = 'mandrill_api_key';
DELETE FROM acp_settings WHERE setting_ref = 'postmark_api_key';
DELETE FROM acp_settings WHERE setting_ref = 'sendgrid_api_key';
DELETE FROM acp_settings WHERE setting_ref = 'mailgun_api_key';
DELETE FROM acp_settings WHERE setting_ref = 'force_online';
DELETE FROM acp_settings WHERE setting_ref = 'use_api';
" > commands.sql
validateCommand

echo "Updating MySQL Records..."
mysql --host=${mysqlhost} --user=${mysqluser} --password=${mysqlpass} < commands.sql
validateCommand

echo -n "If you are using an email method OTHER THAN PHP please enter your API Token: "
read sendmailToken
validateCommand

mysql --host=${mysqlhost} --user=${mysqluser} --password=${mysqlpass} -e "UPDATE acp_settings SET setting_val = '${sendmailToken}' WHERE setting_ref = 'transport_token'" pufferpanel
validateCommand

cd ${directory}
validateCommand

git fetch
validateCommand

git checkout tags/0.8.3
validateCommand

php composer.phar self-update
validateCommand

php composer.phar update
validateCommand

echo -e "Upgrade Completed..."
