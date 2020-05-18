#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x

. ../libShell/echo_color.lib

build_img_func()
{
    TARGET=$1
    ARCH=$(arch)

#    cp ./Dockerfile_${TARGET}.img ./Dockerfile_${TARGET}.img.${ARCH} 


	docker build --rm -t rayruan/${TARGET} -f ./Dockerfile .

}

build_target_func()
{
    TARGET=$1
    case ${TARGET} in
        ffserver)
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
	docker rmi -f rayruan/${TARGET}
	docker image prune
}

usage_func()
{
    echo "./build.sh <cmd> <image tag>"
    echo ""
    echo "Supported cmd:"
    echo "[ build, clean, streamPush ]"
    echo ""
    echo "Supported image tags:"
    echo "[ ffserver ]"
}


[ $# -lt 2 ] && echo "Invalid args count:$# " && usage_func && exit 1

ARCH=$(arch)

case $1 in
    build) echo "Building image rayruan/$2 ..."
        build_target_func $2
        ;;
    clean) echo "Removing image rayruan/$2 ..."
        do_clean_img_func $2
        ;;
    streamPush) echo "Pushing video streaming..."
        echoY "Playing url: rtsp://<IP>/video.mp4"
        docker-compose exec ffserver ffmpeg -re -i data/video.mp4 http://localhost:8090/feed.ffm
        ;;
    *) echo "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

