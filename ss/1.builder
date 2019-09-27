#FROM debian:stretch-slim
#FROM ubuntu:16.04
FROM rayruan/ubt:basic1604


RUN apt-get update \
    && basicPkgs='git wget ca-certificates' \
    && buildPkgs='gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libc-ares-dev automake' \
    && apt-get install --no-install-recommends -y $basicPkgs $buildPkgs \
    && apt-get --purge autoremove -y \
    && apt-get autoclean -y


#RUN apt-get update \
#        && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y apt-utils \
#        && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y git wget ca-certificates \
#        && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libc-ares-dev automake \
#        && apt-get --purge autoremove -y \
#        && apt-get autoclean -y

#        && DEBIAN_FRONTEND=noninteractive apt-get purge -y libbloom-dev libcork-dev libcorkipset-dev libmbedtls-dev libsodium-dev \
#        && rm -rf /var/cache/apt/archives/* \
#        && rm /etc/apt/sources.list \
#        && rm -rf /var/lib/apt/lists/*


ENTRYPOINT [ "/bin/bash" ]

ENV ssRoot /ssRoot

RUN mkdir ${ssRoot}

COPY . ${ssRoot}

WORKDIR ${ssRoot}

RUN pwd \
    && ls -al \
    && mkdir depPkgs \
    && ./scripts/1.installBuildDeps.sh install \
    && ls -al \
    && rm -rf ./*

