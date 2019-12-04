#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x

. ../libShell/echo_color.lib

ARCH=$(arch)
USER_NAME=$(id -un)
GROUP_NAME=$(id -gn)

DNS_IP="192.168.11.1"
SS_ROOT_DIR=ssRoot
BUILD_DIR=ssBuild

TOP_PATH=$(dirname ${PWD})

RELEASE_ROOT_DIR="deployPkgs"
RELEASE_PATH=${TOP_PATH}/${RELEASE_ROOT_DIR}/${ARCH}

SS_CLT_DEPLOY_PATH=${HOME}/${RELEASE_ROOT_DIR}


deploy_ss_srv_func()
{
    TARGET=$1
    case ${TARGET} in
        dynamic)
            echoR "Do not support dynamic link SS docker image..."
        ;;
        static) echoY "Deploying static SS server ..."
            docker rmi -f rayruan/ss_${ARCH}:${TARGET}
            docker image prune
            docker pull rayruan/ss_${ARCH}:${TARGET}
        ;;
        *) echo "Unsupported target: ${TARGET}."
        exit 1
    esac
}

build_ss_img_func()
{
    TARGET=$1
    case ${TARGET} in
        dynamic)
            echoR "Do not support dynamic link SS docker image..."
        ;;
        static) echoY "Building static SS image..."
            do_clean_ss_img_func ${TARGET}
            sudo cp ./configs/config.json ${PWD}/${BUILD_DIR}/dist/${ARCH}/bin/
            sudo cp ./configs/*.service ${PWD}/${BUILD_DIR}/dist/${ARCH}/bin/
            docker build --rm -t rayruan/ss_${ARCH}:${TARGET} -f ./2.Dockerfile_ss_${TARGET}.img ${PWD}/ssBuild/dist/${ARCH}/bin
        ;;
        *) echoR "Unsupported target: ${TARGET}."
        exit 1
    esac
}

relPkgs_static_ss_func()
{
    TARGET=$1
    case ${TARGET} in
        dynamic)
            echoR "Do not support dynamic link SS relPkgs..."
        ;;
        static) echoY "Releasing static SS relPkgs..."
            echoY "Releasing static SS to:${RELEASE_PATH}"
            mkdir -p ${RELEASE_PATH}/ss
            rm -rf ${RELEASE_PATH}/ss/*

            cp ${PWD}/${BUILD_DIR}/dist/${ARCH}/bin/ss-* ${RELEASE_PATH}/ss/
            cp ./configs/*.service ${RELEASE_PATH}/ss/
            cp ./configs/config.json ${RELEASE_PATH}/ss/
        ;;
        *) echoR "Unsupported target: ${TARGET}."
        exit 1
    esac
}


do_clean_ss_img_func()
{
    TARGET=$1
    ARCH=$(arch)
	docker rmi -f rayruan/ss_${ARCH}:${TARGET}
	docker image prune
}

build_ss_target_func()
{
    TARGET=$1
    case ${TARGET} in
        dynamic) echoY "Building dynamic SS..."
            mkdir -p ${BUILD_DIR}
            docker run --rm -it \
                --dns=${DNS_IP} \
                --hostname "ssBuild" \
                -v ${PWD}:/${SS_ROOT_DIR} \
                --entrypoint "/${SS_ROOT_DIR}/scripts/2.buildSS.sh" \
                rayruan/ss_builder_${ARCH}:${TARGET} build ${BUILD_DIR}
        ;;
        static) echoY "Building static SS..."
            mkdir -p ${BUILD_DIR}
            docker run --rm -it \
                --dns=${DNS_IP} \
                --hostname "ssBuild" \
                -v ${PWD}:/${SS_ROOT_DIR} \
                --entrypoint "/${SS_ROOT_DIR}/scripts/2.buildStaticSS.sh" \
                rayruan/ss_builder_${ARCH}:${TARGET} ${ARCH} ${BUILD_DIR}

        ;;
        *) echoR "Unsupported target: ${TARGET}."
        exit 1
    esac
}


builder_img_func()
{
    TARGET=$1
    ARCH=$(arch)

    cp ./1.Dockerfile_builder_${TARGET}.img ./1.Dockerfile_builder_${TARGET}.img.${ARCH} 

    if [ ${TARGET} == dynamic -o ${TARGET} == static ]; then
        echoY "Building image..."
        sed -i "s/ubt1604_arch/ubt1604_${ARCH}/" ./1.Dockerfile_builder_${TARGET}.img.${ARCH}
        docker build --rm -t rayruan/ss_builder_${ARCH}:${TARGET} -f ./1.Dockerfile_builder_${TARGET}.img.${ARCH} .
    else
        echoR "Unsupport target:${TARGET} for image building."
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
        *) echoR "Unsupported target: ${TARGET}."
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
    echoY "./run.sh <cmd> <image tag>"
    echo ""
    echoY "Supported cmd:"
    echo "[ builder, cleanBuilder, build, relPkgs, buildImg, cleanImg, pullImg ]"
    echo ""
    echoY "Supported image tags:"
    echo "[ dynamic, static ]"
}


[ $# -lt 2 ] && echoR "Invalid args count:$# " && usage_func && exit 1

case $1 in
    builder) echoY "Building SS builder rayruan/ss_builder_${ARCH}:$2 ..."
        builder_target_func $2
        ;;
    cleanBuilder) echoY "Removing SS builder rayruan/ss_builder_${ARCH}:$2 ..."
        do_builder_clean_img_func $2
        ;;
    build) echoY "Building SS ..."
        build_ss_target_func $2
        ;;
    relPkgs) echoY "Release SS ..."
        relPkgs_static_ss_func $2
        ;;
    buildImg) echoY "Building SS image rayruan/ss_${ARCH}:$2 ..."
        build_ss_img_func $2
        ;;
    cleanImg) echoY "Removing SS image rayruan/ss_${ARCH}:$2 ..."
        do_clean_ss_img_func $2
        ;;
    pullImg) echoY "Pulling SS docker image rayruan/ss_${ARCH}:$2 ..."
        deploy_ss_srv_func $2
        ;;
    *) echoR "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

