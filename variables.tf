variable "vsphere_user" {
    type      = string
    sensitive = true
}

variable "vsphere_password" {
    type      = string
    sensitive = true
}

variable "vsphere_server" {
    type = string
}

variable "datacenter" {
    type = string
}

variable "cluster" {
    type = string
}

variable "datastore" {
    type = string
}

variable "network" {
    type = string
}

variable "vm_name" {
    type = string
}

variable "vm_template" {
    type = string
}

variable "vm_cpu" {
    type    = number
    default = 2
}

variable "vm_memory" {
    type    = number
    default = 4096
}

variable "guest_os_type" {
    type        = string
    description = "rhel9, debian12, oracle9, sles15"
}

variable "postgres_version" {
    type    = string
    default = "17"
}

variable "postgres_distribution" {
    type        = string
    default     = "community"
    description = "community, edb-as, edb-pge"
}
