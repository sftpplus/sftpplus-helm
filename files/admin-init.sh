#!/bin/sh
set -eu

mkdir -p "$SFTPPLUS_CONFIGURATION"
cd "$SFTPPLUS_CONFIGURATION/.."

if [ ! -f "$SFTPPLUS_CONFIGURATION/server.ini" ]; then
  echo "Initializing admin config..."
  INITIAL_CONFIG=$(mktemp "$SFTPPLUS_CONFIGURATION/server.ini.XXXXXX")
  trap 'rm -f "$INITIAL_CONFIG"' EXIT
  cp /opt/sftpplus-initialization/server-admin.ini.init "$INITIAL_CONFIG"

  /opt/sftpplus/bin/admin-commands.sh generate-self-signed \
    --common-name=sftpplus-k8s.example.com \
    --key-size=2048 \
    --sign-algorithm=sha256 \
    > /tmp/default_tls_certificate.pem
  /opt/sftpplus/bin/admin-commands.sh generate-ssh-key \
    --key-type=rsa \
    --key-size=2048 \
    --key-file=/tmp/default_ssh_rsa_host_key
  sed -i 's/^/    /' /tmp/default_tls_certificate.pem
  sed -i 's/^/    /' /tmp/default_ssh_rsa_host_key
  sed -i -e '/UPDATED_AT_INIT_TLS/{ r /tmp/default_tls_certificate.pem' \
    -e 'd; }' "$INITIAL_CONFIG"
  sed -i -e '/UPDATED_AT_INIT_SSH/{ r /tmp/default_ssh_rsa_host_key' \
    -e 'd; }' "$INITIAL_CONFIG"

  WORKER_PASSWORD=$(cat /opt/sftpplus-worker-credentials/worker-password)
  WORKER_HASH=$(/opt/sftpplus/bin/admin-commands.sh generate-password \
    "$WORKER_PASSWORD")
  ADMIN_PASSWORD=$(cat /opt/sftpplus-admin-credentials/admin-password)
  ADMIN_HASH=$(/opt/sftpplus/bin/admin-commands.sh generate-password \
    "$ADMIN_PASSWORD")
  sed -i "s#UPDATED_AT_INIT_WORKER_HASH_PASSWORD#${WORKER_HASH}#g" \
    "$INITIAL_CONFIG"
  sed -i "s#UPDATED_AT_INIT_ADMIN_HASH_PASSWORD#${ADMIN_HASH}#g" \
    "$INITIAL_CONFIG"

  mv "$INITIAL_CONFIG" "$SFTPPLUS_CONFIGURATION/server.ini"
  trap - EXIT
  rm /tmp/default_tls_certificate.pem /tmp/default_ssh_rsa_host_key \
    /tmp/default_ssh_rsa_host_key.pub
fi

mkdir -p /opt/sftpplus-storage/user-files
echo "Starting SFTPPlus admin ..."
exec /opt/sftpplus/bin/admin-commands.sh start-in-foreground \
  --config="$SFTPPLUS_CONFIGURATION/server.ini"
