#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x


build_img_func()
{
    TARGET=$1
    ARCH=$(arch)

    cp ./Dockerfile_${TARGET}.img ./Dockerfile_${TARGET}.img.${ARCH} 

    if [ ${TARGET} == install ]; then
        echo "Building image..."
    elif [ ${TARGET} == run -o ${TARGET} == rtspSrv ]; then
        sed -i "s/vlc_arch/vlc_${ARCH}/" ./Dockerfile_${TARGET}${TARGET_VER}.img.${ARCH}
    else
            echo "Unsupport target:${TARGET} for image building."
            exit 1
    fi

	docker build --rm -t rayruan/vlc_${ARCH}:${TARGET} -f ./Dockerfile_${TARGET}.img.${ARCH} .

}

build_target_func()
{
    TARGET=$1
    case ${TARGET} in
        install|run|rtspSrv)
        do_clean_img_func ${TARGET}
        build_img_func ${TARGET}
        ;;
        *) echo "Unsupported target: ${TARGET}."
        exit 1
    esac
}

do_clean_img_func()
{
    TARGET=$1
    ARCH=$(arch)
	docker rmi -f rayruan/vlc_${ARCH}:${TARGET}
	docker image prune
}

usage_func()
{
    echo "./build.sh <cmd> <image tag>"
    echo ""
    echo "Supported cmd:"
    echo "[ build, clean ]"
    echo ""
    echo "Supported image tags:"
    echo "[ install, run, rtspSrv ]"
}


[ $# -lt 2 ] && echo "Invalid args count:$# " && usage_func && exit 1

ARCH=$(arch)

case $1 in
    build) echo "Building image rayruan/vlc_${ARCH}:$2 ..."
        build_target_func $2
        ;;
    clean) echo "Removing image rayruan/vlc_${ARCH}:$2 ..."
        do_clean_img_func $2
        ;;
    *) echo "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

