# tfmodules

## Sample Usage:
```
module "function" {
    source = "github.com/implodingduck/tfmodules//functionapp"
    func_name = "MyFuncName"
    resource_group_name = azurerm_resource_group.rg.name
    resource_group_location = azurerm_resource_group.rg.location
    working_dir = "MyTestFunc"
    app_settings = {
      "FUNCTIONS_WORKER_RUNTIME" = "python"
    }
}
```