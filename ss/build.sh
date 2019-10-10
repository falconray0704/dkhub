#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x

ssRootDir=ssRoot
buildDir=ssBuild
LOCAL_ARCH=$(arch)

builder_img_func()
{
    TARGET=$1
    ARCH=$(arch)

    cp ./1.Dockerfile_builder_${TARGET}.img ./1.Dockerfile_builder_${TARGET}.img.${ARCH} 

    if [ ${TARGET} == dynamic -o ${TARGET} == static ]; then
        echo "Building image..."
        sed -i "s/ubt1604_arch/ubt1604_${ARCH}/" ./1.Dockerfile_builder_${TARGET}.img.${ARCH}
        docker build --rm -t rayruan/ss_builder_${ARCH}:${TARGET} -f ./1.Dockerfile_builder_${TARGET}.img.${ARCH} .
    else
            echo "Unsupport target:${TARGET} for image building."
            exit 1
    fi

}

builder_target_func()
{
    TARGET=$1
    case ${TARGET} in
        dynamic|static)
        do_builder_clean_img_func ${TARGET}
        builder_img_func ${TARGET}
        ;;
        *) echo "Unsupported target: ${TARGET}."
        exit 1
    esac
}

do_builder_clean_img_func()
{
    TARGET=$1
    ARCH=$(arch)
	docker rmi -f rayruan/ss_builder_${ARCH}:${TARGET}
	docker image prune
}

usage_func()
{
    echo "./build.sh <cmd> <image tag>"
    echo ""
    echo "Supported cmd:"
    echo "[ builder, cleanBuilder ]"
    echo ""
    echo "Supported image tags:"
    echo "[ dynamic, static ]"
}


[ $# -lt 2 ] && echo "Invalid args count:$# " && usage_func && exit 1

ARCH=$(arch)

case $1 in
    builder) echo "Building SS builder rayruan/ss_builder_${ARCH}:$2 ..."
        builder_target_func $2
        ;;
    cleanBuilder) echo "Removing SS builder rayruan/ss_builder_${ARCH}:$2 ..."
        do_builder_clean_img_func $2
        ;;
    *) echo "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

