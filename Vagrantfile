# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
disk_1 = 'ebs1.vdi'
disk_2 = 'ebs2.vdi'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/xenial64"

  config.vm.provider :virtualbox do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "1024"]

    unless File.exist?(disk_1)
        vb.customize ['createhd', '--filename', disk_1, '--variant', 'Fixed', '--size', 1 * 1024]
        vb.customize ['createhd', '--filename', disk_2, '--variant', 'Fixed', '--size', 1 * 1024]
        vb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', disk_1]
        vb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 3, '--device', 0, '--type', 'hdd', '--medium', disk_2]
    end
  end

  config.vm.provision :saltdeps do |deps|
    deps.base_vagrantfile = "git@github.com:Ubiquiti-Cloud/salt-vagrant-base.git"
    deps.checkout_path =  "./.vagrant-salt/deps"
  end

end
