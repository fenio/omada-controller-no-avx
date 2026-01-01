#!/bin/bash

# Omada Controller entrypoint for Home Assistant (no-AVX version)
# Based on jkunczik/home-assistant-omada
# AVX CPU check is bypassed since we use MongoDB compiled without AVX

set -e

# ======================================
# Home Assistant specific preprocessing
# ======================================

# Check if bashio is available (running in HA), otherwise use echo
if command -v bashio &> /dev/null; then
  log_info() { bashio::log.info "$1"; }
else
  log_info() { echo "INFO: $1"; }
fi

# Create data and logs dir if not existing
log_info "Create 'logs' directory inside persistent /data volume, if it doesn't exist."
mkdir -p "/data/logs"

if [ ! -d /data/data ]; then
  log_info "/data/data created from docker image backup"
  cp -r /opt/tplink/EAPController/data_backup /data/data

  # Check if old directory structure is in place (/data) and copy to (/data/data)
  directories=(db keystore pdf)
  for dir in "${directories[@]}"; do
    if [ -d "/data/$dir" ]; then
      cp -r /data/$dir "/data/data/"
      rm -rf /data/$dir
      log_info "Migrate from old Add-On file structure. Copied /data/$dir to /data/data/$dir"
    else
      log_info "Already in new file structure. /data/$dir does not exist, skipping."
    fi
  done
fi

# Set permissions on /data directory for Home Assistant persistence
chown -R 508:508 "/data"

# Use SSL Keys from Home Assistant
if [ -n "${BASHIO_SUPERVISOR_TOKEN:-}" ]; then
  # Running in Home Assistant
  if bashio::config.true 'enable_hass_ssl'; then
    log_info "Use SSL from Home Assistant"
    SSL_CERT_NAME=$(bashio::config 'certfile')
    log_info "SSL certificate: ${SSL_CERT_NAME}"
    SSL_KEY_NAME=$(bashio::config 'keyfile')
    log_info "SSL private key: ${SSL_KEY_NAME}"

    # Put keys in /cert folder, this is how mbentley expects it
    mkdir -p /cert
    cp "/ssl/$SSL_CERT_NAME" /cert/
    cp "/ssl/$SSL_KEY_NAME" /cert/

    export SSL_CERT_NAME="$(basename "$SSL_CERT_NAME")"
    export SSL_KEY_NAME="$(basename "$SSL_KEY_NAME")"
  fi

  if bashio::config.true 'enable_workaround_509'; then
    log_info "Enable workaround for issue #509"
    export WORKAROUND_509=true
  fi
fi

# Don't use rootless mode for this Add-On
export ROOTLESS=false

# ======================================
# Source mbentley entrypoint functions
# (but don't execute main yet)
# ======================================

# Prevent mbentley entrypoint from auto-executing by temporarily overriding main functions
main_root() { :; }
main_rootless() { :; }

# Source mbentley script to get all the functions
source /mbentley/entrypoint.sh

# ======================================
# Override the AVX check function
# ======================================
# We use MongoDB compiled without AVX, so bypass the CPU feature check
check_cpu_features() {
  echo "INFO: Skipping AVX/CPU feature check - using MongoDB compiled without AVX requirements"
}

# ======================================
# Now run the actual main function
# ======================================

# Re-initialize EXEC_ARGS since sourcing cleared it
EXEC_ARGS=("${@}")

# Run the real main_root function (copied from mbentley)
setup_environment
setup_user_group
common_setup_and_validation

echo "INFO: Starting Omada Controller as user ${PUSERNAME}"
tail_logs
exec gosu "${PUSERNAME}" "${EXEC_ARGS[@]}"
