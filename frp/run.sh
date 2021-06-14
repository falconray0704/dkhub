#!/bin/bash

# refer to:
# https://www.cnblogs.com/kevingrace/p/11753294.html

#set -o
set -e
#set -x

. ../libShell/echo_color.lib

source .env_host

RELEASE_BIN_FILE_NAME="frp_${VERSION_RELEASE_FRP}_${OS_TARGET}_${ARCH_TARGET}.tar.gz" 
RELEASE_SRC_FILE_NAME="v${VERSION_RELEASE_FRP}.tar.gz" 

SUPPORTED_CMD="get,build"
SUPPORTED_TARGETS="releaseBin,releaseSrc,frpsDockerImg"

EXEC_CMD=""
EXEC_ITEMS_LIST=""

#EXEC_CMD_TARGET=""

clean_docker_image()
{
    docker_target=$1

    set +e
	docker rmi -f ${docker_target}
	docker image prune
    set -e
}

exec_items_iterator()
{
    exec_cmd=$1
    exec_items_list=$2

    exec_items_num=`echo ${exec_items_list}|awk -F"," '{print NF}'`
    for ((i=1;i<=${exec_items_num};i++)); do
        eval item='`echo ${exec_items_list}|awk -F, "{ print $"$i" }"`'
        exec_name=${exec_cmd}_${item}
        ${exec_name} ${exec_cmd} ${item}
    done
}


get_items_func()
{
    exec_cmd=$1
    exec_items_list=$2

    exec_items_iterator ${exec_cmd} ${exec_items_list} 
}

build_items_func()
{
    exec_cmd=$1
    exec_items_list=$2

    exec_items_iterator ${exec_cmd} ${exec_items_list} 
}

mkdirs_get_releaseBin()
{
    exec_cmd=$1
    exec_item=$2
    echoY "Preparing running dirs for ${exec_cmd} ${exec_item} ..."
    if [ ! -d ${DOWNLOAD_DIR} ]
    then
    mkdir -p ${DOWNLOAD_DIR}
    fi
    echoG "Preparing running dirs for ${exec_cmd} ${exec_item} success!"
}

get_releaseBin()
{
    exec_cmd=$1
    exec_item=$2

    echoY "Downloading ${VERSION_RELEASE_FRP} frp release ${RELEASE_BIN_FILE_NAME} ..."

    mkdirs_get_releaseBin ${exec_cmd} ${exec_item}
    
    pushd ${DOWNLOAD_DIR}
    if [ -f ${RELEASE_BIN_FILE_NAME} ]
    then
        set +e
        tar -zxf ${RELEASE_BIN_FILE_NAME}
        if [ $? -ne 0 ]
        then
            rm ${RELEASE_BIN_FILE_NAME}
            wget -c https://github.com/fatedier/frp/releases/download/v${VERSION_RELEASE_FRP}/${RELEASE_BIN_FILE_NAME}
        fi

        echoY "File ${RELEASE_BIN_FILE_NAME} already exsisted!"
        set -e
    else
        wget -c https://github.com/fatedier/frp/releases/download/v${VERSION_RELEASE_FRP}/${RELEASE_BIN_FILE_NAME}
    fi
    popd

    echoG "Downloading ${VERSION_RELEASE_FRP} frp success!"
    ls -al ${DOWNLOAD_DIR}
}

get_releaseSrc()
{
    exec_cmd=$1
    exec_item=$2

    echoY "Downloading ${VERSION_RELEASE_FRP} frp release source ${RELEASE_SRC_FILE_NAME} ..."

    mkdirs_get_releaseBin ${exec_cmd} ${exec_item}
    
    pushd ${DOWNLOAD_DIR}
    if [ -f ${RELEASE_SRC_FILE_NAME} ]
    then
        set +e
        tar -zxf ${RELEASE_SRC_FILE_NAME} -O > /dev/null 
        if [ $? -ne 0 ]
        then
            rm ${RELEASE_SRC_FILE_NAME}
            wget -c https://github.com/fatedier/frp/archive/refs/tags/${RELEASE_SRC_FILE_NAME}
        fi
        set -e
    else
        wget -c https://github.com/fatedier/frp/archive/refs/tags/${RELEASE_SRC_FILE_NAME}
    fi
    popd

    echoG "Downloading ${VERSION_RELEASE_FRP} frp source success!"
    ls -al ${DOWNLOAD_DIR}
}

build_frpsDockerImg()
{
    exec_cmd=$1
    exec_item=$2

    pushd ${DOWNLOAD_DIR}
    rm -rf ${RELEASE_BIN_DIR}
    tar -zxf ${RELEASE_BIN_FILE_NAME}
    popd

    DOCKER_TARGET=${FRP_DOCKER_REPO}/${FRPS_DOCKER_NAME}:${FRPS_DOCKER_TAG} 

    echoY "Removing docker image ${DOCKER_TARGET} ..."

    clean_docker_image ${DOCKER_TARGET}
    #sudo cp ./configs/config.json ${PWD}/${BUILD_DIR}/dist/${ARCH}/bin/
    #sudo cp ./configs/*.service ${PWD}/${BUILD_DIR}/dist/${ARCH}/bin/

    echoY "Building docker image ${DOCKER_TARGET} ..."
    docker build --rm -t ${DOCKER_TARGET} -f ./Dockerfile-for-frps ${RELEASE_BIN_PATH}

    if [ $? -eq 0 ]
    then
        echoY "Building docker image ${DOCKER_TARGET} success!"
    else
        echoR "Building docker image ${DOCKER_TARGET} fail!"
        clean_docker_image ${DOCKER_TARGET}
        exit 1
    fi
}

usage_func()
{

    echoY "Usage:"
    echoY './run.sh -c <cmd> -l "<item list>"'
    echoY "eg:\n./run.sh -c get -l \"releaseBin,releaseSrc\""
    echoY "eg:\n./run.sh -c build -l \"frpsDockerImg\""

    echoC "Supported cmd:"
    echo "${SUPPORTED_CMD}"
    echoC "Supported items:"
    echo "${SUPPORTED_TARGETS}"
    
}


no_args="true"
while getopts "c:l:" opts
do
    case $opts in
        c)
              # cmd
              EXEC_CMD=$OPTARG
              ;;
        l)
              # items list
              EXEC_ITEMS_LIST=$OPTARG
              ;;
        :)
            echo "The option -$OPTARG requires an argument."
            exit 1
            ;;
        ?)
            echo "Invalid option: -$OPTARG"
            usage_func
            exit 2
            ;;
        *)    #unknown error?
              echoR "unkonw error."
              usage_func
              exit 1
              ;;
    esac
    no_args="false"
done

[[ "$no_args" == "true" ]] && { usage_func; exit 1; }
#[ $# -lt 1 ] && echoR "Invalid args count:$# " && usage_func && exit 1


case ${EXEC_CMD} in
    "get")
        get_items_func ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "build")
        build_items_func ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "*")
        echoR "Unsupport cmd:${EXEC_CMD}"
        ;;
esac


 
