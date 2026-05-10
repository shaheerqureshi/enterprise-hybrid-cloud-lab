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

resource "azurerm_network_security_group" "lab" {
  name = "nsg-terraform-lab"
  resource_group_name = azurerm_resource_group.lab.name
  location = azurerm_resource_group.lab.location

  security_rule {
    name = "Allow-SSH"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.lab.id
}

resource "azurerm_public_ip" "lab" {
  name = "pip-terraform-lab"
  resource_group_name = azurerm_resource_group.lab.name
  location = azurerm_resource_group.lab.location
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_network_interface" "lab" {
  name = "nic-terraform-lab"
  resource_group_name = azurerm_resource_group.lab.name
  location = azurerm_resource_group.lab.location

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.lab.id
  }
}

resource "azurerm_linux_virtual_machine" "lab" {
  name = "vm-terraform-lab"
  resource_group_name = azurerm_resource_group.lab.name
  location = azurerm_resource_group.lab.location
  size = "Standard_B1s"
  admin_username = "azureuser"
  admin_password = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [ azurerm_network_interface.lab.id ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "001-con-ubuntu-server-jammy"
    sku = "22_04-lts"
    version = "lates"
  }
}