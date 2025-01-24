
resource "azurerm_virtual_network" "vnet_dr" {
  count = var.create_dr_cluster ? 1 : 0
  name                = "${var.prefix}-vnet-dr"
  address_space       = [var.vnet_cidr_dr]
  location            = var.dr_region
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}


resource "azurerm_virtual_network_peering" "primary_to_dr" {
  name                      = "${var.prefix}-primary-to-dr"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_dr[0].id
  allow_virtual_network_access = true
  depends_on = [
    azurerm_virtual_network.vnet_dr
  ]
}

resource "azurerm_virtual_network_peering" "dr_to_primary" {
  count = var.create_dr_cluster ? 1 : 0
  name                      = "${var.prefix}-dr-to-primary"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_dr[0].name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  depends_on = [
    azurerm_virtual_network.vnet_dr
  ]
}


resource "azurerm_subnet" "subnet_dr" {
  count                = var.node_count_dr
  name                 = "${var.prefix}-internal-dr-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_dr[0].name
  address_prefixes     = [cidrsubnet(var.vnet_cidr_dr, tostring(var.node_count_dr), tostring(count.index))]
  depends_on = [
    azurerm_virtual_network.vnet_dr
  ]
}


data "azurerm_public_ip" "pip_dr" {
  for_each           = toset(var.ip_names_dr)
  name               = each.value
  resource_group_name = var.resource_grp_containing_pips
  depends_on = [
    azurerm_virtual_network.vnet_dr
  ]
}


resource "azurerm_network_interface" "nic_dr" {
  count               = var.node_count_dr
  name                = "${var.prefix}-nic-dr-${count.index}"
  location            = var.dr_region
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ip-configuration-2"
    subnet_id                     = azurerm_subnet.subnet_dr[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = data.azurerm_public_ip.pip_dr[var.ip_names_dr[count.index]].id
  }
  depends_on = [
    azurerm_virtual_network.vnet_dr
  ]
}


resource "azurerm_network_interface_security_group_association" "sg2nic_dr" {
  count                     = var.node_count_dr
  network_interface_id      = azurerm_network_interface.nic_dr[count.index].id
  network_security_group_id = azurerm_network_security_group.sg_dr.id
  depends_on = [
    azurerm_virtual_network.vnet_dr
  ]
}


resource "azurerm_virtual_machine" "vm_dr" {
  count               = var.node_count_dr
  name                  = "${var.prefix}-vm-dr-${count.index}"
  location              = var.dr_region
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_dr[count.index].id]
  vm_size               = var.vm_size_dr
  zones = [ "${count.index + 1}" ]

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
    name              = "${var.prefix}-myosdisk-dr-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
  os_profile {
    computer_name  = "${var.prefix}-vm-dr-${count.index}"
    admin_username = var.username
    admin_password = var.password
    custom_data = templatefile(
    "${path.module}/${count.index == 0 ? "scripts/create_cluster.sh" : "scripts/join_cluster.sh"}",
    {
      redis_tar_file_location = var.redis_tar_file_location,
      cluster_admin_username = var.cluster_admin_username,
      cluster_admin_password = var.cluster_admin_password,
      create_dr_cluster = var.create_dr_cluster,
      cluster_name = var.cluster_name_dr,
      time_zone = var.time_zone,
      redis_user = var.redis_user,
      node_external_ips  = data.azurerm_public_ip.pip_dr[var.ip_names_dr[count.index]].ip_address,
      node_internal_ip = azurerm_network_interface.nic_dr[count.index].private_ip_address,
      first_node_internal_ip = azurerm_network_interface.nic_dr[0].private_ip_address
    }
  )
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.vm_tag

  depends_on = [
    azurerm_virtual_machine.vm,
    azurerm_virtual_network.vnet_dr
  ]

}