vsphere_user     = "administrator@vsphere.local"
vsphere_password = "changeme"
vsphere_server   = "ip"

datacenter = "Datacenter"
cluster    = "Cluster1"
datastore  = "datastore1"
network    = "VM Network"

vms = {
  "pg-db01" = { cpu = 2, memory = 4096, disk_gb = 100 }
  "pg-db02"={ cpu = 2, memory = 4096, disk_gb = 100 }
}

vm_template = "sample_testing_rhel09_postgres"

guest_os_type        = "rhel9"
postgres_version     = "17"
postgres_distribution = "community"
