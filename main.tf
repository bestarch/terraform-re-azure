terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
      }
  }
}


resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-ResourceGrp-tf"
  location = var.region
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_subnet" "subnet" {
  count                = 3
  name                 = "${var.prefix}-internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  #address_prefixes     = [var.subnet_cidr]
  address_prefixes     = [cidrsubnet(var.vnet_cidr, tostring(3), tostring(count.index))]
}

resource "azurerm_public_ip" "publicip" {
  count               = 3
  name                = "${var.prefix}-public-ip-${count.index}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = [ "${count.index + 1}" ]
}


resource "azurerm_network_interface" "nic" {
  count               = 3
  name                = "${var.prefix}-nic-${count.index}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ip-configuration-1"
    #subnet_id                     = azurerm_subnet.subnet1.id
    #subnet_id                     = element(azurerm_subnet.subnet.*.id, count.index)
    subnet_id                     = azurerm_subnet.subnet[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "sg2nic" {
  count                     = 3
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.sg.id
}


resource "azurerm_virtual_machine" "vm" {
  count               = 3
  name                  = "${var.prefix}-vm-${count.index}"
  location              = var.region
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = var.vm_size
  zones = [ "${count.index + 1}" ]

  # Comment/Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    # offer     = "0001-com-ubuntu-server-jammy"
    # sku       = "22_04-lts"
    offer     = var.vm_type
    sku       = "server"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-myosdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
  os_profile {
    computer_name  = "${var.prefix}-vm-${count.index}"
    admin_username = var.username
    admin_password = var.password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.vm_tag
}