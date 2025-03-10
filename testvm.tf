resource "azurerm_virtual_network" "test_vnet" {
  count = var.create_test_vm ? 1 : 0
  name                = "${var.prefix}-test-vnet"
  address_space       = [var.test_vnet_cidr]
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name
   depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "test_subnet" {
  count = var.create_test_vm ? 1 : 0
  name                 = "${var.prefix}-test-internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.test_vnet[count.index].name
  address_prefixes     = [cidrsubnet(var.test_vnet_cidr, 1, 1)]
}

resource "azurerm_public_ip" "test_publicip" {
  count = var.create_test_vm ? 1 : 0
  name                = "${var.prefix}-test-public-ip"
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = [ "${count.index}" ]
}

resource "azurerm_network_interface" "test_nic" {
  count = var.create_test_vm ? 1 : 0
  name                = "${var.prefix}-test-nic"
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ip-configuration-2"
    subnet_id                     = azurerm_subnet.test_subnet[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test_publicip[count.index].id
  }
}

resource "azurerm_network_security_group" "test_sg" {
  count = var.create_test_vm ? 1 : 0
  name                = "${var.prefix}-test-security-grp"
  location            = var.primary_region
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.vm_tag
}

resource "azurerm_network_interface_security_group_association" "test_sg2nic" {
  count = var.create_test_vm ? 1 : 0
  network_interface_id      = azurerm_network_interface.test_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.test_sg[count.index].id
}

resource "azurerm_virtual_machine" "test_vm" {
  count = var.create_test_vm ? 1 : 0
  name                  = "${var.prefix}-test-vm"
  location              = var.primary_region
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.test_nic[count.index].id]
  vm_size               = var.test_vm_size
  zones = [ 1]
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.test_vm_publisher
    offer     = var.test_vm_type
    sku       = var.test_vm_sku
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-testdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
  os_profile {
    computer_name  = "${var.prefix}-test-vm"
    admin_username = var.username
    admin_password = var.password
    custom_data = file("${path.module}/scripts/test_vm.sh")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.vm_tag
}

resource "azurerm_virtual_network_peering" "primary_to_test" {
  count = var.create_test_vm ? 1 : 0
  name                      = "${var.prefix}-primary-to-test"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.test_vnet[count.index].id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "test_to_primary" {
  count = var.create_test_vm ? 1 : 0
  name                      = "${var.prefix}-test-to-primary"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.test_vnet[count.index].name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
}

resource "azurerm_network_security_rule" "test_ssh_access" {
  count = var.create_test_vm ? 1 : 0
  name                        = "test-SSH-rule"
  priority                    = 2001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.test_sg[count.index].name
}
