output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "spoke1_vnet_id" {
  value = azurerm_virtual_network.spoke1.id
}

output "spoke2_vnet_id" {
  value = azurerm_virtual_network.spoke2.id
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.capstone.id
}

output "shared_subnet_id" {
  value = azurerm_subnet.shared.id
}