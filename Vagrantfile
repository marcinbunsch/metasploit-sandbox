# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|

  config.vm.provider :virtualbox do |vb|
    config.vm.box = 'ubuntu/trusty64'
  end

  config.vm.network "public_network", type: 'dhcp'

  config.vm.define 'metasploit' do |machine|
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

    machine.vm.hostname = 'localhost-metasploit-target'
    config.vm.provision 'ansible' do |ansible|
      ansible.playbook = 'playbooks/target.yml'
      # ansible.verbose = 'vvvv'
    end
  end

end


