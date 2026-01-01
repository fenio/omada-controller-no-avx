# Omada Controller Docker image for CPUs without AVX support
# Based on jkunczik/home-assistant-omada and mbentley/docker-omada-controller
# Uses MongoDB 7.0.28 compiled without AVX from fenio/mongodb-no-avx

# Stage 1: Get MongoDB binaries from the no-AVX build
FROM ghcr.io/fenio/mongodb-no-avx:7.0.28 AS mongodb

# Stage 2: Build Omada Controller
FROM ubuntu:24.04

# Copy install script and mbentley scripts
COPY install.sh /
COPY mbentley/healthcheck.sh /mbentley/
COPY mbentley/install.sh /mbentley/

# Copy MongoDB binaries from the no-AVX build
COPY --from=mongodb /usr/local/bin/mongod /usr/bin/mongod
COPY --from=mongodb /usr/local/bin/mongos /usr/bin/mongos

# Set architecture - only amd64 supported for now
ARG ARCH=amd64

# Omada Controller version to install
ARG INSTALL_VER=6.0.0.25

# Skip MongoDB installation since we copied binaries above
ARG NO_MONGODB=true

# Install Omada Controller
RUN /install.sh && rm /install.sh && rm /mbentley/install.sh

# Copy entrypoint after installation to avoid rebuilding whole image on changes
COPY entrypoint.sh /
COPY mbentley/entrypoint-unified.sh /mbentley/entrypoint.sh

WORKDIR /opt/tplink/EAPController/lib
EXPOSE 8088 8043 8843 27001/udp 29810/udp 29811 29812 29813 29814 29815 29816 29817
HEALTHCHECK --start-period=6m CMD /mbentley/healthcheck.sh
VOLUME ["/data"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/java","-server","-Xms128m","-Xmx1024m","-XX:MaxHeapFreeRatio=60","-XX:MinHeapFreeRatio=30","-XX:+HeapDumpOnOutOfMemoryError","-XX:HeapDumpPath=/opt/tplink/EAPController/logs/java_heapdump.hprof","-Djava.awt.headless=true","--add-opens","java.base/java.util=ALL-UNNAMED","-cp","/opt/tplink/EAPController/lib/*::/opt/tplink/EAPController/properties:","com.tplink.smb.omada.starter.OmadaLinuxMain"]
