#!/bin/bash

# refer to:
# https://hub.docker.com/r/alexandreoda/vlc
# docker pull alexandreoda/vlc

set -e
#set -x

DNS_IP="192.168.11.1"
SS_ROOT_DIR=ssRoot
BUILD_DIR=ssBuild
ARCH=$(arch)

deploy_ss_img_func()
{
    TARGET=$1
    case ${TARGET} in
        dynamic)
            echo "Do not support dynamic link SS docker image..."
        ;;
        static) echo "Deploying static SS image..."
            docker rmi -f rayruan/ss_${ARCH}:${TARGET}
            docker image prune
            docker pull rayruan/ss_${ARCH}:${TARGET}

            rm -rf ~/ssSrv
            cp -a ./setup/srv ~/ssSrv
            pushd ~/ssSrv
            sed -i "s/ss_arch/ss_${ARCH}/" ./docker-compose.yml
            popd
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
            echo "Do not support dynamic link SS docker image..."
        ;;
        static) echo "Building static SS image..."
            do_clean_ss_img_func ${TARGET}
            docker build --rm -t rayruan/ss_${ARCH}:${TARGET} -f ./2.Dockerfile_ss_${TARGET}.img ${PWD}/ssBuild/dist/${ARCH}/bin
        ;;
        *) echo "Unsupported target: ${TARGET}."
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
        dynamic) echo "Building dynamic SS..."
            mkdir -p ${BUILD_DIR}
            docker run --rm -it \
		--dns=${DNS_IP} \
                --hostname "ssBuild" \
                -v ${PWD}:/${SS_ROOT_DIR} \
                --entrypoint "/ssRoot/scripts/2.buildSS.sh" \
                rayruan/ss_builder_${ARCH}:${TARGET} build ${BUILD_DIR}
        ;;
        static) echo "Building static SS..."
            mkdir -p ${BUILD_DIR}
            docker run --rm -it \
		--dns=${DNS_IP} \
                --hostname "ssBuild" \
                -v ${PWD}:/${SS_ROOT_DIR} \
                --entrypoint "/ssRoot/scripts/2.buildStaticSS.sh" \
                rayruan/ss_builder_${ARCH}:${TARGET} ${ARCH} ${BUILD_DIR}
        ;;
        *) echo "Unsupported target: ${TARGET}."
        exit 1
    esac
}


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
    echo "[ builder, cleanBuilder, build, img, cleanImg, deployImg ]"
    echo ""
    echo "Supported image tags:"
    echo "[ dynamic, static ]"
}


[ $# -lt 2 ] && echo "Invalid args count:$# " && usage_func && exit 1

case $1 in
    builder) echo "Building SS builder rayruan/ss_builder_${ARCH}:$2 ..."
        builder_target_func $2
        ;;
    cleanBuilder) echo "Removing SS builder rayruan/ss_builder_${ARCH}:$2 ..."
        do_builder_clean_img_func $2
        ;;
    build) echo "Building dynamic SS from github ..."
        build_ss_target_func $2
        ;;
    img) echo "Building SS image rayruan/ss_${ARCH}:$2 ..."
        build_ss_img_func $2
        ;;
    cleanImg) echo "Removing SS image rayruan/ss_${ARCH}:$2 ..."
        do_clean_ss_img_func $2
        ;;
    deployImg) echo "Deploying SS docker image rayruan/ss_${ARCH}:$2 ..."
        deploy_ss_img_func $2
        ;;
    *) echo "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

