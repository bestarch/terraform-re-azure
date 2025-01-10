output "public-ips" {
  description = "Public IP of the Node1"
  value = "${azurerm_public_ip.publicip.*.ip_address}"
}
