#! /bin/sh -e

# configures the docker systemd service on EL-based systems

: "${NO_PROXY:=localhost,127.0.0.0/8}"

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

if [ ! -z "$HTTP_PROXY" ]; then
  cat <<EOF> /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=$HTTP_PROXY" "NO_PROXY=$NO_PROXY"
EOF
fi

if [ ! -z "$OPTIONS" ]; then
  grep 'OPTIONS=' /etc/sysconfig/docker > /dev/null 2>&1 || echo 'OPTIONS=' >> /etc/sysconfig/docker
  sed -i "/OPTIONS=/c\OPTIONS='$OPTIONS'" /etc/sysconfig/docker
fi

if [ ! -z "$BLOCK_REGISTRY" ]; then
  grep 'BLOCK_REGISTRY=' /etc/sysconfig/docker > /dev/null 2>&1 || echo 'BLOCK_REGISTRY=' >> /etc/sysconfig/docker
  sed -i "/BLOCK_REGISTRY=/c\BLOCK_REGISTRY='$BLOCK_REGISTRY'" /etc/sysconfig/docker
fi

if [ ! -z "$INSECURE_REGISTRY" ]; then
  grep 'INSECURE_REGISTRY=' /etc/sysconfig/docker > /dev/null 2>&1 || echo 'INSECURE_REGISTRY=' >> /etc/sysconfig/docker
  sed -i "/INSECURE_REGISTRY=/c\INSECURE_REGISTRY='$INSECURE_REGISTRY'" /etc/sysconfig/docker
fi

if [ ! -z "$DOCKER_NETWORK_OPTIONS" ]; then
  grep 'DOCKER_NETWORK_OPTIONS=' /etc/sysconfig/docker-network > /dev/null 2>&1 || echo 'DOCKER_NETWORK_OPTIONS=' >> /etc/sysconfig/docker-network
  sed -i "/DOCKER_NETWORK_OPTIONS=/c\DOCKER_NETWORK_OPTIONS='$DOCKER_NETWORK_OPTIONS'" /etc/sysconfig/docker-network
fi

# docker should already be enabled, but to be sure
systemctl enable docker

# reload the service unit file
systemctl daemon-reload
