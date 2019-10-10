#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x


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


[ $# -lt 1 ] && echo "Invalid args count:$# " && usage_func && exit 1

ARCH=$(arch)

case $1 in
    vlc) echo "Launching vlc container..."
        docker run --rm \
            -v ${HOME}:/home/vlc \
            -v /tmp/.X11-unix/:/tmp/.X11-unix/ \
            -v /dev/snd:/dev/snd \
            -v /dev/shm:/dev/shm \
            -v /var/run/dbus:/var/run/dbus \
            -e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
            -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
            --group-add $(getent group audio | cut -d: -f3) \
            -e DISPLAY rayruan/vlc_${ARCH}:run
        ;;
    bash) echo "Launching bash in vlc container..."
        docker run --rm -it \
            -v ${HOME}:/home/vlc \
            -v /tmp/.X11-unix/:/tmp/.X11-unix/ \
            -v /dev/snd:/dev/snd \
            -v /dev/shm:/dev/shm \
            -v /var/run/dbus:/var/run/dbus \
            -e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
            -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
            --group-add $(getent group audio | cut -d: -f3) \
            --entrypoint "/bin/bash" \
            -e DISPLAY rayruan/vlc_${ARCH}:run
        ;;
    rtspSrv) echo "Launching rtspSrv container..."
        docker run --rm -it \
            --hostname "rtspSrv" \
            --workdir="/rtspSrv" \
            -v ${HOME}:/home/vlc \
            -v /tmp/.X11-unix/:/tmp/.X11-unix/ \
            -v /dev/snd:/dev/snd \
            -v /dev/shm:/dev/shm \
            -v /var/run/dbus:/var/run/dbus \
            -e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
            -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
            --group-add $(getent group audio | cut -d: -f3) \
            -e DISPLAY rayruan/vlc_${ARCH}:rtspSrv
        ;;
    *) echo "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

