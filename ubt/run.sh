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

SUPPORTED_CMD="build,clean"
SUPPORTED_TARGETS="base_bionic"

EXEC_CMD=""
EXEC_ITEMS_LIST=""

build_base_bionic()
{
    local TARGET_USER_NAME=${DOCKER_USER_NAME}
    local TARGET_NAME=$2
    local TARGET_ARCH=${OSENV_DOCKER_CPU_ARCH}

    echoY "Building docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_ubuntu:${TARGET_NAME} ..."

    docker build --rm -t ${TARGET_USER_NAME}/${TARGET_ARCH}_ubuntu:${TARGET_NAME} \
        --build-arg "group=$(id -gn)" \
        --build-arg "gid=$(id -u)" \
        --build-arg "user=$(id -un)" \
        --build-arg	"uid=$(id -g)" \
        -f ./Dockerfile_base.img .

    if [ $? -eq 0 ]
    then
        echoG "Docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_ubuntu:${TARGET_NAME} built success."
    else
        echoR "Docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_ubuntu:${TARGET_NAME} built fail."
    fi

}

clean_base_bionic()
{
    local TARGET_USER_NAME=${DOCKER_USER_NAME}
    local TARGET_NAME=$2
    local TARGET_ARCH=${OSENV_DOCKER_CPU_ARCH}

    clean_docker_image "${TARGET_USER_NAME}/${TARGET_ARCH}_ubuntu:${TARGET_NAME}"
}

usage_func()
{

    echoY "Usage:"
    echoY './run.sh -c <cmd> -l "<item list>"'
    echoY "eg:\n./run.sh -c clean -l \"base_bionic\""
    echoY "eg:\n./run.sh -c build -l \"base_bionic\""

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
    "*")
        echoR "Unsupport cmd:${EXEC_CMD}"
        ;;
esac



