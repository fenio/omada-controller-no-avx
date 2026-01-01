#!/bin/bash

# Omada Controller entrypoint for Home Assistant (no-AVX version)
# Based on jkunczik/home-assistant-omada
# AVX CPU check is bypassed since we use MongoDB compiled without AVX

set -e

# ======================================
# Home Assistant specific preprocessing
# ======================================

# Simple logging function
log_info() { echo "INFO: $1"; }

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
