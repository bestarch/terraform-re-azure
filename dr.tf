
resource "azurerm_virtual_network" "vnet_dr" {
  name                = "${var.prefix}-vnet-dr"
  address_space       = [var.vnet_cidr_dr]
  location            = var.dr_region
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}


resource "azurerm_virtual_network_peering" "primary_to_dr" {
  name                      = "${var.prefix}-primary-dr"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_dr.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "dr_to_primary" {
  name                      = "${var.prefix}-dr-primary"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_dr.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
}



resource "azurerm_subnet" "subnet_dr" {
  name                 = "${var.prefix}-internal-dr"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_dr.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr_dr, tostring(3), tostring(0))]
}

data "azurerm_public_ip" "pip_dr" {
  name                = var.ip_name_dr
  resource_group_name = var.resource_grp_containing_pips
}


resource "azurerm_network_interface" "nic_dr" {
  name                = "${var.prefix}-nic-dr"
  location            = var.dr_region
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ip-configuration-2"
    subnet_id                     = azurerm_subnet.subnet_dr.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = data.azurerm_public_ip.pip_dr.id
  }
}

resource "azurerm_network_interface_security_group_association" "sg2nic_dr" {
  network_interface_id      = azurerm_network_interface.nic_dr.id
  network_security_group_id = azurerm_network_security_group.sg_dr.id
}

resource "azurerm_virtual_machine" "vm_dr" {
  name                  = "${var.prefix}-vm-dr"
  location              = var.dr_region
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_dr.id]
  vm_size               = var.vm_size_dr

  # Comment/Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.vm_publisher_dr
    offer     = var.vm_type_dr
    sku       = var.vm_sku_dr
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-myosdisk-dr"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
  os_profile {
    computer_name  = "${var.prefix}-vm-dr"
    admin_username = var.username
    admin_password = var.password
    custom_data = templatefile(
    "${path.module}/scripts/create_cluster.sh",
    {
      redis_tar_file = var.redis_tar_file,
      cluster_admin_username = var.cluster_admin_username,
      cluster_admin_password = var.cluster_admin_password,
      create_cluster = var.create_cluster,
      cluster_name = var.cluster_name_dr,
      time_zone = var.time_zone,
      redis_user = var.redis_user,
      node_external_ips  = data.azurerm_public_ip.pip_dr.ip_address,
      node_internal_ip = azurerm_network_interface.nic_dr.private_ip_address,
      first_node_internal_ip = azurerm_network_interface.nic_dr.private_ip_address
    }
  )
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.vm_tag

  depends_on = [
    azurerm_virtual_machine.vm
  ]

}