# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|

  config.vm.network "public_network", type: 'dhcp'

  config.vm.define 'metasploit' do |machine|
    machine.vm.box = "ubuntu/trusty64"
    machine.vm.hostname = 'localhost-metasploit'
    machine.vm.provision 'ansible' do |ansible|
      ansible.playbook = 'playbooks/metasploit.yml'
    end
    machine.vm.provider :virtualbox do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  config.vm.define 'target' do |machine|
    machine.vm.box = "ubuntu/trusty64"
    machine.vm.hostname = 'localhost-metasploit-target'
    machine.vm.provision 'ansible' do |ansible|
      ansible.playbook = 'playbooks/target.yml'
    end
    machine.vm.provider :virtualbox do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
  end

  config.vm.define 'target-windows' do |machine|
    machine.vm.box = 'windows/xp-ie6'
    machine.vm.box_url = 'http://aka.ms/vagrant-xp-ie6'

    machine.vm.communicator = "winrm"
    machine.vm.boot_timeout = 1
    machine.winrm.host = "localhost"
    machine.winrm.timeout = 1
    machine.winrm.retry_limit = 1

    machine.vm.provider :virtualbox do |v|
      v.gui = true
    end
  end

end


