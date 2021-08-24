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

 site_config = var.site_config

 app_settings = merge({"APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.app.instrumentation_key}"}, var.app_settings)

}
