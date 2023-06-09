

terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.3.1"
    }
  }
}

#===============================================================================
# vSphere Provider
#===============================================================================

provider "vsphere" {
  vsphere_server       = var.vsphere_vcenter
  user                 = var.vsphere_user
  password             = var.vsphere_password
  allow_unverified_ssl = var.vsphere_unverified_ssl
}


data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vm_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {}

# // for existing port-groups
data "vsphere_network" "vm_vlan" {
  name          = var.vm_vlan
  datacenter_id = data.vsphere_datacenter.dc.id
}


data "vsphere_host" "host" {
  name          = "esxi1"
  datacenter_id = data.vsphere_datacenter.dc.id
}
# current problem: vlan and vswitch cant be created at the same time 
# // Create Virtual Switch
# resource "vsphere_host_virtual_switch" "host_vswitch" {
#   name           = var.vswitch_name
#   host_system_id = data.vsphere_host.host.id

#   network_adapters = ["", ""]

#   active_nics    = [""]
#   standby_nics   = [""]
#   teaming_policy = "failover_explicit"

#   allow_promiscuous      = false
#   allow_forged_transmits = false
#   allow_mac_changes      = false

#   shaping_enabled           = true
#   shaping_average_bandwidth = 50000000
#   shaping_peak_bandwidth    = 100000000
#   shaping_burst_size        = 1000000000
# }


# // Create Port-group 
# resource "vsphere_host_port_group" "pg" {
#   name                = var.vm_vlan
#   host_system_id      = data.vsphere_host.host.id
#   virtual_switch_name = vsphere_host_virtual_switch.host_vswitch.name
# }


// Create Virtual Machine
resource "vsphere_virtual_machine" "vm" {
  name                       = "${var.vm_name}-master-${count.index+1}"
  resource_pool_id           = data.vsphere_resource_pool.pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  count                      = var.vm_count
  num_cpus                   = var.vm_cpu
  memory                     = var.vm_ram
  wait_for_guest_net_timeout = 0
  // For more information about guest id in vmware >>>
  // https://docs.vmware.com/en/VMware-HCX/4.6/hcx-user-guide/GUID-D4FFCBD6-9FEC-44E5-9E26-1BD0A2A81389.html
  guest_id          = var.guest_id
  nested_hv_enabled = true
  network_interface {
    network_id   = data.vsphere_network.vm_vlan.id
    adapter_type = var.adapter_type
  }
  cdrom {
    datastore_id = data.vsphere_datastore.datastore.id
    path = "iso/ubuntu-22.04.2-live-server-amd64.iso"
  }
  disk {
    label = "vm"
    size  = var.vm_disksize
  }
  depends_on = [
    # vsphere_host_virtual_switch.host_vswitch
    data.vsphere_network.vm_vlan
  ]
}



// Create Virtual Machine
resource "vsphere_virtual_machine" "vm_worker" {
  name                       = "${var.vm_name}-worker-${count.index+1}"
  resource_pool_id           = data.vsphere_resource_pool.pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  count                      = var.vm_count
  num_cpus                   = var.vm_cpu
  memory                     = var.vm_ram
  wait_for_guest_net_timeout = 0
  // For more information about guest id in vmware >>>
  // https://docs.vmware.com/en/VMware-HCX/4.6/hcx-user-guide/GUID-D4FFCBD6-9FEC-44E5-9E26-1BD0A2A81389.html
  guest_id          = var.guest_id
  nested_hv_enabled = true
  network_interface {
    network_id   = data.vsphere_network.vm_vlan.id
    adapter_type = var.adapter_type
  }
  cdrom {
    datastore_id = data.vsphere_datastore.datastore.id
    path = "iso/ubuntu-22.04.2-live-server-amd64.iso"
  }
  disk {
    label = "vm"
    size  = var.vm_disksize
  }
  depends_on = [
    # vsphere_host_virtual_switch.host_vswitch
    data.vsphere_network.vm_vlan
  ]
}