output "public-ips" {
  description = "Public IP of the Node1"
  value = "${azurerm_public_ip.publicip.*.ip_address}"
}

output "internalip1" {
  description = "INternal IP of the Node1"
  value = "${azurerm_network_interface.nic[0].private_ip_address}"
}

output "internalip2" {
  description = "External IP of"
  value = "${azurerm_public_ip.publicip[0].ip_address}"
}
