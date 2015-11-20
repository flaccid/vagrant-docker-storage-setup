# -*- mode: ruby -*-
# vi: set ft=ruby:ff=unix

DOCKER_DISK = {
  # the size of the extra disk for the
  # docker data should be at least 10GB
  size: 10,
  file: 'docker-data.vdi',
  controller: 'IDE Controller'
}

Vagrant.configure('2') do |config|
  config.vm.box = ENV['box'] || 'centos/7'
  config.vm.box_url = ENV['box_url'] || nil

  # additional networking to support boxes with different capabilities
  config.vm.network 'private_network', type: 'dhcp'
  config.vm.network 'public_network',
                    dev: 'virbr0', mode: 'bridge', type: 'bridge'

  config.vm.synced_folder '.', '/home/vagrant/sync',
                          id: 'vagrant-root', type: 'rsync'

  config.vm.provision 'docker'

  if Vagrant.has_plugin?('vagrant-proxyconf')
    config.proxy.http     = ENV['http_proxy']
    config.proxy.https    = ENV['https_proxy']
    config.proxy.no_proxy = ENV['no_proxy']
    config.proxy.enabled = { docker: true }
  end

  config.vm.provider 'virtualbox' do |vb|
    unless File.exist?(DOCKER_DISK[:file])
      vb.customize ['createhd',
                    '--filename', DOCKER_DISK[:file],
                    '--size', DOCKER_DISK[:size] * 1024]
    end
    vb.customize ['storageattach', :id,
                  '--storagectl', DOCKER_DISK[:controller],
                  '--port', 1,
                  '--device', 0,
                  '--type', 'hdd',
                  '--medium', DOCKER_DISK[:file]]
  end

  config.vm.provision 'shell', path: 'data/docker-storage-setup-strap.sh'
  config.vm.provision 'shell',
                      inline: '(getent group docker || groupadd docker) && \
                               usermod -aG docker vagrant'
end
