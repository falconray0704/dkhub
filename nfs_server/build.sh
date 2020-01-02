#!/bin/bash

set -e
#set -x

. ../libShell/echo_color.lib
. ../libShell/sysEnv.lib

BUILD_CONTEXT_DIR="build_context"

ARCH=$(arch)

setup_build_context_func()
{
    rm -rf ${BUILD_CONTEXT_DIR}
    mkdir -p ${BUILD_CONTEXT_DIR}
    
    cp ./entrypoint.sh ${BUILD_CONTEXT_DIR}/
}

build_target_func()
{
    setup_build_context_func

    do_clean_img_func
    docker build --rm -t rayruan/nfs-server_${ARCH} -f ./Dockerfile ${BUILD_CONTEXT_DIR}
}

do_clean_img_func()
{
	docker rmi -f rayruan/nfs-server_${ARCH}
	docker image prune
}

usage_func()
{
    echoY "./build.sh <target> <target version>"
    echo ""
    echoY "Supported target:"
    echo "[ build, clean ]"
    echo ""
    echoY "Supported target version:"
    echo "[ img ]"
}

[ $# -lt 2 ] && echoR "Invalid args count:$# " && usage_func && exit 1

case $1 in
    build) echoY "Building image rayruan/nfs-server_${ARCH} ..."
        build_target_func
        ;;
    clean) echoY "Removing image rayruan/nfs-server_${ARCH} ..."
        do_clean_img_func
        ;;
    *) echoR "Unsupported target:$1."
        usage_func
        exit 1
esac


exit 0

