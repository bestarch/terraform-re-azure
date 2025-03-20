output "public_ips" {
  description = "List of public IP addresses for Redis nodes"
  value       = var.enable_public_ip ? [for pip in data.azurerm_public_ip.pips : pip.ip_address] : null
}

output "public_ips_dr" {
  description = "List of IP addresses for Redis DR nodes"
  value       = var.create_dr_cluster ? [for pip in azurerm_public_ip.pip_dr : pip.ip_address] : null
  depends_on = [
    azurerm_virtual_network.vnet_dr
  ]
}

output "internal_ips" {
  description = "Internal IP addresses of Redis Nodes"
  value = "${azurerm_network_interface.nic.*.private_ip_address}"
}

output "test_vm_ip" {
  description = "IP address of test VM"
  value       = var.create_test_vm ? azurerm_public_ip.test_publicip[0].ip_address : null
  depends_on = [
    azurerm_virtual_network.test_vnet
  ]
}
