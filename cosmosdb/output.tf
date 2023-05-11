output "connection_strings" {
    value = azurerm_cosmosdb_account.db.connection_strings
    sensitive = true
}
