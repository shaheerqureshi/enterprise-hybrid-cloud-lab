output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.lab.ip_address
}

output "vm_name" {
  description = "Name of the VM"
  value       = azurerm_linux_virtual_machine.lab.name
}

output "resource_group" {
  description = "Resource group name"
  value       = azurerm_resource_group.lab.name
}