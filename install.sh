#!/usr/bin/env bash

set -e

# Modified install script for no-AVX build
# MongoDB binaries are already copied from fenio/mongodb-no-avx image
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

# Install bashio for parsing Home Assistant add-on options
apt-get update
apt-get install --no-install-recommends -y ca-certificates curl jq
BASHIO_VERSION="0.16.2"
echo "**** Install BashIO ${BASHIO_VERSION}, for parsing HASS AddOn options ****"
curl -J -L -o /tmp/bashio.tar.gz "https://github.com/hassio-addons/bashio/archive/refs/tags/v${BASHIO_VERSION}.tar.gz"
mkdir /tmp/bashio
tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio
mv /tmp/bashio/lib /usr/lib/bashio
ln -s /usr/lib/bashio/bashio /usr/bin/bashio

# Symlink to Home Assistant data dir to make configuration persistent
mkdir -p /data

mv /opt/tplink/EAPController/data /opt/tplink/EAPController/data_backup
ln -s /data/data /opt/tplink/EAPController/data

rm -rf /opt/tplink/EAPController/logs
ln -s /data/logs /opt/tplink/EAPController/logs

# Cleanup
rm -rf /tmp/* /var/lib/apt/lists/*

echo "INFO: Installation complete"
