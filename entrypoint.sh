#!/bin/bash

# Omada Controller entrypoint for Home Assistant (no-AVX version)
# This is a modified version of mbentley's entrypoint with AVX check disabled

set -e

# ======================================
# Home Assistant specific preprocessing
# ======================================

echo "INFO: [HA Add-on] Setting up directories..."
mkdir -p "/data/logs"

if [ ! -d /data/data ]; then
  echo "INFO: [HA Add-on] /data/data created from docker image backup"
  cp -r /opt/tplink/EAPController/data_backup /data/data

  directories=(db keystore pdf)
  for dir in "${directories[@]}"; do
    if [ -d "/data/$dir" ]; then
      cp -r /data/$dir "/data/data/"
      rm -rf /data/$dir
      echo "INFO: [HA Add-on] Migrated /data/$dir to /data/data/$dir"
    fi
  done
fi

chown -R 508:508 "/data"

export ROOTLESS=false

# ======================================
# Override check_cpu_features BEFORE sourcing mbentley script
# This works because we define it as a function that will be
# called later, not executed immediately
# ======================================

# First, source the mbentley script but prevent execution
# by temporarily redefining the main entry point check

# Save original args
ORIGINAL_ARGS=("$@")

# The mbentley script checks ROOTLESS at the end to decide which main to run
# We need to intercept this. Let's use a different approach:
# Create a wrapper that sources mbentley but skips the final execution

# Temporarily disable the final if block by making ROOTLESS undefined during source
# Actually, let's just patch the script inline

# Create a modified version of the entrypoint
sed 's/^check_cpu_features$/check_cpu_features_disabled/' /mbentley/entrypoint.sh > /tmp/mbentley_modified.sh
echo '
check_cpu_features() {
  echo "INFO: Skipping AVX/CPU feature check - using MongoDB compiled without AVX requirements"
}
' >> /tmp/mbentley_modified.sh

# Now source and run
source /tmp/mbentley_modified.sh

# The script should have executed main_root or main_rootless
