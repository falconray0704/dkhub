#!/bin/bash

set -e
set -x


RED='\033[0;31m'
NC='\033[0m'

[ $# -lt 1 ] && echo "${RED}Invalid args count:$#${NC}"


BASE="${PWD}/${buildDir}"
PREFIX="$BASE/stage"
SRC="$BASE/src"
DIST="$BASE/dist"


# libev
LIBEV_VER=4.27
LIBEV_NAME=libev-${LIBEV_VER}
LIBEV_URL=http://dist.schmorp.de/libev/${LIBEV_NAME}.tar.gz

## mbedTLS
MBEDTLS_VER=2.16.2
#MBEDTLS_VER=2.9.0
MBEDTLS_NAME=mbedtls-${MBEDTLS_VER}
MBEDTLS_URL=https://tls.mbed.org/download/${MBEDTLS_NAME}-apache.tgz

## Sodium
SODIUM_VER=1.0.18
#SODIUM_VER=1.0.16
SODIUM_NAME=libsodium-${SODIUM_VER}
SODIUM_URL=https://download.libsodium.org/libsodium/releases/${SODIUM_NAME}.tar.gz

## PCRE
PCRE_VER=8.43
#PCRE_VER=8.42
PCRE_NAME=pcre-${PCRE_VER}
PCRE_URL=https://ftp.pcre.org/pub/pcre/${PCRE_NAME}.tar.gz

#PCRE_VER=10.33
#PCRE_NAME=pcre2-${PCRE_VER}
#PCRE_URL=https://ftp.pcre.org/pub/pcre/${PCRE_NAME}.tar.gz

## c-ares
CARES_VER=1.14.0
CARES_NAME=c-ares-${CARES_VER}
CARES_URL=https://c-ares.haxx.se/download/${CARES_NAME}.tar.gz

#shadowsocks-libev
SHADOWSOCKS_VER=3.3.1
#SHADOWSOCKS_VER=3.2.0
SHADOWSOCKS_NAME=shadowsocks-libev-${SHADOWSOCKS_VER}
SHADOWSOCKS_URL=https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${SHADOWSOCKS_VER}/${SHADOWSOCKS_NAME}.tar.gz

#apt-get update -y
#apt-get install --no-install-recommends -y build-essential gcc-aarch64-linux-gnu g++-aarch64-linux-gnu automake autoconf libtool aria2


# download source
download_sources_func()
{
    pushd "${SRC}"
    DOWN="aria2c --file-allocation=trunc -s10 -x10 -j10 -c"
    for pkg in LIBEV SODIUM MBEDTLS PCRE CARES SHADOWSOCKS
    do
        name=${pkg}_NAME
        url=${pkg}_URL
        filename="${!name}".tar.gz
        $DOWN ${!url} -o "${filename}"
    done
    popd
}

# extract source
extract_sources_func()
{
    ARCH=$1
    pushd "${SRC}"
    pwd
    mkdir -p ${ARCH}
    for pkg in LIBEV SODIUM MBEDTLS PCRE CARES SHADOWSOCKS
    do
        name=${pkg}_NAME
        url=${pkg}_URL
        filename="${!name}".tar.gz
        echo "Extracting: ${filename}..."
        tar xf ${filename} -C ${ARCH}
    done
    popd
}

dk_extract_sourcess() {
    for ARCH in x86_64 aarch64
    do
        extract_sources_func $ARCH
    done
}

# build deps
build_deps() {
    # 静态编译参数
    ARCH=$1
    host=$ARCH-linux-gnu
    prefix=${PREFIX}/$ARCH
    args="--host=${host} --prefix=${prefix} --disable-shared --enable-static"

    # libev
    pwd
    pushd "$SRC/${ARCH}/$LIBEV_NAME"
    ./configure $args
    make clean
    make -j8
    make install
    popd

    # mbedtls
    pushd "$SRC/${ARCH}/$MBEDTLS_NAME"
    make clean
    make DESTDIR="${prefix}" CC="${host}-gcc" AR="${host}-ar" LD="${host}-ld" LDFLAGS=-static install -j8
    unset DESTDIR
    popd

    # sodium
    pushd "$SRC/${ARCH}/$SODIUM_NAME"
    ./configure $args
    make clean
    make -j8
    make install
    popd

    # pcre
    pushd "$SRC/${ARCH}/$PCRE_NAME"
    ./configure $args \
      --enable-unicode-properties --enable-utf8
    make clean
    make -j8
    make install
    popd

    # c-ares
    pushd "$SRC/${ARCH}/$CARES_NAME"
    ./configure $args
    make clean
    make -j8
    make install
    popd
}

dk_deps() {
    for arch in x86_64 aarch64
    do
        build_deps $arch
    done
}

build_proj() {
    ARCH=$1
    host=$ARCH-linux-gnu
    prefix=${DIST}/$ARCH
    dep=${PREFIX}/$ARCH 

    pushd "$SRC/${ARCH}/$SHADOWSOCKS_NAME"
    ./configure LIBS="-lpthread -lm" \
        LDFLAGS="-Wl,-static -static -static-libgcc -L$dep/lib" \
        CFLAGS="-I$dep/include" \
        --host=${host} \
        --prefix=${prefix} \
        --disable-ssp \
        --disable-documentation \
        --with-mbedtls="$dep" \
        --with-pcre="$dep" \
        --with-sodium="$dep" \
        --with-cares="$dep"
    make clean
    make install-strip -j8
    popd
    cp ./setup/srv/* ${prefix}/bin/
}

dk_build() {
    for ARCH in x86_64 aarch64
    do
        build_proj $ARCH
    done
}

archClean() 
{
    ARCH=$1
    rm -rf ${PREFIX}/${ARCH} ${SRC}/${ARCH} ${DIST}/${ARCH}
}

dk_clean() {
    for ARCH in x86_64 aarch64
    do
        archClean $ARCH
    done
}

mkdir -p ${PREFIX} 
mkdir -p ${SRC} 
mkdir -p ${DIST}

download_sources_func

case $1 in
    "x86_64"|"armv7l") echo "Building static SS for $1..."
        archClean $1
        extract_sources_func $1
        build_deps $1
        build_proj $1
        echo "Building static SS for $1 finished."
        ;;
    "aarch64") echo "Building static SS for aarch64..."
        archClean aarch64
        extract_sources_func aarch64
        build_deps aarch64
        build_proj aarch64
        echo "Building static SS for aarch64 finished."
        ;;
    "all") echo "Building static SS for all platform..."
        dk_clean
        dk_extract_sourcess
        dk_deps
        dk_build
        echo "Building static SS for all platform finished."
        ;;
    *) echo "Unsupported cmd."
        exit 1
esac


exit 0

# 工具
# upx
mkdir -p "${SRC}"

UPX_VER=3.94
UPX_NAME=upx-${UPX_VER}-amd64_linux
UPX_URL=https://github.com/upx/upx/releases/download/v${UPX_VER}/${UPX_NAME}.tar.xz
cd ${SRC}
wget ${UPX_URL}
tar -Jxf "${UPX_NAME}.tar.xz"
mv ${UPX_NAME}/upx /usr/bin



rm -rf "$BASE/pack"
mkdir -p "$BASE/pack"
cd "$BASE/pack"
mkdir -p shadowsocks-libev
cd shadowsocks-libev
mkdir -p aarch64
mkdir -p x86_64

for bin in local server tunnel
do
    cp ${DIST}/aarch64/bin/ss-${bin} aarch64
    cp ${DIST}/x86_64/bin/ss-${bin} x86_64
    upx aarch64/ss-${bin}
    upx x86_64/ss-${bin}
done

cd "$BASE/pack"
tar -Jcf bin.tar.xz shadowsocks-libev
echo -e "${RED}${BASE}/pack/bin.tar.gz 打包完毕${NC}"
