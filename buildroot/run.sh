#!/bin/bash

set -o nounset
set -o errexit
# trace each command execute, same as `bash -v myscripts.sh`
#set -o verbose
# trace each command execute with attachment infomations, same as `bash -x myscripts.sh`
#set -o xtrace


. ../libShell/echo_color.lib
. ../libShell/utils.lib
. ../libShell/sysEnv.lib

. ./.docker_vars
. ./.env_setup

SUPPORTED_CMD="build,clean"
SUPPORTED_TARGETS="rk3568"

EXEC_CMD=""
EXEC_ITEMS_LIST=""

build_rk3568()
{
    local TARGET_USER_NAME=${DOCKER_USER_NAME}
    local TARGET_NAME=$2
    local TARGET_ARCH=${OSENV_DOCKER_CPU_ARCH}

    echoY "Building docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_buildroot_sdk:${TARGET_NAME} for building rk3568 SDK..."

    docker build --rm -t ${TARGET_USER_NAME}/${TARGET_ARCH}_buildroot_sdk:${TARGET_NAME} \
        --build-arg "group=$(id -gn)" \
        --build-arg "gid=$(id -u)" \
        --build-arg "user=$(id -un)" \
        --build-arg	"uid=$(id -g)" \
        -f ./Dockerfile_ubt1804_build_sdk_rk3568.img .

    if [ $? -eq 0 ]
    then
        echoG "Docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_buildroot_sdk:${TARGET_NAME} built success."
    else
        echoR "Docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_buildroot_sdk:${TARGET_NAME} built fail."
    fi

}

clean_rk3568()
{
    local TARGET_USER_NAME=${DOCKER_USER_NAME}
    local TARGET_NAME=$2
    local TARGET_ARCH=${OSENV_DOCKER_CPU_ARCH}

    echoY "Cleanning docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_buildroot_sdk:${TARGET_NAME} for building rk3568 SDK..."
	docker rmi -f ${TARGET_USER_NAME}/${TARGET_ARCH}_buildroot_sdk:${TARGET_NAME}
    if [ $? -eq 0 ]
    then
        docker image prune
        echoG "Docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_buildroot_sdk:${TARGET_NAME} removed success!"
    else
        echoR "Docker image ${TARGET_USER_NAME}/${TARGET_ARCH}_buildroot_sdk:${TARGET_NAME} removed fail!"
    fi
}


clean_items_func()
{
    local exec_cmd=$1
    local exec_items_list=$2

    exec_items_iterator ${exec_cmd} ${exec_items_list} 
}

build_items_func()
{
    local exec_cmd=$1
    local exec_items_list=$2

    exec_items_iterator ${exec_cmd} ${exec_items_list} 
}

usage_func()
{

    echoY "Usage:"
    echoY './run.sh -c <cmd> -l "<item list>"'
    echoY "eg:\n./run.sh -c clean -l \"rk3568\""
    echoY "eg:\n./run.sh -c build -l \"rk3568\""

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
        clean_items_func ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "build")
        build_items_func ${EXEC_CMD} ${EXEC_ITEMS_LIST}
        ;;
    "*")
        echoR "Unsupport cmd:${EXEC_CMD}"
        ;;
esac



