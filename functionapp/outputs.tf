output "possible_outbound_ip_addresses" {
    value = split("," ,azurerm_function_app.func.possible_outbound_ip_addresses)
}

output "identity_principal_id" {
  value = length(azurerm_function_app.func.identity) == 0 ? null : azurerm_function_app.func.identity.0.principal_id
}

output "identity_tenant_id" {
  value = length(azurerm_function_app.func.identity) == 0 ? null : azurerm_function_app.func.identity.0.tenant_id
}

output "function_id" {
  value = azurerm_function_app.func.id
}


output "function_name" {
  value = azurerm_function_app.func.name
}

output "asp_id" {
  value = azurerm_app_service_plan.asp.id
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "storage_account_key" {
  value = azurerm_storage_account.sa.primary_access_key
  sensitive = true
}