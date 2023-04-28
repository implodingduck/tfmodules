terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    random = {
      source  = "hashicorp/random"
    }
    azapi = {
      source  = "azure/azapi"
    }
  }
}

data "http" "ip" {
  url = "https://ifconfig.me/ip"
}


resource "azurerm_storage_account" "sa" {
  name                     = "sa${var.name}"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

resource "azurerm_storage_container" "hosts" {
#   depends_on = [
#     azapi_resource_action.resource_access_rule
#   ]
  name                  = "azure-webjobs-hosts"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "secrets" {
#   depends_on = [
#     azapi_resource_action.resource_access_rule
#   ]
  name                  = "azure-webjobs-secrets"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_share" "share" {
#   depends_on = [
#     azapi_resource_action.resource_access_rule
#   ]
  name                 = "la-${var.name}-content"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 1
}

# resource "azapi_resource_action" "resource_access_rule" {
#     type = "Microsoft.Storage/storageAccounts@2022-05-01"
#     resource_id            = azurerm_storage_account.sa.id
#     method                 = "PUT"
    
#     body                   = jsonencode({
#         location               = var.resource_group_location
#         properties = {
#             networkAcls = {
#                 # resourceAccessRules = [
#                 #     {
#                 #         resourceId = "${azurerm_resource_group.rg.id}/providers/Microsoft.Logic/workflows/*"
#                 #         tenantId = data.azurerm_client_config.current.tenant_id
#                 #     }
#                 # ]
#                 bypass = "AzureServices"
#                 virtualNetworkRules = [
#                     {
#                         id = var.subnet_id_logicapp
#                         action = "Allow"
#                     }
                    
#                 ]
#                 ipRules = [
#                     {
#                         action = "Allow"
#                         value = data.http.ip.response_body
#                     }
#                 ]
#                 defaultAction = "Deny"
#             }
#         }
#     })
# }


resource "azurerm_service_plan" "asp" {
  name                = "asp-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  os_type             = "Windows"
  sku_name            = "WS1"
  tags = var.tags
}


resource "azurerm_logic_app_standard" "example" {
  name                       = "la-${var.name}"
  location                   = var.resource_group_location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  virtual_network_subnet_id  = var.subnet_id_logicapp
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"        = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"    = "~14"
    "WEBSITE_CONTENTOVERVNET"         = "1"
    "AzureWebJobStorage__accountName" = azurerm_storage_account.sa.name
  }

  site_config {
    dotnet_framework_version  = "v6.0"
    use_32_bit_worker_process = true
    vnet_route_all_enabled    = true
    ftps_state                = "Disabled"
  }

  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}

resource "azurerm_role_assignment" "system" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_logic_app_standard.example.identity.0.principal_id  
}