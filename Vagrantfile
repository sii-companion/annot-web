# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  config.vm.network :forwarded_port, guest: 5000, host: 5000

  config.vm.provision :chef_solo do |chef|
    chef.version = "12.3.0"
    chef.cookbooks_path = ["cookbooks", "site-cookbooks"]

    chef.add_recipe "runit"
    chef.add_recipe "apt"
    chef.add_recipe "nodejs"
    chef.add_recipe "java"
    chef.add_recipe "redisio"
    chef.add_recipe "redisio::enable"
    chef.add_recipe "ruby_build"
    chef.add_recipe "rbenv::user"
    chef.add_recipe "rbenv::vagrant"
    chef.add_recipe "vim"

    chef.json = {
      java: {
         jdk_version: "7",
      },
      rbenv: {
        user_installs: [{
          user: 'vagrant',
          rubies: ["2.2.1"],
          global: "2.2.1",
          gems: {
            "2.2.1" => [
              { name: "bundler" }
            ]
          }
        }]
      }
    }
  end
end
