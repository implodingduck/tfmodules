output "connection_strings" {
    value = azurerm_cosmosdb_account.example.connection_strings
    sensitive = true
}
