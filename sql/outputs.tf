output db_server_id {
    value = azurerm_mssql_server.db.id
}

output db_fully_qualified_domain_name {
    value = azurerm_mssql_server.db.fully_qualified_domain_name
}

output db_name {
    value = azurerm_mssql_database.db.name
}

