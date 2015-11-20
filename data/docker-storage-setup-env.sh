#! /bin/bash -e

# the docker-storage-setup initial overrides

DEVS=/dev/sdb
VG=dockervg

[ -e docker-storage-setup-env.local.sh ] && . docker-storage-setup-env.local.sh
