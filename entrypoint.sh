#!/bin/bash

# Omada Controller entrypoint for Home Assistant.

set -e

ROOTLESS="${ROOTLESS:-false}"

echo "INFO: [HA Add-on] Setting up directories..."
mkdir -p "/data/logs"

if [ ! -d /data/data ]; then
  echo "INFO: [HA Add-on] /data/data created from docker image backup"
  cp -r /opt/tplink/EAPController/data_backup /data/data

  directories=(db keystore pdf)
  for dir in "${directories[@]}"; do
    if [ -d "/data/$dir" ]; then
      cp -r "/data/${dir}" "/data/data/"
      rm -rf "/data/${dir}"
      echo "INFO: [HA Add-on] Migrated /data/$dir to /data/data/$dir"
    fi
  done
fi

if [ "${ROOTLESS}" != "true" ]; then
  chown -R 508:508 "/data"
fi

if [ -f /data/options.json ]; then
  if [ "$(jq -r '.enable_hass_ssl // false' /data/options.json)" = "true" ]; then
    ssl_cert_name="$(jq -er '.certfile' /data/options.json)"
    ssl_key_name="$(jq -er '.keyfile' /data/options.json)"

    if [ ! -f "/ssl/${ssl_cert_name}" ] || [ ! -f "/ssl/${ssl_key_name}" ]; then
      echo "ERROR: Home Assistant SSL certificate or key not found in /ssl"
      exit 1
    fi

    echo "INFO: [HA Add-on] Importing SSL certificate from /ssl"
    mkdir -p /cert
    cp "/ssl/${ssl_cert_name}" "/cert/$(basename "${ssl_cert_name}")"
    cp "/ssl/${ssl_key_name}" "/cert/$(basename "${ssl_key_name}")"
    SSL_CERT_NAME="$(basename "${ssl_cert_name}")"
    SSL_KEY_NAME="$(basename "${ssl_key_name}")"
    export SSL_CERT_NAME SSL_KEY_NAME
  fi

  if [ "$(jq -r '.enable_workaround_509 // false' /data/options.json)" = "true" ]; then
    echo "WARN: [HA Add-on] enable_workaround_509 is obsolete and has no effect with Omada 6.3"
  fi
fi

export ROOTLESS
exec /mbentley/entrypoint.sh "$@"
