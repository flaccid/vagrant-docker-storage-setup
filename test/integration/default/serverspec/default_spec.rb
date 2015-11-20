# encoding: UTF-8

require_relative 'spec_helper'

describe package('docker-storage-setup') do
  it { should be_installed }
end

describe service('docker') do
  it { should be_enabled }
  it { should be_running }
end

describe command('docker info') do
  its(:stdout) { should contain 'Storage Driver: devicemapper' }
  its(:stdout) { should contain 'Pool Name: dockervg-docker--pool' }
  its(:stdout) { should_not contain '/dev/loop' }
end
