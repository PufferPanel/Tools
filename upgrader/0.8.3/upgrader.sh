#!/bin/bash
# Upgrades from 0.8.2 to 0.8.3

red="\e[31m"
normal="\e[0m"
directory="/srv/PufferPanel/"
mysqlhost="localhost"

function validateCommand() {
    if [ $? -ne 0 ]; then
        echo -e "${red}An error occured while upgrading, halting${normal}"
        exit 1
    fi
}

while getopts ":h:" opt; do
    case "$opt" in
    h)
        echo "Usage: ./upgrader.sh"
        exit 0
        ;;
    esac
done

echo -e "Welcome to the PufferPanel Upgrader. Please provide some information below so we can continue..."

echo -n "PufferPanel Directory [${directory}]: "
read directory
if [ -n "${directory}" ]; then
    directory=${directory}
fi

echo -n "MySQL Host [${mysqlhost}]: "
read mysqlhost
if [ -n "${mysqlhost}" ]; then
    mysqlhost=${mysqlhost}
fi

echo -n "MySQL User: "
read mysqluser

notValid=true
while ${notValid}; do
    echo -n "MySQL Password: "
    read -s mysqlpass
    if mysql -h ${mysqlhost} -u ${mysqluser} -p${mysqlpass} -e "exit"; then
        notValid=false
    else
        echo -e "${red}Database connection could not be established${normal}"
    fi
done;

echo -n "If you are using an email method OTHER THAN PHP please enter your API Token: "
read sendmailToken
validateCommand

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

-- Update Plugins
UPDATE plugins SET default_startup = '-Xms\${memory}M -server -jar \${jar}' WHERE slug = 'minecraft';
UPDATE plugins SET default_startup = '-Xms\${memory}M -server -jar \${jar}' WHERE slug = 'minecraft-pre';
UPDATE plugins SET default_startup = '-game \${game} -console +map \${map} -maxplayers \${players} -norestart' WHERE slug = 'srcds';
UPDATE plugins SET default_startup = '-Xms\${memory}M -server -jar \${jar}' WHERE slug = 'bungeecord';

-- Add PocketMine-MP
INSERT INTO plugins VALUES (NULL, 'd4bbcd72-a220-427a-a361-be2bfd944f1e', 'pocketmine', 'PocketMine-MP', 'PocketMine-MP is a server software for Minecraft PE (Pocket Edition). It has a Plugin API that enables a developer to extend it and add new features, or change default ones.', '--disable-ansi --no-wizard', '{\"build_params\":{\"name\":\"build_params\",\"description\":\"Build parameters used for the server. Use \'-v <VERSION>\' where version can be stable, beta, or development.\",\"required\":false,\"editable\":false,\"default\":\"-v stable\"}}');

-- Update Settings for New Email Methods
UPDATE acp_settings SET setting_ref = 'transport_email' WHERE setting_ref = 'sendmail_email';
UPDATE acp_settings SET setting_ref = 'transport_method' WHERE setting_ref = 'sendmail_method';
INSERT INTO acp_settings VALUES (NULL, 'transport_token', '${sendmailToken}');

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
exit 0
