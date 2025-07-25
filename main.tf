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
  name     = "${var.prefix}-rsg"
  location = var.primary_region
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_subnet" "subnet" {
  count                = var.node_count_primary
  name                 = "${var.prefix}-internal-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, tostring(var.node_count_primary), tostring(count.index))]
}

resource "azurerm_public_ip" "pips" {
  count               = var.node_count_primary
  name                = "${var.prefix}-public-ip-${count.index}"
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = [ "${count.index + 1}" ]
}

# data "azurerm_public_ip" "pips" {
#   for_each           = toset(var.ip_names)
#   name               = each.value
#   resource_group_name = var.resource_grp_containing_pips
# }

resource "azurerm_network_interface" "nic" {
  count               = var.node_count_primary
  name                = "${var.prefix}-nic-${count.index}"
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ip-configuration-1"
    #subnet_id                    = element(azurerm_subnet.subnet.*.id, count.index)
    subnet_id                     = azurerm_subnet.subnet[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = var.enable_public_ip ? azurerm_public_ip.pips[count.index].id : null
    #public_ip_address_id = var.enable_public_ip ? data.azurerm_public_ip.pips[var.ip_names[count.index]].id : null
  }
}

resource "azurerm_network_interface_security_group_association" "sg2nic" {
  count                     = var.node_count_primary
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.sg.id
}

# locals {
#   node_external_ips = {
#     for idx in range(var.node_count_primary) : idx => azurerm_public_ip.publicip[idx].ip_address
#   }
# }

resource "azurerm_virtual_machine" "vm" {
  count               = var.node_count_primary
  name                  = "${var.prefix}-vm-${count.index}"
  location              = var.primary_region
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = var.vm_size
  zones = [ "${count.index + 1}" ]

  # Comment/Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.vm_publisher
    # offer     = "0001-com-ubuntu-server-jammy"
    # sku       = "22_04-lts"
    offer     = var.vm_type
    sku       = var.vm_sku
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
    custom_data = templatefile(
    "${path.module}/${count.index == 0 ? "scripts/create_cluster.sh" : "scripts/join_cluster.sh"}",
    {
      redis_tar_file_location = var.redis_tar_file_location,
      cluster_admin_username = var.cluster_admin_username,
      cluster_admin_password = var.cluster_admin_password,
      create_dr_cluster = var.create_dr_cluster,
      cluster_name = var.cluster_name,
      redis_user = var.redis_user,
      #node_external_ips  = var.enable_public_ip ? data.azurerm_public_ip.pips[var.ip_names[count.index]].ip_address : "N/A",
      node_external_ips  = var.enable_public_ip ? azurerm_public_ip.pips[count.index].ip_address : "N/A",
      node_internal_ip = azurerm_network_interface.nic[count.index].private_ip_address,
      first_node_internal_ip = azurerm_network_interface.nic[0].private_ip_address,
      enable_public_ip = var.enable_public_ip
    }
  )
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.vm_tag
}