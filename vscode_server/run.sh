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
. ./.env_setup

. ../utils/utils.lib
. ./.docker_vars

SUPPORTED_CMD="build,clean,start,stop"
SUPPORTED_TARGETS="vscode_server"

EXEC_CMD=""
EXEC_ITEMS_LIST=""

start_vscode_server()
{
    export uid=$(id -u)
    export gid=$(id -g)
    export HOST_PROJECT_PATH="/mnt/n11/zsync/rk1126"
    export HOST_PROJECT_DIR=$(basename ${HOST_PROJECT_PATH})
    export HOST_VSCODE_SERVER_CONFIG_PATH="$(dirname ${HOST_PROJECT_PATH})/.vsc_srv_cfg"
    mkdir -p ${HOST_VSCODE_SERVER_CONFIG_PATH}
    docker-compose up -d
}

stop_vscode_server()
{
    export uid=$(id -u)
    export gid=$(id -g)
    export HOST_PROJECT_PATH="/mnt/n11/zsync/rk1126"
    export HOST_PROJECT_DIR=$(basename ${HOST_PROJECT_PATH})
    export HOST_VSCODE_SERVER_CONFIG_PATH="$(dirname ${HOST_PROJECT_PATH})/.vsc_srv_cfg"
    docker-compose down
}

build_vscode_server()
{
    local TARGET_USER_NAME=${DOCKER_USER_NAME}
    local TARGET_NAME=$2
    local TARGET_ARCH=${OSENV_DOCKER_CPU_ARCH}

    echoY "Building docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_${TARGET_NAME} with version: ${VSCODE_REL_VERSION} ..."

    mkdir -p img_build_dir
    pushd img_build_dir
    # download code-server release
    if [ -f code-server_${VSCODE_REL_VERSION}_${TARGET_ARCH}.deb ]
    then
        echoY "code-server_${VSCODE_REL_VERSION}_${TARGET_ARCH}.deb already existed." 
    else
        wget -c https://github.com/cdr/code-server/releases/download/v${VSCODE_REL_VERSION}/code-server_${VSCODE_REL_VERSION}_${TARGET_ARCH}.deb
    fi

    # download sysCfg
    if [ -d sysCfg/.git ]
    then
        pushd sysCfg
#        git fetch origin vscode_server
        git pull
#        git checkout vscode_server
        popd
    else
        git clone https://github.com/falconray0704/sysCfg.git
#        git checkout vscode_server
    fi
    pushd sysCfg
    git submodule init
    git submodule update
    popd
    popd
#    exit 0

    cp entrypoint.sh img_build_dir/
    cp Dockerfile img_build_dir/

    docker build --rm -t ${TARGET_USER_NAME}/${TARGET_ARCH}_${TARGET_NAME} \
        --build-arg "group=$(id -gn)" \
        --build-arg "gid=$(id -u)" \
        --build-arg "user=$(id -un)" \
        --build-arg	"uid=$(id -g)" \
        --build-arg "VSCODE_REL_VERSION=${VSCODE_REL_VERSION}" \
        --build-arg	"OSENV_DOCKER_CPU_ARCH=${OSENV_DOCKER_CPU_ARCH}" \
        img_build_dir

    if [ $? -eq 0 ]
    then
        echoG "Docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_${TARGET_NAME} built success."
    else
        echoR "Docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_${TARGET_NAME} built fail."
    fi

}

clean_vscode_server()
{
    local TARGET_USER_NAME=${DOCKER_USER_NAME}
    local TARGET_NAME=$2
    local TARGET_ARCH=${OSENV_DOCKER_CPU_ARCH}

    clean_docker_image "${TARGET_USER_NAME}/${TARGET_ARCH}_${TARGET_NAME}"
}

usage_func()
{

    echoY "Usage:"
    echoY './run.sh -c <cmd> -l "<item list>"'
    echoY "eg:\n./run.sh -c clean -l \"vscode_server\""
    echoY "eg:\n./run.sh -c build -l \"vscode_server\""
    echoY "eg:\n./run.sh -c start -l \"vscode_server\""
    echoY "eg:\n./run.sh -c stop -l \"vscode_server\""

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
    "clean")
        clean_items ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "build")
        build_items ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "start")
        start_items ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "stop")
        stop_items ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "*")
        echoR "Unsupport cmd:${EXEC_CMD}"
        ;;
esac



