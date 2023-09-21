#!/bin/bash

set -o nounset
set -o errexit
# trace each command execute, same as `bash -v myscripts.sh`
#set -o verbose
# trace each command execute with attachment infomations, same as `bash -x myscripts.sh`
#set -o xtrace

#set -o
set -e
#set -x

export LIBSHELL_ROOT_PATH=${PWD}/../libShell

. ${LIBSHELL_ROOT_PATH}/echo_color.lib
. ${LIBSHELL_ROOT_PATH}/utils.lib
. ${LIBSHELL_ROOT_PATH}/sysEnv.lib
# Checking environment setup symbolic link and its file exists
if [ -L ".env_setup" ] && [ -f ".env_setup" ]
then
#    echoG "Symbolic .env_setup exists."
    . ./.env_setup
else
    echoR "Setup environment informations by making .env_setup symbolic link to specific .env_setup_xxx file(eg: .env_setup_amd64_ubt_1804) ."
    exit 1
fi

. ../utils/utils.lib
. ./.docker_vars

SUPPORTED_CMD="get,clean,build"
SUPPORTED_TARGETS="releaseBin,releaseSrc,releaseBinImgSocat,releaseBinImg,srcBinImgSocat,srcBinImg,ImgSocat,Img"

EXEC_CMD=""
EXEC_ITEMS_LIST=""

RELEASE_BIN_FILE_NAME="frp_${VERSION_RELEASE_FRP}_${OSENV_DOCKER_OS}_${OSENV_DOCKER_CPU_ARCH}.tar.gz" 
RELEASE_SRC_FILE_NAME="v${VERSION_RELEASE_FRP}.tar.gz" 

DOCKER_FILE_NAME="Dockerfile"

mkdirs_get_releaseBin()
{
    local exec_cmd=$1
    local exec_item=$2
    echoY "Preparing running dirs for ${exec_cmd} ${exec_item} ..."
    if [ ! -d ${DOWNLOAD_DIR} ]
    then
    mkdir -p ${DOWNLOAD_DIR}
    fi
    echoG "Preparing running dirs for ${exec_cmd} ${exec_item} success!"
}

