resource "azurerm_storage_account" "sa" {
  name                     = "sa-${var.func_name}"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "asp" {
  name                = "asp-${var.func_name}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  kind                = "functionapp"
  reserved = true
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_application_insights" "app" {
  name                = "${var.func_name}-insights"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"
  application_type    = "other"
}

resource "azurerm_function_app" "func" {
  name                       = "${var.func_name}"
  location                   = var.resource_group_location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_app_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  version = "~3"
  os_type = "linux"
  https_only = true

  app_settings = merge({"APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.app.instrumentation_key}"}, var.app_settings)

  site_config {
    dynamic "site_config"{
      for_each = var.site_config
      content {
        site_config.key = site_config.value
      }
    } 
  }
  
  
}

resource "null_resource" "publish_func"{
  depends_on = [
    azurerm_function_app.func
  ]
  triggers = {
    index = "${timestamp()}"
  }
  provisioner "local-exec" {
    working_dir = "DetermineActiveSite"
    command     = "func azure functionapp publish ${azurerm_function_app.func.name}"
  }
}
