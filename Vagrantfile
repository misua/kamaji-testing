# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile for Kamaji Worker Nodes
# Creates lightweight VMs that join tenant control planes

Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 LTS
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_version = "4.3.12"

  # Disable default synced folder
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Define worker nodes for each tenant
  tenants = ["dev", "staging", "prod"]
  
  tenants.each_with_index do |tenant, index|
    config.vm.define "tcp-#{tenant}-worker" do |worker|
      worker.vm.hostname = "tcp-#{tenant}-worker"
      
      # Network configuration - use private network that can reach kind
      worker.vm.network "private_network", type: "dhcp"
      
      # VM resources
      worker.vm.provider "libvirt" do |v|
        v.memory = 2048
        v.cpus = 2
        v.driver = "kvm"
      end
      
      # Alternative: VirtualBox provider
      worker.vm.provider "virtualbox" do |v|
        v.memory = 2048
        v.cpus = 2
        v.name = "tcp-#{tenant}-worker"
      end
      
      # Provision the worker node
      worker.vm.provision "shell", path: "scripts/provision-worker.sh", 
        args: [tenant],
        privileged: true
    end
  end
end
