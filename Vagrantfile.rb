# -*- mode: ruby -*-
# vi: set ft=ruby:ff=unix

DOCKER_DISK = {
  # the size of the extra disk for docker data should be at least 10GB
  size: 10,
  file: 'docker-data.vdi',
  controller: 'SATA Controller'
}

Vagrant.configure('2') do |c|
  c.vm.provider 'virtualbox' do |vb|
    unless File.exist?(DOCKER_DISK[:file])
      vb.customize ['createhd',
                   '--filename', DOCKER_DISK[:file],
                   '--size', DOCKER_DISK[:size] * 1024]
    end
    vb.customize ['storageattach', :id,
                 '--storagectl', DOCKER_DISK[:controller],
                 '--port', 1,
                 '--device', 0,
                 '--type',
                 'hdd',
                 '--medium', DOCKER_DISK[:file]]
  end
end
