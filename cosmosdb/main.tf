resource "azurerm_cosmosdb_account" "db" {
  name                = "cdb${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
}

resource "azurerm_cosmosdb_sql_database" "sql" {
  name                = "sql${var.name}"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.db.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                  = var.name
  resource_group_name   = azurerm_cosmosdb_account.db.resource_group_name
  account_name          = azurerm_cosmosdb_account.db.name
  database_name         = azurerm_cosmosdb_sql_database.sql.name
  partition_key_path    = "/definition/id"
}