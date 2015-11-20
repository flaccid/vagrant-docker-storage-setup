#! /bin/bash -e

# the docker-storage-setup initial overrides

STORAGE_DRIVER=devicemapper
DEVS=/dev/sdb
VG=dockervg
DATA_SIZE=40%FREE
MIN_DATA_SIZE=2G
CHUNK_SIZE=512K
GROWPART=false
AUTO_EXTEND_POOL=yes
POOL_AUTOEXTEND_THRESHOLD=60
POOL_AUTOEXTEND_PERCENT=20

[ -e docker-storage-setup-env.local.sh ] && . docker-storage-setup-env.local.sh
