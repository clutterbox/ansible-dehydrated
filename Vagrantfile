# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/bionic64"


    config.vm.provider "virtualbox" do |vb|
      vb.linked_clone = true
      vb.cpus   = 4
      vb.memory = 4096
    end

    config.vm.provision "shell-1", type: "shell", inline: <<-SHELL
        export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
        apt-get update
        apt-get -y install python3-pip jq
        pip3 install virtualenv
        curl -sSL "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    SHELL
    config.vm.provision "docker" do |d|
        d.pull_images "ubuntu:18.04"
        d.pull_images "ubuntu:16.04"
    end
    config.vm.provision "shell-2", type: "shell", inline: <<-SHELL
        sudo -u vagrant -H sh -c "cd /vagrant && ./molecule/setup.sh"
    SHELL
end
