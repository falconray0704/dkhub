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
USER_NAME=$(whoami)

SS_SRV_DEPLOY_PATH=${HOME}
SS_CLT_DEPLOY_PATH=${HOME}

deploy_ss_clt_func()
{
    TARGET=$1
    case ${TARGET} in
        dynamic)
            echo "Do not support dynamic link SS docker image..."
        ;;
        static) echo "Deploying static SS ss-redir ..."
#            docker rmi -f rayruan/ss_${ARCH}:${TARGET}
#            docker image prune
#            docker pull rayruan/ss_${ARCH}:${TARGET}

            sudo rm -rf ${SS_CLT_DEPLOY_PATH}/ssredir
            mkdir -p ${SS_CLT_DEPLOY_PATH}/ssredir

#            docker run --rm -v ${SS_CLT_DEPLOY_PATH}/ssredir:/ssredir rayruan/ss_installer_${ARCH}:${TARGET}
#            docker run --rm -it -v ${SS_CLT_DEPLOY_PATH}/ssredir:/ssredir --entrypoint "/bin/sh" rayruan/ss_installer_${ARCH}:${TARGET}
            docker run --rm -v ${SS_CLT_DEPLOY_PATH}/ssredir:/ssredir rayruan/ss_installer_${ARCH}:${TARGET}

            sudo chown -hR ${USER_NAME}:${USER_NAME} ${SS_CLT_DEPLOY_PATH}/ssredir

#                --entrypoint="/bin/cp /bin/ss-redir /ssredir/ && /bin/cp /etc/shadowsocks/*.service /ssredir/" \
#            docker run --rm -it -v ${SS_CLT_DEPLOY_PATH}/ssredir:/ssredir \
#                --entrypoint="/bin/sh" \
#                rayruan/ss_${ARCH}:${TARGET}
        ;;
        *) echo "Unsupported target: ${TARGET}."
        exit 1
    esac
}

deploy_ss_srv_func()
{
    TARGET=$1
    case ${TARGET} in
        dynamic)
            echo "Do not support dynamic link SS docker image..."
        ;;
        static) echo "Deploying static SS server ..."
            docker rmi -f rayruan/ss_${ARCH}:${TARGET}
            docker image prune
            docker pull rayruan/ss_${ARCH}:${TARGET}

            rm -rf ${SS_SRV_DEPLOY_PATH}/ssSrv
            cp -a ./setup/srv ${SS_SRV_DEPLOY_PATH}/ssSrv
            pushd ${SS_SRV_DEPLOY_PATH}/ssSrv
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

            cp ./3.Dockerfile_installer_${TARGET}.img ./3.Dockerfile_installer_${TARGET}.img.${ARCH}
            sed -i "s/ss_arch/ss_${ARCH}/g" ./3.Dockerfile_installer_${TARGET}.img.${ARCH}

            sudo cp ./scripts/3.installSS.sh ${PWD}/${BUILD_DIR}/dist/${ARCH}/bin/
            docker build --rm -t rayruan/ss_installer_${ARCH}:${TARGET} \
                -f ./3.Dockerfile_installer_${TARGET}.img.${ARCH} \
                ${PWD}/ssBuild/dist/${ARCH}/bin
        ;;
        *) echo "Unsupported target: ${TARGET}."
        exit 1
    esac
}

do_clean_ss_img_func()
{
    TARGET=$1
    ARCH=$(arch)
    docker rmi -f rayruan/ss_installer_${ARCH}:${TARGET}
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
                --entrypoint "/${SS_ROOT_DIR}/scripts/2.buildSS.sh" \
                rayruan/ss_builder_${ARCH}:${TARGET} build ${BUILD_DIR}
        ;;
        static) echo "Building static SS..."
            mkdir -p ${BUILD_DIR}
            docker run --rm -it \
                --dns=${DNS_IP} \
                --hostname "ssBuild" \
                -v ${PWD}:/${SS_ROOT_DIR} \
                --entrypoint "/${SS_ROOT_DIR}/scripts/2.buildStaticSS.sh" \
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
    echo "[ builder, cleanBuilder, build, img, cleanImg, deploySrv, deployClt ]"
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
    deploySrv) echo "Deploying SS server with docker image rayruan/ss_${ARCH}:$2 ..."
        deploy_ss_srv_func $2
        ;;
    deployClt) echo "Deploying SS clients..."
        deploy_ss_clt_func $2
        ;;
    *) echo "Unsupported cmd:$1."
        usage_func
        exit 1
esac

exit 0

