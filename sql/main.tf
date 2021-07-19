locals {
  merged_tags    = merge({ managed_by = "terraform" }, var.tags)
  loc_for_naming = lower(replace(var.resource_group_location, " ", ""))
}

data "azurerm_client_config" "current" {}

resource "azurerm_mssql_server" "db" {
  name                         = "${var.name}-server"
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.db_password
  minimum_tls_version          = "1.2"

  tags = local.merged_tags
}

resource "azurerm_mssql_database" "db" {
  name                        = "${var.name}db"
  server_id                   = azurerm_mssql_server.db.id
  max_size_gb                 = 40
  auto_pause_delay_in_minutes = -1
  min_capacity                = 1
  sku_name                    = "GP_S_Gen5_1"
  tags = local.merged_tags
  short_term_retention_policy {
    retention_days = 7
  }
}

resource "azurerm_mssql_firewall_rule" "azureservices" {
  name             = "azureservices"
  server_id        = azurerm_mssql_server.db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "editor" {
  name             = "editor"
  server_id        = azurerm_mssql_server.db.id
  start_ip_address = "167.220.149.227"
  end_ip_address   = "167.220.149.227"
}

resource "azurerm_template_deployment" "sql_connection" {
  name = "${var.name}-sql-connection"
  resource_group_name = var.resource_group_name

  template_body = <<DEPLOY
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "connections_sql_name": {
            "defaultValue": "sql",
            "type": "String"
        },
        "sqlPassword": {
            "type": "securestring"
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Web/connections",
            "apiVersion": "2016-06-01",
            "name": "[parameters('connections_sql_name')]",
            "location": "eastus",
            "kind": "V1",
            "properties": {
                "displayName": "${var.name}-sql-connection",
                "customParameterValues": {},
                "api": {
                    "id": "[concat('/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/eastus/managedApis/', parameters('connections_sql_name'))]"
                },
                "parameterValues": {
                  "server": "${azurerm_mssql_server.db.name}.database.windows.net",
                  "database": "${azurerm_mssql_database.db.name}",
                  "authType": "basic",
                  "username": "sqladmin",
                  "password": "[parameters('sqlPassword')]"
                }
            }
        }
    ]
}
  DEPLOY
  parameters = {
    "sqlPassword" = var.db_password
  }
  deployment_mode = "Incremental"
}
