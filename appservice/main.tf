locals {
    app_name    = "${var.appname}${random_string.unique.result}"
    merged_tags = merge({ managed_by = "terraform" }, var.tags)
    short_name  = "${substr(replace(replace(replace(var.appname, "_", ""), "-", ""), " ", ""), 0, 10)}${random_string.unique.result}"
}

data "azurerm_client_config" "current" {}

resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_application_insights" "app" {
  name                = "${local.app_name}-insights"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  application_type    = "other"
  workspace_id        = var.workspace_id
}

resource "azurerm_app_service_plan" "asp" {
  name                = "asp-${local.app_name}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  kind                = var.app_service_kind
  reserved = true
  sku {
    tier = var.sku_tier
    size = var.sku_size
  }
}

resource "azurerm_app_service" "as" {
 name                = local.app_name
 resource_group_name = var.resource_group_name
 location            = var.resource_group_location
 app_service_plan_id = azurerm_app_service_plan.asp.id

 site_config {
   always_on = var.sc_always_on
   linux_fx_version = var.sc_linux_fx_version
   health_check_path = var.sc_health_check_path
   dynamic "cors" {
      for_each = var.cors
      content {
        allowed_origins = length(lookup(cors.value, "allowed_origins", [])) > 0 ? concat(lookup(cors.value, "allowed_origins", []), ["${var.func_name}.azurewebsites.net"]) : []
        support_credentials = lookup(cors.value, "support_credentials", false)
      }  
    }
 }

 app_settings = merge({"APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.app.instrumentation_key}", "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app.connection_string}, var.app_settings)

 dynamic "storage_account" {
   for_each = var.storage_account
   content {
      name = storage_account.value["name"]
      type = storage_account.value["type"]
      account_name = storage_account.value["account_name"]
      share_name = storage_account.value["share_name"]
      access_key = storage_account.value["access_key"]
      mount_path = storage_account.value["mount_path"]
  }
 }
 identity {
   type = "SystemAssigned"
 }

}
