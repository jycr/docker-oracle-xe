FROM debian:stable-slim

ARG BUILD_PACKAGES="\
    curl \
    unzip \
    wget \
    alien \
"
ARG RUN_PACKAGES="\
    bc \
    libaio1 \
    net-tools \
    unixodbc \
"

ENV PRODUCT_VERSION=11.2.0

# checksum, download will be validated using it
ARG PRODUCT_SHA=93710c1f4abc72839827be1a55274b6172009afb98de4581baab6351b7345363ed8b5b7517bfe16a722ba0744041397b63026a0cacfeb7b2408111f1d48811d4

# Can be used to customize where package get downloaded from
ARG PRODUCT_URL=https://www.marco-gatti.com/debian/squeeze/unstable/oracle-xe_${PRODUCT_VERSION}-1.0_amd64.deb

#Unable to download package from official website
#ARG PRODUCT_URL=http://download.oracle.com/otn/linux/oracle11g/xe/oracle-xe-11.2.0-1.0.x86_64.rpm.zip

COPY assets /assets

# unzip oracle-xe_amd64.rpm.zip
# 

RUN set -ex \
    && chmod +x /assets/*.sh \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        $BUILD_PACKAGES \
        $RUN_PACKAGES \
    && /assets/setup.sh "$PRODUCT_VERSION" "$PRODUCT_URL" "$PRODUCT_SHA" \
    && apt-get remove --purge -y \
        $BUILD_PACKAGES \
    && rm -rf /var/lib/apt/lists/*


EXPOSE 1521
EXPOSE 8080

CMD /usr/sbin/startup.sh && tail -f /dev/null
