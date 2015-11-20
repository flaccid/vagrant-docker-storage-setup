#! /bin/bash -e

# the docker-storage-setup overrides
overrides=(
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
)

if vgdisplay | grep dockervg; then
  echo 'Looks like the dockervg volume group already exists, skipping.'
  exit 0
fi

# this is recommended but an up-to-date image should be fine
[[ "$YUM_UPDATE" -eq 1 ]] && yum -y update

# quick install of docker if not found
if ! type -P docker > /dev/null 2>&1; then
  cat >/etc/yum.repos.d/docker.repo <<-EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
  yum -y install docker-engine
fi

# install deps
yum -y install rpm-build tar curl

# download docker-storage-setup
cd /tmp
rm -Rf /tmp/docker-storage-setup*
curl -L https://github.com/projectatomic/docker-storage-setup/archive/master.tar.gz > \
  docker-storage-setup.tar.gz
tar zxvf docker-storage-setup.tar.gz
cd docker-storage-setup-master

# temp hack (don't check VG_EXISTS)
sed -i'' '315,318 s/^/#/' docker-storage-setup.sh

# turn on bash -x
[[ "$DOCKER_STORAGE_DEBUG" -eq 1 ]] && \
  sed -i 's%#!/bin/bash%#!/bin/bash -x%g' docker-storage-setup.sh

# build and install the docker-storage-setup rpm
mkdir -p /root/rpmbuild/SOURCES
rm -Rf /root/rpmbuild/SOURCES/*
cp docker-storage-setup.sh \
  docker-storage-setup.service \
  docker-storage-setup.conf \
  docker-storage-setup-override.conf \
  libdss.sh \
    /root/rpmbuild/SOURCES/
rpmbuild -v -bb --clean docker-storage-setup.spec
rpm -iv --force --replacepkgs /root/rpmbuild/RPMS/x86_64/*.rpm

# save the overrides config
touch /etc/sysconfig/docker-storage-setup
for i in "${overrides[@]}"
do
    :
    ! grep "$i" /etc/sysconfig/docker-storage-setup && \
        echo "$i" >> /etc/sysconfig/docker-storage-setup
done

# docker should already be enabled, but to be sure
systemctl enable docker

# ensure docker is stopped
systemctl stop docker

# start the docker-storage-setup service to reconfigure the disk
# systemctl start docker-storage-setup
#   or, command directly:
/usr/bin/docker-storage-setup

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
# rm -Rf /var/lib/docker/*
systemctl start docker

echo 'Done.'
