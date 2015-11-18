# -*- mode: ruby -*-
# vi: set ft=ruby:ff=unix

# the size of the extra disk for docker data (in gigabytes)
# should be at least 10GB
DATA_DISK_SIZE = 10

# default to centos
box ||= 'centos/7'

# allows env overrides for the box
box = ENV['box'] if ENV['box']
box_url = ENV['box_url'] if ENV['box_url']

# consume proxy env if set
http_proxy = ENV['http_proxy']
https_proxy = ENV['http_proxy']
no_proxy = ENV['no_proxy']
http_proxy ||= false
https_proxy ||= false
no_proxy ||= 'localhost,127.0.0.1,.localdomain'

Vagrant.configure('2') do |config|
  config.vm.box = box
  config.vm.box_url = box_url if box_url
  config.vm.network 'private_network', type: 'dhcp'
  config.vm.network 'public_network', dev: 'virbr0', mode: 'bridge', type: 'bridge'

  config.vm.provision 'docker'

  config.vm.synced_folder '.', '/home/vagrant/sync', id: 'vagrant-root', type: 'rsync'

  if Vagrant.has_plugin?('vagrant-proxyconf')
    config.proxy.http     = http_proxy
    config.proxy.https    = http_proxy
    config.proxy.no_proxy = no_proxy
    config.proxy.enabled = { docker: true }
  end

  data_disk = './docker-data.vdi'
  config.vm.provider 'virtualbox' do |v|
    unless File.exist?(data_disk)
      v.customize ['createhd', '--filename', data_disk, '--size', DATA_DISK_SIZE * 1024]
    end
    v.customize ['storageattach', :id, '--storagectl', 'IDE Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', data_disk]
  end

  config.vm.provision 'shell', path: 'docker-storage-setup-strap.sh'
  config.vm.provision 'shell', inline: 'grep docker /etc/group || (sudo groupadd docker && usermod -aG docker vagrant)'
end
