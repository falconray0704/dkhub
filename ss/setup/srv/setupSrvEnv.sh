#!/bin/bash

set -e
set -x

apt-get update

# make system quickly generate high-quality random numbers.
apt-get install -y haveged

# enable system support multipath TCP
apt-key adv --keyserver hkp://keys.gnupg.net --recv-keys 379CE192D401AB61
echo 'deb https://dl.bintray.com/cpaasch/deb stretch main' > /etc/apt/sources.list.d/mptcp.list
apt-get update
apt-get install linux-mptcp

