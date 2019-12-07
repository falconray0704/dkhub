#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x

. ../libShell/echo_color.lib

DEPLOY_PKGS_DIR="deployPkgs"

LAST_VERSION="1.0.0"
NEW_VERSION="1.0.1"

TOP_DIR=$(dirname ${PWD})

BUILD_ROOT_DIR=${PWD}/buildRoot


pull_pre_release_pkgs_func()
{

    echoY "Fetching release of relpkgs:${LAST_VERSION} ..."
    sudo rm -rf ${BUILD_ROOT_DIR}
    mkdir -p ${BUILD_ROOT_DIR}

    set +e
    docker run --rm -it -v ${BUILD_ROOT_DIR}:/target rayruan/relpkgs:${LAST_VERSION}
    set -e

    USER_NAME=$(id -un)
    GROUP_NAME=$(id -gn)
    #echo "### ${USER_NAME}"
    sudo chown -hR ${USER_NAME}:${GROUP_NAME} ${BUILD_ROOT_DIR}
    echoY "Fetching release of relpkgs:${LAST_VERSION} finished."
    
}

build_relPkgs_func()
{
    docker rmi -f rayruan/relpkgs:${NEW_VERSION}
    docker image prune

    echoY "Updating ${DEPLOY_PKGS_DIR} ..."
    cp -a ${TOP_DIR}/${DEPLOY_PKGS_DIR} ${BUILD_ROOT_DIR}/

    docker build --rm -t rayruan/relpkgs:${NEW_VERSION} -f Dockerfile.img ${BUILD_ROOT_DIR}

}

install_relPkgs2pi_func() 
{
    sdcard=$1
    fsBoot=/mnt/piBoot
    fsRoot=/mnt/piRoot
    installPath=${fsRoot}

    set +o errexit
    sudo umount -f ${sdcard}*
    set -o errexit

    sudo mkdir -p ${fsBoot}
    sudo mkdir -p ${fsRoot}

    sudo mount ${sdcard}1 ${fsBoot}
    sudo mount ${sdcard}2 ${fsRoot}

    sudo cp -a ./v${NEW_VERSION}/deployPkgs ${fsRoot}/home/
    sync

    set +o errexit
    sudo umount -f ${sdcard}*
    set -o errexit

}

deploy_server_func()
{
    sudo cp -a ./v${NEW_VERSION}/deployPkgs ${HOME}/
}

usage_func()
{
    echoY "./build.sh <cmd> <target> [args]"
    echo ""
    echoY "Supported cmd:"
    echo "[ pull, build, deploy ]"
    echo ""
    echoY "Supported target:"
    echo "[ prerel, relpkgs, pi, server ]"
}

echoG "TOP_DIR:${TOP_DIR}"

[ $# -lt 2 ] && echoR "Invalid args count:$# " && usage_func && exit 1

case $1 in
    build) echoY "Building relPkgs ..."
        if [ $2 == "relpkgs" ]
        then
            echoY "Building rayruan/relpkgs:${NEW_VERSION} ..."
            build_relPkgs_func
        else
            echoR "Unknow target:$2, only support building target [ relPkgs ]."
        fi
        ;;
    pull) echoY "Pulling ..."
        if [ $2 == "relPkgs" ]
        then
            echoY "Pulling relPkgs:${NEW_VERSION} to v${NEW_VERSION}..."
            sudo rm -rf v${NEW_VERSION}
            mkdir -p v${NEW_VERSION}
            docker run --rm -v ${PWD}/v${NEW_VERSION}:/target rayruan/relpkgs:${NEW_VERSION}
            sudo chown -hR $(id -un):$(id -gn) v${NEW_VERSION}
            echoG "Pulling relPkgs:${NEW_VERSION} to v${NEW_VERSION} finished."
        elif [ $2 == "prerel" ]
        then
            echoY "Pulling pre-release ..."
            pull_pre_release_pkgs_func
        else
            echoR "Unknow target:$2, only support pulling target [ relPkgs, prerel ]."
        fi
        ;;
    deploy) echoY "Deploying relPkgs to $2..."
        if [ $2 == "pi" ]
        then
            echoY "Installing relpkgs:${NEW_VERSION} ..."
            if [ $# -lt 3 ]
            then
                echoR "Usage of command $1: ./run.sh $1 $2 /dev/disk"
            else
                install_relPkgs2pi_func $3
            fi
        elif [ $2 == "server" ]
        then
            deploy_server_func
        else
            echoR "Unknow target:$2, only support installing target [ pi, server ]."
        fi
        ;;
    *) echoR "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

