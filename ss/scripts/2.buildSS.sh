#!/bin/bash


export SS_VER="3.3.1"

BUILD_DIR=$2

build_ss_func()
{
    pushd ${BUILD_DIR}
#    rm -rf shadowsocks-libev-$SS_VER
#    rm -rf v$SS_VER.tar.gz
    rm -rf shadowsocks-libev

    # Installation of libsodium
#    wget -c https://github.com/shadowsocks/shadowsocks-libev/archive/v$SS_VER.tar.gz
#    tar xvf v$SS_VER.tar.gz
    git clone https://github.com/shadowsocks/shadowsocks-libev.git
#    pushd shadowsocks-libev-3.3.1
    pushd shadowsocks-libev
    git fetch --all --tags --prune
    git checkout tags/v${SS_VER} -b v${SS_VER}
    git submodule init
    git submodule update
    ./autogen.sh 
    ./configure
    make
    popd
    popd
}

case $1 in
    "build") echo "Building ss ..."
        build_ss_func $2
        echo "Building ss finished."
        ;;
    *) echo "unknow action"
        exit 1
esac