get_releaseBin()
{
    local exec_cmd=$1
    local exec_item=$2

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
    local exec_cmd=$1
    local exec_item=$2

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

clean_Img()
{
    local TARGET_USER_NAME=${DOCKER_USER_NAME}
    local TARGET_NAME=${FRP_DOCKER_NAME}
    local TARGET_ARCH=${OSENV_DOCKER_CPU_ARCH}

    local DOCKER_TARGET=${TARGET_USER_NAME}/${TARGET_ARCH}_${FRP_DOCKER_NAME}:${VERSION_RELEASE_FRP} 

    clean_docker_image ${DOCKER_TARGET}
}

build_releaseBinImg()
{
    local exec_cmd=$1
    local exec_item=$2

    pushd ${DOWNLOAD_DIR}
    rm -rf ${RELEASE_BIN_DIR}
    tar -zxf ${RELEASE_BIN_FILE_NAME}
    popd

    local TARGET_USER_NAME=${DOCKER_USER_NAME}
    local TARGET_NAME=${FRP_DOCKER_NAME}
    local TARGET_ARCH=${OSENV_DOCKER_CPU_ARCH}

    local DOCKER_TARGET=${TARGET_USER_NAME}/${TARGET_ARCH}_${FRP_DOCKER_NAME}:${VERSION_RELEASE_FRP} 

    echoY "Removing docker image ${DOCKER_TARGET} ..."

    clean_docker_image ${DOCKER_TARGET}
    #sudo cp ./configs/config.json ${PWD}/${BUILD_DIR}/dist/${ARCH}/bin/
    #sudo cp ./configs/*.service ${PWD}/${BUILD_DIR}/dist/${ARCH}/bin/

    echoY "Building docker image ${DOCKER_TARGET} ..."
    docker build --rm -t ${DOCKER_TARGET} -f ./${DOCKER_FILE_NAME} ${RELEASE_BIN_PATH}

    if [ $? -eq 0 ]
    then
        echoY "Building docker image ${DOCKER_TARGET} success!"
    else
        echoR "Building docker image ${DOCKER_TARGET} fail!"
        clean_docker_image ${DOCKER_TARGET}
        exit 1
    fi
}

build_releaseSrc()
{
    local exec_cmd=$1
    local exec_item=$2

    echoY "Building frp ${VERSION_RELEASE_FRP} from source ${RELEASE_SRC_FILE_NAME} ..."

    pushd ${DOWNLOAD_DIR}
    if [ -f ${RELEASE_SRC_FILE_NAME} ]
    then
        set +e
        rm -rf "frp-${VERSION_RELEASE_FRP}"
        tar -zxf ${RELEASE_SRC_FILE_NAME}
        if [ $? -eq 0 ]
        then
            pushd frp-${VERSION_RELEASE_FRP}
            ./package.sh
            popd
        fi
        set -e
    else
        echoR "Can not find ${RELEASE_SRC_FILE_NAME}, please get the source first!"
        exit 1
    fi
    popd

    if [ $? -eq 0 ]
    then
        echoG "Downloading ${VERSION_RELEASE_FRP} frp source success!"
        ls -al ${DOWNLOAD_DIR}/frp-${VERSION_RELEASE_FRP}/bin
    fi

}

build_srcBinImg()
{
    local exec_cmd=$1
    local exec_item=$2

    if [ ! -f ${DOWNLOAD_DIR}/frp-${VERSION_RELEASE_FRP}/bin/frps ]
    then
        echoR "Can not find ${DOWNLOAD_DIR}/frp-${VERSION_RELEASE_FRP}/bin/frps, build it from source first!"
        exit 1
    fi

    local TARGET_USER_NAME=${DOCKER_USER_NAME}
    local TARGET_NAME=${FRP_DOCKER_NAME}
    local TARGET_ARCH=${OSENV_DOCKER_CPU_ARCH}

    local DOCKER_TARGET=${TARGET_USER_NAME}/${TARGET_ARCH}_${FRP_DOCKER_NAME}:${VERSION_RELEASE_FRP} 

    echoY "Removing docker image ${DOCKER_TARGET} ..."

    clean_docker_image ${DOCKER_TARGET}
    #sudo cp ./configs/config.json ${PWD}/${BUILD_DIR}/dist/${ARCH}/bin/
    #sudo cp ./configs/*.service ${PWD}/${BUILD_DIR}/dist/${ARCH}/bin/

    echoY "Building docker image ${DOCKER_TARGET} ..."
    rm -rf ${DOWNLOAD_DIR}/frp-${VERSION_RELEASE_FRP}/img_bin
    cp -a ${DOWNLOAD_DIR}/frp-${VERSION_RELEASE_FRP}/bin ${DOWNLOAD_DIR}/frp-${VERSION_RELEASE_FRP}/img_bin
    cp -a ${DOWNLOAD_DIR}/frp-${VERSION_RELEASE_FRP}/conf/*.ini ${DOWNLOAD_DIR}/frp-${VERSION_RELEASE_FRP}/img_bin/
    docker build --rm -t ${DOCKER_TARGET} -f ./${DOCKER_FILE_NAME} ${DOWNLOAD_DIR}/frp-${VERSION_RELEASE_FRP}/img_bin

    if [ $? -eq 0 ]
    then
        echoY "Building docker image ${DOCKER_TARGET} success!"
    else
        echoR "Building docker image ${DOCKER_TARGET} fail!"
        clean_docker_image ${DOCKER_TARGET}
        exit 1
    fi
}

clean_ImgSocat()
{
	FRP_DOCKER_NAME="${FRP_DOCKER_NAME}_socat"
    clean_Img
}

build_srcBinImgSocat()
{
    local exec_cmd=$1
    local exec_item=$2

	FRP_DOCKER_NAME="${FRP_DOCKER_NAME}_socat"
	DOCKER_FILE_NAME="Dockerfile_socat"
	build_srcBinImg ${exec_cmd} ${exec_item}
}

build_releaseBinImgSocat()
{
    local exec_cmd=$1
    local exec_item=$2

	FRP_DOCKER_NAME="${FRP_DOCKER_NAME}_socat"
	DOCKER_FILE_NAME="Dockerfile_socat"
	build_releaseBinImg ${exec_cmd} ${exec_item}
}


usage_func()
{

    echoY "Usage:"
    echoY './run.sh -c <cmd> -l "<item list>"'
    echoY "eg:\n./run.sh -c get -l \"releaseBin\""
    echoY "eg:\n./run.sh -c get -l \"releaseSrc\""
    echoY "eg:\n./run.sh -c clean -l \"Img\""
    echoY "eg:\n./run.sh -c clean -l \"ImgSocat\""
    echoY "eg:\n./run.sh -c build -l \"releaseBinImg\""
    echoY "eg:\n./run.sh -c build -l \"releaseBinImgSocat\""
    echoY "eg:\n./run.sh -c build -l \"releaseSrc\""
    echoY "eg:\n./run.sh -c build -l \"srcBinImg\""
    echoY "eg:\n./run.sh -c build -l \"srcBinImgSocat\""

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

case ${EXEC_CMD} in
    "get")
        get_items ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "clean")
        clean_items ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "build")
        build_items ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "*")
        echoR "Unsupport cmd:${EXEC_CMD}"
        ;;
esac


 
