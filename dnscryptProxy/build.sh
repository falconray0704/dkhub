#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x

. ../libShell/echo_color.lib

LATEST_VERSION="2.0.31"
ARCH=$(arch)

TOP_DIR=$(cd ../ && pwd -P)

BUILD_ROOT_DIR=${TOP_DIR}/dnscryptProxy/buildRoot

GOPATH_DIR=${BUILD_ROOT_DIR}/gopath

SRC_ROOT_DIR=${BUILD_ROOT_DIR}/src
SRC_BUILD_DIR=${BUILD_ROOT_DIR}/src/dnscrypt-proxy-${LATEST_VERSION}/dnscrypt-proxy

DEST_DIR=${BUILD_ROOT_DIR}/dest/dnscrypt-proxy-${ARCH}

get_latest_src_func()
{
    mkdir -p ${SRC_ROOT_DIR}
    pushd ${SRC_ROOT_DIR}
    rm -rf dnscrypt-proxy-src.${LATEST_VERSION}.tar.gz
    wget -c https://github.com/jedisct1/dnscrypt-proxy/archive/${LATEST_VERSION}.tar.gz
#    mv ${LATEST_VERSION}.tar.gz dnscrypt-proxy-src.${LATEST_VERSION}.tar.gz
    popd
}

build_latest_func()
{

    mkdir -p ${GOPATH_DIR}/bin
    mkdir -p ${GOPATH_DIR}/src

    rm -rf ${SRC_BUILD_DIR}/dnscrypt-proxy-${ARCH}
    rm -rf ${SRC_ROOT_DIR}/dnscrypt-proxy-${LATEST_VERSION}
    tar -zxf ${SRC_ROOT_DIR}/${LATEST_VERSION}.tar.gz -C ${SRC_ROOT_DIR}/

#    docker run --rm -it -v ${TOP_DIR}:${TOP_DIR} -v ${GOPATH_DIR}:/gopath -w ${SRC_BUILD_DIR} --entrypoint="/bin/bash" --env GOPATH=/gopath golang 
    docker run --rm -it -v ${TOP_DIR}:${TOP_DIR} -v ${GOPATH_DIR}:/gopath -w ${SRC_BUILD_DIR} --env GOPATH=/gopath golang go build -ldflags="-s -w" -o dnscrypt-proxy-${ARCH}


    rm -rf ${DEST_DIR}
    mkdir -p ${DEST_DIR}
    cp ${SRC_BUILD_DIR}/dnscrypt-proxy-${ARCH} ${DEST_DIR}/dnscrypt-proxy
    cp ${SRC_BUILD_DIR}/example-* ${DEST_DIR}/

}

config_func()
{

    pushd ${HOME}/dnscrypt-proxy
    cp example-dnscrypt-proxy.toml dnscrypt-proxy.toml
	sed -i "s/^# server_names =.*/server_names = \['cisco', 'google', 'scaleway-fr', 'yandex', 'cloudflare'\]/" dnscrypt-proxy.toml
	sed -i "s/^listen_addresses =.*/listen_addresses = \['127.0.0.1:53'\]/" dnscrypt-proxy.toml
	sed -i "s/.*ignore_system_dns =.*/ignore_system_dns = true/" dnscrypt-proxy.toml
	sed -i "s/.*force_tcp =.*/force_tcp = true/" dnscrypt-proxy.toml
	sed -i "s/^timeout =.*/timeout = 3000/" dnscrypt-proxy.toml

    popd
}

install_service()
{
    pushd ${HOME}/dnscrypt-proxy
    ./dnscrypt-proxy -service install
    popd
}

usage_func()
{
    echo "./build.sh <cmd> <target>"
    echo ""
    echo "Supported cmd:"
    echo "[ get, build, install ]"
    echo ""
    echo "Supported target:"
    echo "[ src, dns, service, installer ]"
}

echoG "TOP_DIR:${TOP_DIR}"

[ $# -lt 2 ] && echo "Invalid args count:$# " && usage_func && exit 1

case $1 in
    get) echoY "Fetching $2 ..."
        if [ $2 == "src" ]
        then
            echo "Fetching dnscrypt-proxy  ${LATEST_VERSION}.tar.gz"
            get_latest_src_func
        else
            echoR "Unknow target:$2, only support fetching target [ src ]."
        fi
        ;;
    build) echoY "Building dynamic SS from github ..."
        if [ $2 == "dns" ]
        then
            echo "Building dnscrypt-proxy ${LATEST_VERSION}.tar.gz..."
            build_latest_func
        elif [ $2 == "installer" ]
        then
            echo "Building dnscrypt-proxy docker image for deployment..."
            docker rmi rayruan/dnscrypt-proxy_${ARCH}:installer
            docker image prune
            docker build --rm -t rayruan/dnscrypt-proxy_${ARCH}:installer -f Dockerfile_installer.img ${DEST_DIR}
        else
            echoR "Unknow target:$2, only support building target [dns, installer]."
        fi
        ;;
    install) echoY "Installing..."
        if [ $2 == "dns" ] 
        then
            echoY "Installing dnscrypt-proxy to your ${HOME}..."
            sudo rm -rf ${HOME}/dnscrypt-proxy
            docker run --rm -it -v ${HOME}:/target rayruan/dnscrypt-proxy_${ARCH}:installer 
            sudo chown -hR $(users):$(users) ${HOME}/dnscrypt-proxy
            cp dnsCryptSrc/public-resolvers.md* ${HOME}/dnscrypt-proxy/

            config_func
        elif [ $2 == "service" ]
        then
            echoY "Installing dnscrypt-proxy service..."
            install_service
        else
            echoR "Unknow target:$2, only support installing target [dns, service]."
        fi
        ;;
    *) echo "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

