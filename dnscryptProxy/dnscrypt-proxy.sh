#!/bin/bash

set -o nounset
set -o errexit

LATEST_VERSION="2.0.16"
DEPLOY_ARCH="arm" # 386 amd64 arm

install_dependency_func()
{
    go get github.com/BurntSushi/toml
    go get github.com/VividCortex/ewma
    go get github.com/VividCortex/godaemon
    go get github.com/coreos/go-systemd/activation
    go get github.com/coreos/go-systemd/daemon
    go get github.com/dchest/safefile
    go get github.com/hashicorp/go-immutable-radix
    go get github.com/hashicorp/golang-lru
    go get github.com/jedisct1/dlog
    go get github.com/jedisct1/go-minisign
    go get github.com/jedisct1/xsecretbox
    go get github.com/kardianos/service
    go get github.com/miekg/dns
    go get github.com/pquerna/cachecontrol/cacheobject

    go get github.com/facebookgo/pidfile
    go get gopkg.in/natefinch/lumberjack.v2
    go get github.com/jedisct1/go-clocksmith
    go get github.com/jedisct1/go-dnsstamps
    go get github.com/k-sone/critbitgo
    go get golang.org/x/text/secure/bidirule
    go get golang.org/x/text/unicode/norm
    go get golang.org/x/crypto/curve25519
    go get golang.org/x/crypto/ed25519
    go get golang.org/x/crypto/nacl/box
    go get golang.org/x/crypto/nacl/secretbox
    go get golang.org/x/net/http2

}

get_latest_src_func()
{
    rm -rf dnscrypt-proxy-src.${LATEST_VERSION}.tar.gz
    wget -c https://github.com/jedisct1/dnscrypt-proxy/archive/${LATEST_VERSION}.tar.gz
    mv ${LATEST_VERSION}.tar.gz dnscrypt-proxy-src.${LATEST_VERSION}.tar.gz
}

build_latest_func()
{

    cp ./releasePkg/dnscrypt-proxy-src.${LATEST_VERSION}.tar.gz /opt/github/

    pushd /opt/github/
    #rm -rf dnscrypt-proxy
    rm -rf dnscrypt-proxy-${LATEST_VERSION}
    tar -zxf dnscrypt-proxy-src.${LATEST_VERSION}.tar.gz

    #git clone https://github.com/jedisct1/dnscrypt-proxy.git
    #pushd /opt/github/dnscrypt-proxy/dnscrypt-proxy
    pushd dnscrypt-proxy-${LATEST_VERSION}/dnscrypt-proxy
    #git pull
    go clean
    # Linux
    GOOS=linux GOARCH=386 go build -ldflags="-s -w" -o dnscrypt-proxy-386
    GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o dnscrypt-proxy-amd64
    GOOS=linux GOARCH=arm go build -ldflags="-s -w" -o dnscrypt-proxy-arm
    popd

    popd
}

release_latest_func()
{
    pushd releasePkg

    mkdir -p ${LATEST_VERSION}
    cp /opt/github/dnscrypt-proxy-${LATEST_VERSION}/dnscrypt-proxy/dnscrypt-proxy-386 ${LATEST_VERSION}/
    cp /opt/github/dnscrypt-proxy-${LATEST_VERSION}/dnscrypt-proxy/dnscrypt-proxy-amd64 ${LATEST_VERSION}/
    cp /opt/github/dnscrypt-proxy-${LATEST_VERSION}/dnscrypt-proxy/dnscrypt-proxy-arm ${LATEST_VERSION}/

    cp /opt/github/dnscrypt-proxy-${LATEST_VERSION}/dnscrypt-proxy/example-* ${LATEST_VERSION}/

    popd
}

