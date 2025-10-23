output "vm_ips" {
  value = 
  { for k, v in module.vm : k => v.vm_ip }
}