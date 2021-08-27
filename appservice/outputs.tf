output "app_service_name" {
  value = azurerm_app_service.as.name
}

output "possible_outbound_ip_address_list" {
  value = azurerm_app_service.as.possible_outbound_ip_address_list
}

output "identity_principal_id" {
  value = azurerm_app_service.as.identity.0.principal_id
}

output "identity_tenant_id" {
  value = azurerm_app_service.as.identity.0.tenant_id
}