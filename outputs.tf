output "public_ips" {
  description = "List of IP addresses for Redis nodes"
  value       = [for pip in data.azurerm_public_ip.pips : pip.ip_address]
}

output "public_ips_dr" {
  description = "List of IP addresses for Redis DR nodes"
  value       = data.azurerm_public_ip.pip_dr.ip_address
}

output "internal_ips" {
  description = "Internal IP addresses of Redis Nodes"
  value = "${azurerm_network_interface.nic.*.private_ip_address}"
}

