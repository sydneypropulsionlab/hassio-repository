#!/usr/bin/env bash

# bashio::log.info "Starting Taiga migrations."
# export TAIGA_SECRET_KEY=$(bashio::config 'taiga_secret_key')
# echo bashio::addon.config $(bashio::addon.config)


STATIC_DIR=/home/taiga/taiga-back/static
# Setup data dirs
if ! [[ -L $STATIC_DIR ]] # if it is already a symlink take no action
then
  rm -r $STATIC_DIR
  mkdir /data/taiga-static
  ln -s /data/taiga-static $STATIC_DIR
  chown taiga /data/taiga-static
fi
MEDIA_DIR=/home/taiga/taiga-back/media
# Setup data dirs
if ! [[ -L $MEDIA_DIR ]]
then
  rm -r $MEDIA_DIR
  mkdir /data/taiga-media
  ln -s /data/taiga-media $MEDIA_DIR
  chown taiga /data/taiga-media
fi

export TAIGA_SECRET_KEY=$(cat /data/options.json | jq -r .taiga_secret_key) 
export RABBITMQ_DEFAULT_PASS=$(cat /data/options.json | jq -r .rabbitmq_password) 
export POSTGRES_PASSWORD=$(cat /data/options.json | jq -r .postgres_password) 
# Add-ons from the same repository share our "<repository hash>-" hostname
# prefix (e.g. 3243f943-taiga -> 3243f943-taiga-postgres), which differs per fork.
# "auto" (or the old upstream default) means use the sibling add-on.
ADDON_PREFIX=${HOSTNAME%-taiga}
addon_host() {
  case "$1" in
    ""|null|auto|9547a9e0-taiga-postgres|9547a9e0-rabbitmq) echo "$ADDON_PREFIX-$2" ;;
    *) echo "$1" ;;
  esac
}
export POSTGRES_HOST=$(addon_host "$(jq -r .postgres_advanced_options.host /data/options.json)" taiga-postgres)
export RABBITMQ_HOST=$(addon_host "$(jq -r .rabbitmq_advanced_options.host /data/options.json)" rabbitmq)
echo "Using postgres at $POSTGRES_HOST and rabbitmq at $RABBITMQ_HOST"
export POSTGRES_USER=$(cat /data/options.json | jq -r .postgres_advanced_options.user) 
export POSTGRES_DB=$(cat /data/options.json | jq -r .postgres_advanced_options.database) 
export RABBITMQ_VHOST=$(cat /data/options.json | jq -r .rabbitmq_advanced_options.virtual_host) 
export MINUTES_BETWEEN_BACKUPS=$(cat /data/options.json | jq -r .minutes_between_backups) 
# Outgoing email. With no SMTP host, emails are written to the log instead.
export EMAIL_HOST=$(jq -r '.smtp.host // empty' /data/options.json)
export EMAIL_PORT=$(jq -r '.smtp.port // 587' /data/options.json)
export EMAIL_SECURITY=$(jq -r '.smtp.security // "starttls"' /data/options.json)
export EMAIL_HOST_USER=$(jq -r '.smtp.username // empty' /data/options.json)
export EMAIL_HOST_PASSWORD=$(jq -r '.smtp.password // empty' /data/options.json)
export EMAIL_FROM=$(jq -r '.smtp.from_email // empty' /data/options.json)
if [[ -n $EMAIL_HOST ]]; then
  echo "Sending email via $EMAIL_HOST:$EMAIL_PORT ($EMAIL_SECURITY)"
else
  echo "No SMTP host configured: emails will be printed to the log, not sent"
fi

SLUG=$(echo $HOSTNAME | sed -e 's/-/_/g')
ADDON_INFO=$(curl  -H "Authorization: Bearer $SUPERVISOR_TOKEN" supervisor/addons/$SLUG/info)
export INGRESS_ENTRY=$(echo $ADDON_INFO | jq -r '.data.ingress_entry')

# The ingress and direct-port nginx servers each rewrite this placeholder to
# their own base path when serving the page
sed -i 's,base href="/",base href="/ingress_path_placeholder/",' /home/taiga/taiga-front-dist/dist/index.html
echo "set \$taiga_path \"$INGRESS_ENTRY\";" > /etc/nginx/taiga-ingress-path.conf

# ENVIRONMENT="INGRESS_ENTRY='$INGRESS_ENTRY' TAIGA_SECRET_KEY=$TAIGA_SECRET_KEY RABBITMQ_DEFAULT_PASS='$RABBITMQ_DEFAULT_PASS'"
VARIABLES="TAIGA_SECRET_KEY,INGRESS_ENTRY,RABBITMQ_DEFAULT_PASS,RABBITMQ_HOST,POSTGRES_PASSWORD,POSTGRES_HOST,POSTGRES_USER,POSTGRES_DB,RABBITMQ_VHOST,MINUTES_BETWEEN_BACKUPS,EMAIL_HOST,EMAIL_PORT,EMAIL_SECURITY,EMAIL_HOST_USER,EMAIL_HOST_PASSWORD,EMAIL_FROM"
# Carry out db migrations
su -w $VARIABLES  - taiga -c "bash -l /migrate.sh"

# Start the proxy server
nginx

echo "Test log message!" >> /home/taiga/logs/nginx.access.log
echo "Tailing logs..."

# print proxy errors to stdout so they appear in the logs in home assistant
# tail -f  /home/taiga/logs/nginx.access.log |  sed -e 's/^/nginx:: /' &
tail -f /home/taiga/logs/nginx.error.log | sed -e 's/^/nginx:: /' &
# tail -f  /var/log/nginx/access.log |  sed -e 's/^/nginx.root:: /' &
tail -f /var/log/nginx/error.log | sed -e 's/^/nginx.root:: /' &

# Start backup script
mkdir -p /share/$HOSTNAME
chown taiga /share/$HOSTNAME
su -w $VARIABLES - taiga -c "bash -l /backup.sh" &

# Launch Taiga
su -w $VARIABLES - taiga -c "bash -l /run.sh"

wait

