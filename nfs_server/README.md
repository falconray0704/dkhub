# nfs-server-alpine

A handy NFS Server image comprising Alpine Linux and NFS v4 only, over TCP on port 2049.

## Overview

The image comprises of;

- [Alpine Linux](http://www.alpinelinux.org/) v3.11.2. 
- NFS v4 only, over TCP on port 2049. Rpcbind is enabled for now to overcome a bug with slow startup, it shouldn't be required.

### Multiple Shares from host with docker-compose
To launch nfs server container with multiple host shares, just customize the configuration file `config/exports`, map it into container in `docer-compose.yml`, and map those directories on host you want to share into container as well.

Start share:
`docker-compose up -d`

Stop share:
`docker-compose down`

Check logs:
`docker-compose logs`

### Mount from Linux
To mount :

`sudo mount -v -o vers=4,loud 10.11.12.101:/ /some/where/here`

To _unmount_:

`sudo umount /some/where/here`

