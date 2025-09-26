data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "ds" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.ds.id

  num_cpus = var.vm_cpu
  memory   = var.vm_memory
  guest_id = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label = "disk0"
    size  = data.vsphere_virtual_machine.template.disks.0.size
    thin_provisioned = true
  }

  clone { template_uuid = data.vsphere_virtual_machine.template.id }

  provisioner "file" {
    source      = "${path.module}/../../scripts/bootstrap.sh"
    destination = "/tmp/bootstrap.sh"

    connection {
      type     = "ssh"
      user     = "cloud-user"
      password = "ChangeMe"
      host     = self.default_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo /tmp/bootstrap.sh ${var.guest_os_type} ${var.postgres_distribution} ${var.postgres_version}"
    ]
    connection {
      type     = "ssh"
      user     = "cloud-user"
      password = "ChangeMe"
      host     = self.default_ip_address
    }
  }
}

output "vm_ip" {
  description = "The default IP address of the deployed VM"
  value       = vsphere_virtual_machine.vm.default_ip_address
}
