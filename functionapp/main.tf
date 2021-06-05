resource "azurerm_storage_account" "sa" {
  name                     = "sa-${local.das_func_name}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "asp" {
  name                = "asp-${local.das_func_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "functionapp"
  reserved = true
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_application_insights" "app" {
  name                = "${local.das_func_name}-insights"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  application_type    = "other"
}

resource "azurerm_function_app" "func" {
  name                       = "${local.das_func_name}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  version = "~3"
  os_type = "linux"
  https_only = true

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.app.instrumentation_key}"
    "COSMOSDB_ENDPOINT"        = azurerm_cosmosdb_account.cosmos.endpoint
    "COSMOSDB_KEY"             = azurerm_cosmosdb_account.cosmos.primary_key
    "COSMOSDB_NAME"            = "${local.das_func_name}-db"
    "COSMOSDB_CONTAINER"       = "${local.das_func_name}-dbcontainer"
  }

  site_config {
    use_32_bit_worker_process   = false
    linux_fx_version = "Python|3.8"        
    ftps_state = "Disabled"
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
