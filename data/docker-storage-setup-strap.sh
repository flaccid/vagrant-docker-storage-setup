#! /bin/bash -e

[ -e docker-storage-setup-env.sh ] && . ./docker-storage-setup-env.sh

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

pushd /tmp
  # download docker-storage-setup
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
popd

# save the overrides config
touch /etc/sysconfig/docker-storage-setup
valid_directives=(
  STORAGE_DRIVER
  DEVS
  VG
  ROOT_SIZE
  DATA_SIZE
  MIN_DATA_SIZE
  CHUNK_SIZE
  GROWPART
  AUTO_EXTEND_POOL
  POOL_AUTOEXTEND_THRESHOLD
  POOL_AUTOEXTEND_PERCENT
)
for i in "${valid_directives[@]}"
do
    :
    [ ! -z "${!i}" ] && ! grep "$i=${!i}" /etc/sysconfig/docker-storage-setup && \
      echo "$i=${!i}" >> /etc/sysconfig/docker-storage-setup
done

if vgdisplay | grep dockervg; then
  echo 'Looks like the dockervg volume group already exists, skipping.'
else
  # ensure docker is stopped
  systemctl stop docker

  # start the docker-storage-setup service to reconfigure the disk
  # systemctl start docker-storage-setup
  #   or, command directly:
  /usr/bin/docker-storage-setup

  # optional, not required
  # rm -Rf /var/lib/docker/*
fi

# export possible environment variables that can be used in service configuration
export HTTP_PROXY
export NO_PROXY
export OPTIONS
export DOCKER_STORAGE_OPTIONS
export DOCKER_NETWORK_OPTIONS
export BLOCK_REGISTRY
export INSECURE_REGISTRY

# configure the system service
./docker-setup-service.sh

# finally, (re)start the docker service
systemctl restart docker

# print the docker info
docker info

# print the systemd docker service env
systemctl show docker --property Environment

systemctl status docker

echo 'Done.'
