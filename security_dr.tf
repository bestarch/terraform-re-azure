
resource "azurerm_network_security_group" "sg_dr" {
  name                = "${var.prefix}-security-grp-dr"
  location            = var.dr_region
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.vm_tag
}

resource "azurerm_network_security_rule" "install-ssh-dr" {
  name                        = "SSH-rule"
  priority                    = 2001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg_dr.name
}

resource "azurerm_network_security_rule" "https-ui-dr" {
  name                        = "HTTPS-UI-rule"
  priority                    = 2000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg_dr.name
}

resource "azurerm_network_security_rule" "https-api-dr" {
  name                        = "HTTPS-API-rule"
  priority                    = 2100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg_dr.name
}

resource "azurerm_network_security_rule" "redis-dbs-dr" {
  name                        = "DBs-rule"
  priority                    = 2009
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "10001-19999"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg_dr.name
}

resource "azurerm_network_security_rule" "redis-sentinel-dr" {
  name                        = "DB-Sentinel-rule"
  priority                    = 2006
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8001"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg_dr.name
}

resource "azurerm_network_security_rule" "dns-services-dr" {
  name                        = "DNS-Server-rule"
  priority                    = 2027
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "53"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg_dr.name
}

resource "azurerm_network_security_rule" "public-ssh-dr" {
  name                        = "Public-SSH-rule"
  priority                    = 2028
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg_dr.name
}
