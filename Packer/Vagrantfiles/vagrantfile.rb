# -*- mode: ruby -*-
# vi: set ft=ruby :

$msg = <<MSG
Welcome to Alpine Linux box for Vagrant by Yohnah

MSG

class VagrantPlugins::ProviderVirtualBox::Action::Network #Monkey path to fix dhcp service when public bridge or host-only
  def dhcp_server_matches_config?(dhcp_server, config)
    true
  end
end

Vagrant.configure(2) do |config|
  config.vm.post_up_message = $msg
  config.ssh.shell = '/bin/sh'

  config.vm.provider "virtualbox" do |vb, override|
    vb.memory = 2048
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--vram", "128"]
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--uart1", "off"] #Disconnect serial port to permit box up on windows/non-unixlike devices
    vb.customize ['modifyvm', :id, '--vrde', 'off']
  end

end