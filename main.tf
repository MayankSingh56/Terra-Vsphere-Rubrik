module "vm" {
  for_each = var.vms
  source   = "./modules/vm"
 
  vm_name      = each.key
  vm_cpu       = each.value.cpu
  vm_memory    = each.value.memory
  vm_disk_size = each.value.disk_gb

  vsphere_user        = var.vsphere_user
  vsphere_password    = var.vsphere_password
  vsphere_server      = var.vsphere_server
  datacenter          = var.datacenter
  cluster             = var.cluster
  datastore           = var.datastore
  network             = var.network
  
  vm_template         = var.vm_template
  
  guest_os_type       = var.guest_os_type
  postgres_version    = var.postgres_version
  postgres_distribution = var.postgres_distribution
}
