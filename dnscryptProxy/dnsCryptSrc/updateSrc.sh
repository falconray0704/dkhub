#!/bin/bash

set -o nounset
set -o errexit

rm -rf ./public*
wget -c https://download.dnscrypt.info/dnscrypt-resolvers/v2/public-resolvers.md
wget -c https://download.dnscrypt.info/dnscrypt-resolvers/v2/public-resolvers.md.minisig
#wget -c https://download.dnscrypt.info/dnscrypt-resolvers/v2/opennic.md
#wget -c https://mastad0n.github.io/resolvers/v2/usa.md

