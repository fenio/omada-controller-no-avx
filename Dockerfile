# Omada Controller Docker image for CPUs without AVX support
# Based on jkunczik/home-assistant-omada and mbentley/docker-omada-controller
# Uses MongoDB 7.0.28 compiled without AVX from fenio/mongodb-no-avx

# Stage 1: Get MongoDB binaries from the no-AVX build
FROM ghcr.io/fenio/mongodb-no-avx:7.0.28 AS mongodb

# Stage 2: Build Omada Controller
FROM ubuntu:24.04

# Copy install script and mbentley scripts
COPY --chmod=755 install.sh /
COPY --chmod=755 mbentley/healthcheck.sh /mbentley/
COPY --chmod=755 mbentley/install.sh /mbentley/

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

# Copy mbentley entrypoint and patch it to skip AVX check
COPY --chmod=755 mbentley/entrypoint-unified.sh /mbentley/entrypoint.sh
RUN sed -i 's/^  check_cpu_features$/  : # check_cpu_features disabled - using MongoDB without AVX/' /mbentley/entrypoint.sh

# Verify mongod binary and symlink
RUN echo "=== Verifying MongoDB setup ===" && \
    ls -la /usr/bin/mongod && \
    ls -la /opt/tplink/EAPController/bin/mongod && \
    file /usr/bin/mongod && \
    /usr/bin/mongod --version || echo "mongod --version failed (expected on non-AVX build machine)"

WORKDIR /opt/tplink/EAPController/lib
EXPOSE 8088 8043 8843 27001/udp 29810/udp 29811 29812 29813 29814 29815 29816 29817
HEALTHCHECK --start-period=6m CMD /mbentley/healthcheck.sh
VOLUME ["/data"]
ENTRYPOINT ["/mbentley/entrypoint.sh"]
CMD ["/usr/bin/java","-server","-Xms128m","-Xmx1024m","-XX:MaxHeapFreeRatio=60","-XX:MinHeapFreeRatio=30","-XX:+HeapDumpOnOutOfMemoryError","-XX:HeapDumpPath=/opt/tplink/EAPController/logs/java_heapdump.hprof","-Djava.awt.headless=true","--add-opens","java.base/java.util=ALL-UNNAMED","-cp","/opt/tplink/EAPController/lib/*::/opt/tplink/EAPController/properties:","com.tplink.smb.omada.starter.OmadaLinuxMain"]
