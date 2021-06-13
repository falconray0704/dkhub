#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x

. ../libShell/echo_color.lib
. ../libShell/time.lib

LATEST_VERSION="2.0.45"
ARCH=$(arch)
TIME_STAMP=$(timestamp)

DNSCRYPT_PROXY_RELEASE_PACKAGE="dnscrypt-proxy-${ARCH}-${TIME_STAMP}.tar.gz"

#TOP_PATH=$(cd ../ && pwd -P)
TOP_PATH=$(dirname ${PWD})

BUILD_ROOT_PATH=${TOP_PATH}/dnscryptProxy/buildRoot

GOPATH_PATH=${BUILD_ROOT_PATH}/gopath

SRC_ROOT_PATH=${BUILD_ROOT_PATH}/src
SRC_BUILD_PATH=${BUILD_ROOT_PATH}/src/dnscrypt-proxy-${LATEST_VERSION}/dnscrypt-proxy

DEST_PATH=${BUILD_ROOT_PATH}/dest/dnscrypt-proxy-${ARCH}

RELEASE_ROOT_DIR="deployPkgs"
RELEASE_PATH=${TOP_PATH}/${RELEASE_ROOT_DIR}/${ARCH}

get_latest_src_func()
{
    mkdir -p ${SRC_ROOT_PATH}
    pushd ${SRC_ROOT_PATH}
    rm -rf dnscrypt-proxy-src.${LATEST_VERSION}.tar.gz
    wget -c https://github.com/jedisct1/dnscrypt-proxy/archive/${LATEST_VERSION}.tar.gz
#    mv ${LATEST_VERSION}.tar.gz dnscrypt-proxy-src.${LATEST_VERSION}.tar.gz
    popd
}

build_latest_func()
{

    mkdir -p ${GOPATH_PATH}/bin
    mkdir -p ${GOPATH_PATH}/src

    rm -rf ${SRC_BUILD_PATH}/dnscrypt-proxy-${ARCH}
    rm -rf ${SRC_ROOT_PATH}/dnscrypt-proxy-${LATEST_VERSION}
    tar -zxf ${SRC_ROOT_PATH}/${LATEST_VERSION}.tar.gz -C ${SRC_ROOT_PATH}/

#    docker run --rm -it -v ${TOP_PATH}:${TOP_PATH} -v ${GOPATH_PATH}:/gopath -w ${SRC_BUILD_PATH} --entrypoint="/bin/bash" --env GOPATH=/gopath golang 
    docker run --rm -it -v ${TOP_PATH}:${TOP_PATH} -v ${GOPATH_PATH}:/gopath -w ${SRC_BUILD_PATH} --env GOPATH=/gopath golang go build -ldflags="-s -w" -o dnscrypt-proxy-${ARCH}
#    docker run --rm -it -v ${TOP_PATH}:${TOP_PATH} -v ${GOPATH_PATH}:/gopath -w ${SRC_BUILD_PATH} --env GOPATH=/gopath --dns="192.168.11.1" golang go build -ldflags="-s -w" -o dnscrypt-proxy-${ARCH}


    rm -rf ${DEST_PATH}
    mkdir -p ${DEST_PATH}
    cp ${SRC_BUILD_PATH}/dnscrypt-proxy-${ARCH} ${DEST_PATH}/dnscrypt-proxy
    cp ${SRC_BUILD_PATH}/example-* ${DEST_PATH}/

}

relpkgs_dns_func()
{
    mkdir -p ${RELEASE_PATH}
    rm -rf ${RELEASE_PATH}/dnscrypt-proxy

    pushd ${RELEASE_PATH}
    cp -a ${DEST_PATH} ./
    mv dnscrypt-proxy-${ARCH} dnscrypt-proxy
    tar -zcf ${DNSCRYPT_PROXY_RELEASE_PACKAGE} dnscrypt-proxy
    popd
}

usage_func()
{
    echoY "./run.sh <cmd> <target>"
    echo ""
    echoY "Supported cmd:"
    echo "[ get, build, relpkgs ]"
    echo ""
    echoY "Supported target:"
    echo "[ src, dns ]"
}

echoG "TOP_PATH:${TOP_PATH}"

[ $# -lt 2 ] && echoR "Invalid args count:$# " && usage_func && exit 1

case $1 in
    get) echoY "Fetching $2 ..."
        if [ $2 == "src" ]
        then
            echoY "Fetching dnscrypt-proxy  ${LATEST_VERSION}.tar.gz"
            get_latest_src_func
        else
            echoR "Unknow target:$2, only support fetching target [ src ]."
        fi
        ;;
    build) echoY "Building ..."
        if [ $2 == "dns" ]
        then
            echoY "Building dnscrypt-proxy ${LATEST_VERSION}.tar.gz..."
            build_latest_func
        else
            echoR "Unknow target:$2, only support building target [ dns ]."
        fi
        ;;
    relpkgs) echoY "Releasing ..."
        if [ $2 == "dns" ]
        then
            echoY "Releasing ${DNSCRYPT_PROXY_RELEASE_PACKAGE} to:${RELEASE_PATH}"
            relpkgs_dns_func
        else
            echoR "Unknow target:$2, only support releasing target [ dns ]."
        fi
        ;;
    *) echo "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

