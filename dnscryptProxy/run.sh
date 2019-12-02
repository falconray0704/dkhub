#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x

. ../libShell/echo_color.lib

LATEST_VERSION="2.0.33"
ARCH=$(arch)

#TOP_PATH=$(cd ../ && pwd -P)
TOP_PATH=$(dirname ${PWD})

BUILD_ROOT_PATH=${TOP_PATH}/dnscryptProxy/buildRoot

GOPATH_PATH=${BUILD_ROOT_PATH}/gopath

SRC_ROOT_PATH=${BUILD_ROOT_PATH}/src
SRC_BUILD_PATH=${BUILD_ROOT_PATH}/src/dnscrypt-proxy-${LATEST_VERSION}/dnscrypt-proxy

DEST_PATH=${BUILD_ROOT_PATH}/dest/dnscrypt-proxy-${ARCH}

RELEASE_ROOT_DIR="deployPkgs"
RELEASE_PATH=${TOP_PATH}/${RELEASE_ROOT_DIR}/${ARCH}

INSTALL_ROOT_PATH=${HOME}/${RELEASE_ROOT_DIR}/${ARCH}

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

config_func()
{

    pushd ${INSTALL_ROOT_PATH}/dnscrypt-proxy
    cp example-dnscrypt-proxy.toml dnscrypt-proxy.toml
	sed -i "s/^# server_names =.*/server_names = \['cisco', 'google', 'scaleway-fr', 'yandex', 'cloudflare'\]/" dnscrypt-proxy.toml
	sed -i "s/^listen_addresses =.*/listen_addresses = \['127.0.0.1:53'\]/" dnscrypt-proxy.toml
	sed -i "s/.*ignore_system_dns =.*/ignore_system_dns = true/" dnscrypt-proxy.toml
	sed -i "s/.*force_tcp =.*/force_tcp = true/" dnscrypt-proxy.toml
	sed -i "s/^timeout =.*/timeout = 3000/" dnscrypt-proxy.toml

    echoY "Downloading public-resolvers..."
    set +e
    ./dnscrypt-proxy
    set -e

    popd
}

install_service_func()
{
	sudo sed -i '/^static domain_name_servers=.*/d' /etc/dhcpcd.conf
	sudo sed -i '/^#static domain_name_servers=192.168.1.1$/a\static domain_name_servers=127.0.0.1' /etc/dhcpcd.conf

    pushd ${INSTALL_ROOT_PATH}/dnscrypt-proxy
    sudo ./dnscrypt-proxy -service install
    popd
}

uninstall_service_func()
{
    pushd ${INSTALL_ROOT_PATH}/dnscrypt-proxy
    sudo ./dnscrypt-proxy -service stop
    sudo ./dnscrypt-proxy -service uninstall
    popd

	sudo sed -i '/^static domain_name_servers=.*/d' /etc/dhcpcd.conf
}

usage_func()
{
    echo "./run.sh <cmd> <target>"
    echo ""
    echo "Supported cmd:"
    echo "[ get, build, release, init, install, uninstall ]"
    echo ""
    echo "Supported target:"
    echo "[ src, dns, service, installer ]"
}

echoG "TOP_PATH:${TOP_PATH}"

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
    build) echoY "Building ..."
        if [ $2 == "dns" ]
        then
            echo "Building dnscrypt-proxy ${LATEST_VERSION}.tar.gz..."
            build_latest_func
        elif [ $2 == "installer" ]
        then
            echo "Building dnscrypt-proxy docker image for deployment..."
            docker rmi -f rayruan/dnscrypt-proxy_${ARCH}:installer
            docker image prune
            docker build --rm -t rayruan/dnscrypt-proxy_${ARCH}:installer -f Dockerfile_installer.img ${DEST_PATH}
        else
            echoR "Unknow target:$2, only support building target [dns, installer]."
        fi
        ;;
    release) echoY "Releasing ..."
        if [ $2 == "dns" ]
        then
            echoY "Releasing dnscrypt-proxy to:${RELEASE_PATH}"

            mkdir -p ${RELEASE_PATH}
            rm -rf ${RELEASE_PATH}/dnscrypt-proxy

            pushd ${RELEASE_PATH}
            cp -a ${DEST_PATH} ./
            mv dnscrypt-proxy-${ARCH} dnscrypt-proxy
            popd
        else
            echoR "Unknow target:$2, only support releasing target [ dns ]."
        fi
        ;;
    init) echoY "Initiating configs of $2"
        if [ $2 == "dns" ]
        then
            config_func
        else
            echoR "Unknow target:$2, only support init targets [ dns ]."
        fi
        ;;
    install) echoY "Installing..."
        if [ $2 == "dns" ] 
        then
            echoY "Installing dnscrypt-proxy to your ${INSTALL_ROOT_PATH}..."
            sudo rm -rf ${INSTALL_ROOT_PATH}/dnscrypt-proxy
            mkdir -p ${INSTALL_ROOT_PATH}
            docker run --rm -it -v ${INSTALL_ROOT_PATH}:/target rayruan/dnscrypt-proxy_${ARCH}:installer 
	        USER_NAME=$(id -un)
	        GROUP_NAME=$(id -gn)
	        #echo "### ${USER_NAME}"
            sudo chown -hR ${USER_NAME}:${GROUP_NAME} ${INSTALL_ROOT_PATH}/dnscrypt-proxy
            cp dnsCryptSrc/public-resolvers.md* ${INSTALL_ROOT_PATH}/dnscrypt-proxy/

            config_func
	        cp ./dnsCryptSrc/public* ${INSTALL_ROOT_PATH}/dnscrypt-proxy/
        elif [ $2 == "service" ]
        then
            echoY "Installing dnscrypt-proxy service..."
            install_service_func
        else
            echoR "Unknow target:$2, only support installing targets [dns, service]."
        fi
        echoG "Install $2 finished."
        ;;
    uninstall) echoY "Uninstalling..."
        if [ $2 == "dns" ] 
        then
            echoY "Uinstalling dnscrypt-proxy service ..."
            sudo rm -rf ${INSTALL_ROOT_PATH}/dnscrypt-proxy
        elif [ $2 == "service" ]
        then
            echoY "Installing dnscrypt-proxy service..."
            uninstall_service_func
        else
            echoR "Unknow target:$2, only support uninstalling targets [dns, service]."
        fi
        echoG "Uninstall $2 finished."
        ;;
    *) echo "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

