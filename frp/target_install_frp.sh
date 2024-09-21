#!/bin/sh

set -o nounset
set -o errexit
# trace each command execute, same as `bash -v myscripts.sh`
#set -o verbose
# trace each command execute with attachment infomations, same as `bash -x myscripts.sh`
#set -o xtrace

#set -o
set -e
#set -x

#pwd 
#tree -al ./

# Capture the argument passed (TARGETPLATFORM)
platform=$1
frp_version=$2
build_dir=$3
webDAV_server=$4

os='linux'
arch='amd64'


# Perform platform-specific actions
if [ "$platform" == "linux/amd64" ]; then
    echo "Running script for AMD64"
	os='linux'
	arch='amd64'
elif [ "$platform" == "linux/arm/v6" ]; then
    echo "Running script for ARM v6"
	os='linux'
	arch='arm'
elif [ "$platform" == "linux/arm/v7" ]; then
    echo "Running script for ARM v7"
	os='linux'
	arch='arm_hf'
elif [ "$platform" == "linux/arm64" ]; then
    echo "Running script for ARM64"
	os='linux'
	arch='arm64'
else
    echo "Running script for platform: $platform"
fi

echo "Fetching: /usr/bin/frpc http://${webDAV_server}:1080/frp_${frp_version}_${os}_${arch}/frpc"
wget -O /usr/bin/frpc "http://${webDAV_server}:1080/frp_${frp_version}_${os}_${arch}/frpc"
chmod a+x /usr/bin/frpc

echo "Fetching: /usr/bin/frps http://${webDAV_server}:1080/frp_${frp_version}_${os}_${arch}/frps"
wget -O /usr/bin/frps "http://${webDAV_server}:1080/frp_${frp_version}_${os}_${arch}/frps"
chmod a+x /usr/bin/frps

ls -al /usr/bin/frp*
ls -al /etc/frp/

