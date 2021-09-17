output "possible_outbound_ip_addresses" {
    value = split("," ,azurerm_function_app.func.possible_outbound_ip_addresses)
}

output "identity_principal_id" {
  value = lookup(azurerm_function_app.func.identity.0, { principal_id=null }).principal_id
}

output "identity_tenant_id" {
  value = lookup(azurerm_function_app.func.identity.0, { tenant_id=null }).tenant_id
}

output "function_id" {
  value = azurerm_function_app.func.id
}