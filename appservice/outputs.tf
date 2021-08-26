output "app_service_name" {
  value = azurerm_app_service.as.name
}

output "possible_outbound_ip_address_list" {
  value = azurerm_app_service.as.possible_outbound_ip_address_list
}