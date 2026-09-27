#!/bin/sh
set -eu

mkdir -p /tmp/configuration
echo "Generating configuration for SFTPPlus worker ..."
cp /opt/sftpplus-initialization/server-worker.ini.init \
  /tmp/configuration/server.ini
sed -i "s#UPDATED_AT_INIT_INSTANCE_NAME#$(hostname)#g" \
  /tmp/configuration/server.ini
WORKER_PASSWORD=$(cat /opt/sftpplus-worker-credentials/worker-password)
ESCAPED_PASSWORD=$(printf '%s' "$WORKER_PASSWORD" | sed 's/[\\&#]/\\&/g')
sed -i "s#UPDATED_AT_INIT_INSTANCE_PASSWORD#${ESCAPED_PASSWORD}#g" \
  /tmp/configuration/server.ini
echo "Starting SFTPPlus worker ..."
cd /tmp
sleep 5
exec /opt/sftpplus/bin/admin-commands.sh start-in-foreground \
  --config=/tmp/configuration/server.ini
