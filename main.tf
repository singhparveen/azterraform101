terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.41.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resourcegroup01" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "azvnet" {
  name                = "${var.resource_group_name}-vnet"
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.resourcegroup01.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_group_name}-snet"
  address_prefix       = "10.0.1.0/24"
  resource_group_name  = azurerm_resource_group.resourcegroup01.name
  virtual_network_name = azurerm_virtual_network.azvnet.name
}


resource "azurerm_public_ip" "static" {
  name                = "${var.resource_group_name}-vm-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup01.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.resource_group_name}-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.resourcegroup01.name
  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.static.id
  }
}

resource "azurerm_windows_virtual_machine" "simple-vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.resourcegroup01.name
  location            = var.location
  size                = "Standard_B4ms"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]
  os_disk {
    name                 = join("_", [var.vm_name, "OsDisk"])
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-10"
    sku       = "20h1-pro"
    version   = "19041.685.2012032305"
  }
}
