#!/bin/sh

set -e
set -x

cp /bin/ss-redir /ssredir/
cp /etc/shadowsocks/*.service /ssredir/
cp /etc/shadowsocks/config.json /ssredir/

