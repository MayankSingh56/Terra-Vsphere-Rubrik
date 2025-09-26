module "vm" {
  source = "./modules/vm"

  vsphere_user        = var.vsphere_user
  vsphere_password    = var.vsphere_password
  vsphere_server      = var.vsphere_server
  datacenter          = var.datacenter
  cluster             = var.cluster
  datastore           = var.datastore
  network             = var.network
  vm_name             = var.vm_name
  vm_template         = var.vm_template
  vm_cpu              = var.vm_cpu
  vm_memory           = var.vm_memory
  guest_os_type       = var.guest_os_type
  postgres_version    = var.postgres_version
  postgres_distribution = var.postgres_distribution
}
