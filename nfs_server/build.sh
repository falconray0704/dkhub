#!/bin/bash

set -e
#set -x

. ../libShell/echo_color.lib
. ../libShell/sysEnv.lib

ARCH=$(arch)

build_target_func()
{
    do_clean_img_func
    docker build --rm -t rayruan/nfs-server_${ARCH} -f ./Dockerfile ./configs
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

