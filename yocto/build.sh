#!/bin/bash

set -e
#set -x


build_img_func()
{
    TARGET=$1
    TARGET_VER=$2
    ARCH=$(arch)

    cp ./Dockerfile_${TARGET}${TARGET_VER}.img ./Dockerfile_${TARGET}${TARGET_VER}.img.${ARCH} 

    if [ ${TARGET} == basic ]; then
        sed -i "s/ubt${TARGET_VER}/ubt${TARGET_VER}_${ARCH}/" ./Dockerfile_${TARGET}${TARGET_VER}.img.${ARCH}
#        docker build --rm -t rayruan/yocto_${ARCH}:${TARGET}${TARGET_VER} -f ./Dockerfile_${TARGET}${TARGET_VER}.img.${ARCH} .
    elif [ ${TARGET} == build ]; then
        sed -i "s/yocto/yocto_${ARCH}/" ./Dockerfile_${TARGET}${TARGET_VER}.img.${ARCH}
    else
            echo "Unsupport target:${TARGET} for image building."
            exit 1
    fi

    docker build --rm -t rayruan/yocto_${ARCH}:${TARGET}${TARGET_VER} \
        --build-arg "group=${USER}" \
        --build-arg "gid=$(id -u)" \
        --build-arg "user=${USER}" \
        --build-arg	"uid=$(id -g)" \
        -f ./Dockerfile_${TARGET}${TARGET_VER}.img.${ARCH} .
}

build_target_func()
{
    TARGET=$1
    TARGET_VER=$2
    case $2 in
        1404|1604|1804)
        do_clean_img_func ${TARGET} ${TARGET_VER}
        build_img_func ${TARGET} ${TARGET_VER}
        ;;
        *) echo "Unsupported version:$2."
        exit 1
    esac
}

do_clean_img_func()
{
    TARGET=$1
    TARGET_VER=$2
    ARCH=$(arch)
	docker rmi -f rayruan/yocto_${ARCH}:${TARGET}${TARGET_VER}
	docker image prune
}

ARCH=$(arch)

usage_func()
{
    echo "./build.sh <target> <target version>"
    echo ""
    echo "Supported target:"
    echo "[ basic, build ]"
    echo ""
    echo "Supported target version:"
    echo "[ 1404, 1604, 1804 ]"
}

[ $# -lt 2 ] && echo "Invalid args count:$# " && usage_func && exit 1

case $1 in
    basic|build) echo "Building image rayruan/yocto_${ARCH}:$1$2 ..."
        build_target_func $1 $2
        ;;
    cleanBasic) echo "Removing image rayruan/yocto_${ARCH}:basic$2 ..."
        do_clean_img_func basic $2
        ;;
    cleanBuild) echo "Removing image rayruan/yocto_${ARCH}:build$2 ..."
        do_clean_img_func build $2
        ;;
    *) echo "Unsupported target:$1."
        usage_func
        exit 1
esac


exit 0

