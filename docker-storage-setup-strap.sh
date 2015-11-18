#!/bin/sh -ex

# install deps
yum -y install rpm-build git

# the docker-storage-setup overrides
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

# build and install the rpm
cd /tmp
[ -e /tmp/ ] && rm -Rf /tmp/docker-storage-setup
git clone https://github.com/projectatomic/docker-storage-setup.git
cd docker-storage-setup
mkdir -pv /root/rpmbuild/SOURCES

# temp hacks (don't check VG_EXISTS, turn on bash -x)
sed -i'' '315,318 s/^/#/' docker-storage-setup.sh
sed -i 's%#!/bin/bash%#!/bin/bash -x%g' docker-storage-setup.sh

rm -Rf /root/rpmbuild/SOURCES/*
cp -v docker-storage-setup.sh /root/rpmbuild/SOURCES/
cp -v docker-storage-setup.service /root/rpmbuild/SOURCES/
cp -v docker-storage-setup.conf /root/rpmbuild/SOURCES/
cp -v docker-storage-setup-override.conf /root/rpmbuild/SOURCES/
cp -v libdss.sh /root/rpmbuild/SOURCES/
rpmbuild -v -bb --clean docker-storage-setup.spec
rpm -iv --force --replacepkgs /root/rpmbuild/RPMS/x86_64/*.rpm

# save the overrides config
echo STORAGE_DRIVER=devicemapper >> /etc/sysconfig/docker-storage-setup
echo DEVS="$DEVS" >> /etc/sysconfig/docker-storage-setup
echo VG="$VG" >> /etc/sysconfig/docker-storage-setup
echo DATA_SIZE="$DATA_SIZE" >> /etc/sysconfig/docker-storage-setup
echo MIN_DATA_SIZE="$MIN_DATA_SIZE" >> /etc/sysconfig/docker-storage-setup
echo CHUNK_SIZE="$CHUNK_SIZE" >> /etc/sysconfig/docker-storage-setup
echo GROWPART="$GROWPART" >> /etc/sysconfig/docker-storage-setup
echo AUTO_EXTEND_POOL="$AUTO_EXTEND_POOL" >> /etc/sysconfig/docker-storage-setup
echo POOL_AUTOEXTEND_THRESHOLD="$POOL_AUTOEXTEND_THRESHOLD" >> /etc/sysconfig/docker-storage-setup
echo POOL_AUTOEXTEND_PERCENT="$POOL_AUTOEXTEND_PERCENT" >> /etc/sysconfig/docker-storage-setup

# docker should already be enabled, but to be sure
systemctl enable docker

# ensure docker is stopped
systemctl stop docker

# optional, no need to run it again after once-off setup
# systemctl enable docker-storage-setup

# start the docker-storage-setup service to reconfigure the disk
# systemctl start docker-storage-setup
# or, command directly:
/usr/bin/docker-storage-setup

# finally, start docker
systemctl start docker

touch /etc/sysconfig/docker /etc/sysconfig/docker-storage /etc/sysconfig/docker-network

mkdir -p /etc/systemd/system/docker.service.d
cat <<'EOF'> /etc/systemd/system/docker.service.d/10-parameterized.conf
[Service]
EnvironmentFile=-/etc/sysconfig/docker
EnvironmentFile=-/etc/sysconfig/docker-storage
EnvironmentFile=-/etc/sysconfig/docker-network
ExecStart=
ExecStart=/usr/bin/docker daemon $OPTIONS \
          $DOCKER_STORAGE_OPTIONS \
          $DOCKER_NETWORK_OPTIONS \
          $BLOCK_REGISTRY \
          $INSECURE_REGISTRY
EOF

systemctl daemon-reload

# known to not always work first time, or even the second time!
# e.g. level=fatal msg="zError starting daemon: error initializing graphdriver: Base Device UUID verification failed. Possibly using a different thin pool than last invocation:Er
systemctl start docker || systemctl restart docker || systemctl restart docker

echo 'Done.'
