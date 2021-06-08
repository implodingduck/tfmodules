output "name" {
  value = var.name
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "keyvault_name" {
  value = azurerm_key_vault.kv.name
}