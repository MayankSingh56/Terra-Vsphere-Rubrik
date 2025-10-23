variable "vsphere_user" {
    description = "vSphere username"
    type        = string
}

variable "vsphere_password" {
    description = "vSphere password"
    type        = string
    sensitive   = true
}

variable "vsphere_server" {
    description = "vSphere server address"
    type        = string
}

variable "datacenter" {
    description = "vSphere datacenter name"
    type        = string
}

variable "cluster" {
    description = "vSphere cluster name"
    type        = string
}

variable "datastore" {
    description = "vSphere datastore name"
    type        = string
}

variable "network" {
    description = "vSphere network name"
    type        = string
}

variable "vm_name" {
    description = "Name of the virtual machine"
    type        = string
}

variable "vm_template" {
    description = "VM template to use"
    type        = string
}

variable "vm_cpu" {
    description = "Number of CPUs for the VM"
    type        = number
}

variable "vm_memory" {
    description = "Amount of memory (MB) for the VM"
    type        = number
}

variable "guest_os_type" {
    description = "Guest OS type"
    type        = string
}

variable "postgres_version" {
    description = "PostgreSQL version"
    type        = string
}

variable "postgres_distribution" {
    description = "PostgreSQL distribution"
    type        = string
}

variable "vm_disk_size" {
    description = "Size of the VM disk in GB"
    type        = number
}