install_func()
{
    rm -rf ~/dnsCryptProxy

    pushd releasePkg
    cp -a ${LATEST_VERSION} ~/dnsCryptProxy
    pushd ${LATEST_VERSION}
    cd ~/dnsCryptProxy
    cp dnscrypt-proxy-${DEPLOY_ARCH} dnscrypt-proxy
    popd
    popd

    cp dnsCryptSrc/*.md ~/dnsCryptProxy/
    cp dnsCryptSrc/*.md.minisig ~/dnsCryptProxy/
}

disable_systemDNS_func()
{
    sudo apt-get remove dnsmasq
    sudo apt-get purge dnsmasq

    sudo apt-get remove --auto-remove avahi-daemon
    sudo apt-get purge --auto-remove avahi-daemon

    sudo systemctl stop systemd-resolved.service
    sudo systemctl disable systemd-resolved.service

}

config_func()
{

    pushd ~/dnsCryptProxy
    cp example-dnscrypt-proxy.toml dnscrypt-proxy.toml
	sed -i "s/.*server_names =.*/server_names = \['cisco', 'opennic-onic', 'opennic-tumabox', 'scaleway-fr', 'yandex', 'doh-crypto-sx'\]/" dnscrypt-proxy.toml
	sed -i "s/.*ignore_system_dns =.*/ignore_system_dns = true/" dnscrypt-proxy.toml
	sed -i "s/.*force_tcp =.*/force_tcp = true/" dnscrypt-proxy.toml
	sed -i "s/^timeout =.*/timeout = 3000/" dnscrypt-proxy.toml

    popd
}

enable_service_func()
{
	sudo sed -i '/^static domain_name_servers=.*/d' /etc/dhcpcd.conf
	sudo sed -i '/^#static domain_name_servers=192.168.1.1$/a\static domain_name_servers=127.0.0.1' /etc/dhcpcd.conf

    pushd ~/dnsCryptProxy
    sudo ./dnscrypt-proxy -service install
    sudo sed -i "s/^RestartSec=.*/RestartSec=5/" /etc/systemd/system/dnscrypt-proxy.service
    #sudo ./dnscrypt-proxy -service restart
    sudo ./dnscrypt-proxy -service start
    popd
}

deploy_func()
{
    install_func
    config_func
    disable_systemDNS_func
    enable_service_func
}

deploy_dnscrypt_proxy206_func()
{
    cp -a ./dnsCryptProxy206 ~/dnsCryptProxy

    enable_service_func
}


uninstall_func()
{
    pushd ~/dnsCryptProxy
    sudo ./dnscrypt-proxy -service stop
    sudo ./dnscrypt-proxy -service uninstall
    popd
    sudo rm -rf ~/dnsCryptProxy


	sudo sed -i '/^static domain_name_servers=.*/d' /etc/dhcpcd.conf

}

case $1 in
    installDep) echo "Install dependency..."
        install_dependency_func
        echo "Install dependency finished."
    ;;
    get_latest_src) echo "Get latest dnscrypt proxy source pkg..."
        get_latest_src_func
        echo "Get latest dnscrypt proxy source pkg finished."
    ;;
    build_latest) echo "Build latest dnscrypt proxy ..."
        install_dependency_func
        build_latest_func
        echo "Build latest dnscrypt finished."
    ;;
    release_latest) echo "Release dnscrypt proxy..."
        install_dependency_func
        release_latest_func
        echo "Release dnscrypt finished."
    ;;
    install) echo "Install dnscrypt proxy..."
        install_func
        echo "Install dnscrypt finished."
    ;;
    config) echo "Config dnscrypt proxy..."
        config_func
        echo "Config dnscrypt finished."
    ;;
    disable_systemDNS) echo "Disable dnsmasq as default dns..."
        disable_systemDNS_func
        echo "Disable dnsmasq as default dns finished."
    ;;
    enable_service) echo "Enable dnscrypt proxy..."
        enable_service_func
        echo "Enalble dnscrypt finished."
    ;;
#    "deploy_dnscrypt_proxy206") echo "Deploy dnscrypt proxy 2.0.6..."
#        deploy_dnscrypt_proxy206_func
#        echo "Deploy dnscrypt 2.0.6 finished."
#    ;;
    deploy) echo "Deploy dnscrypt proxy..."
        deploy_func
        echo "Deploy dnscrypt finished."
    ;;
    uninstall) echo "Uninstall dnscrypt proxy..."
        uninstall_func
        echo "Uninstall dnscrypt finished."
    ;;
    *) echo "unknow cmd"
esac




