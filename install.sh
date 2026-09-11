#!/usr/bin/env bash

set -e

# Modified install script for no-AVX build
# MongoDB binaries are already copied from rnsc/mongo-wo-avx image
# This script calls mbentley's install.sh with NO_MONGODB=true, then sets up the MongoDB symlink

# Force NO_MONGODB=true since we provide our own binaries
export NO_MONGODB=true

# Call mbentley install script (this installs Omada Controller without MongoDB)
./mbentley/install.sh

# Create symlink for mongod binary that Omada expects
# The mongod binary was copied to /usr/bin/mongod from our no-AVX MongoDB image
OMADA_DIR="/opt/tplink/EAPController"
ln -sf /usr/bin/mongod "${OMADA_DIR}/bin/mongod"
chmod 755 "${OMADA_DIR}"/bin/*

echo "INFO: MongoDB (no-AVX) binary linked successfully"

# =====================================
# Home Assistant specific preprocessing
# =====================================

# Install MongoDB runtime dependencies and jq for Home Assistant options
apt-get update
apt-get install --no-install-recommends -y jq libcurl4t64

# Symlink to Home Assistant data dir to make configuration persistent
mkdir -p /data

mv /opt/tplink/EAPController/data /opt/tplink/EAPController/data_backup
ln -s /data/data /opt/tplink/EAPController/data

rm -rf /opt/tplink/EAPController/logs
ln -s /data/logs /opt/tplink/EAPController/logs

# Cleanup
rm -rf /tmp/* /var/lib/apt/lists/*

echo "INFO: Installation complete"
