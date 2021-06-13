locals {
  sa_name = substr(replace(replace(replace(var.name, "_", ""), "-", ""), " ", ""), 0, 12)
}

data "azurerm_client_config" "current" {}

resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-be-${var.name}-${var.env}"
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = "${local.sa_name}${random_string.unique.result}${var.env}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-${var.name}-${var.env}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge"
    ]
  }
}

resource "azurerm_key_vault_secret" "container" {
  name         = "container-name"
  value        = azurerm_storage_container.state.name
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "key" {
  name         = "key"
  value        = var.name
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "rg" {
  name         = "resource-group-name"
  value        = azurerm_resource_group.rg.name
  key_vault_id = azurerm_key_vault.kv.id
}


resource "azurerm_key_vault_secret" "sa" {
  name         = "storage-account-name"
  value        = azurerm_storage_account.sa.name
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "subscription" {
  name         = "subscription-id"
  value        = data.azurerm_client_config.current.subscription_id
  key_vault_id = azurerm_key_vault.kv.id
}




