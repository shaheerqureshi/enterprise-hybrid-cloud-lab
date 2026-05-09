terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm"{
    features{}
}
resource "azurerm_resource_group" "lab" {
  name = "rg-terraform-lab"
  location = "canadacentral"
}

resource "azurerm_virtual_network" "lab" {
  name = "vnet-terraform-lab"
  resource_group_name = azurerm_resource_group.lab.name
  location = azurerm_resource_group.lab.location
  address_space = [ "10.10.0.0/16" ]
  
}

resource "azurerm_subnet" "web" {
  name = "snet-web"
  resource_group_name = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes = [ "10.10.1.0/24" ]
}
resource "azurerm_subnet" "data" {
  name = "snet-data"
  resource_group_name = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes = [ "10.10.2.0/24" ]
}