# Omada Controller Docker image for CPUs without AVX support
# Based on jkunczik/home-assistant-omada and mbentley/docker-omada-controller
# Uses MongoDB 8.0.26 compiled without AVX by rnsc/mongodb-without-avx

# Stage 1: Get MongoDB binaries from the no-AVX build
FROM rnsc/mongo-wo-avx:8.0.26@sha256:d6cc81ad4b9d3439b2f577a0caa98c86659dba0f3c64e686cf5551023c386c9f AS mongodb

# Stage 2: Build Omada Controller
FROM ubuntu:24.04

# OCI labels for GitHub Container Registry
LABEL org.opencontainers.image.source=https://github.com/fenio/omada-controller-no-avx
LABEL org.opencontainers.image.description="TP-Link Omada Controller for CPUs without AVX support"
LABEL org.opencontainers.image.licenses=MIT

# Copy install script and mbentley scripts
COPY --chmod=755 install.sh /
COPY --chmod=755 mbentley/healthcheck.sh /mbentley/
COPY --chmod=755 mbentley/install.sh /mbentley/

# Copy MongoDB binaries from the no-AVX build
COPY --from=mongodb /usr/local/bin/mongod /usr/bin/mongod
COPY --from=mongodb /usr/local/bin/mongos /usr/bin/mongos
COPY --from=mongodb /avx_report.txt /mongodb-avx-report.txt

# Set architecture - only amd64 supported for now
ARG ARCH=amd64

# Omada Controller version to install
ARG INSTALL_VER=6.3.0.45

# Skip MongoDB installation since we copied binaries above
ARG NO_MONGODB=true

# Install Omada Controller
RUN /install.sh && rm /install.sh && rm /mbentley/install.sh

# Copy mbentley entrypoint and patch it to skip AVX check
COPY --chmod=755 mbentley/entrypoint-unified.sh /mbentley/entrypoint.sh
COPY --chmod=755 entrypoint.sh /entrypoint.sh
RUN sed -i 's/^  check_cpu_features$/  : # check_cpu_features disabled - using MongoDB without AVX/' /mbentley/entrypoint.sh

# Verify mongod binary and symlink
RUN echo "=== Verifying MongoDB setup ===" && \
    ls -la /usr/bin/mongod && \
    ls -la /opt/tplink/EAPController/bin/mongod && \
    cat /mongodb-avx-report.txt && \
    /usr/bin/mongod --version

WORKDIR /opt/tplink/EAPController/lib
EXPOSE 8044 8088 8043 8843 19810/udp 27001/udp 29810/udp 29811 29812 29813 29814 29815 29816 29817
HEALTHCHECK --start-period=6m CMD /mbentley/healthcheck.sh
VOLUME ["/data"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/java","-server","-Xms128m","-Xmx1024m","-XX:MaxHeapFreeRatio=60","-XX:MinHeapFreeRatio=30","-XX:+HeapDumpOnOutOfMemoryError","-XX:HeapDumpPath=/opt/tplink/EAPController/logs/java_heapdump.hprof","-Djava.awt.headless=true","-cp","/opt/tplink/EAPController/lib/*:/opt/tplink/EAPController/properties","com.tplink.smb.omada.starter.OmadaLinuxMain"]
