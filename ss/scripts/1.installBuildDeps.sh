#!/bin/bash

[ $# -lt 1 ] && echo "Invalid args count:$#." && exit 1

export LIBSODIUM_VER=1.0.18
export MBEDTLS_VER=2.16.2

install_pkgs_func()
{
	sudo apt-get purge -y libbloom-dev libcork-dev libcorkipset-dev libmbedtls-dev libsodium-dev

    pushd ${ssRoot}
#    pushd ${depPkgs}
    # Installation of libsodium
    wget -c https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VER.tar.gz
    tar xvf libsodium-$LIBSODIUM_VER.tar.gz
    pushd libsodium-$LIBSODIUM_VER
    ./configure --prefix=/usr && make
    make install
    popd
    ldconfig

    # Installation of MbedTLS
    wget -c https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz
    tar xvf mbedtls-$MBEDTLS_VER-gpl.tgz
    pushd mbedtls-$MBEDTLS_VER
    make SHARED=1 CFLAGS="-O2 -fPIC"
    make DESTDIR=/usr install
    popd
    ldconfig
#    popd
    popd
}

clean_pkgs_func()
{
    pushd ${ssRoot}
#    rm -rf ${depPkgs}
#    rm -rf libsodium-$LIBSODIUM_VER
#    rm -rf mbedtls-$MBEDTLS_VER
    popd
}

#if [ $UID -ne 0 ]
#then
#    echo "Superuser privileges are required to run this script."
#    echo "e.g. \"sudo $0\""
#    exit 1
#fi

case $1 in
    "install") echo "Installing ss build dependencies..."
        install_pkgs_func
        echo "Install ss build dependencies finished."
        ;;
    "clean") echo "Cleaning ss dependencies building temp files..."
        clean_pkgs_func
        ;;
    *) echo "Unsupported cmd."
        exit 1
esac


