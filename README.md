# tfmodules
This is just a set of samples of how you can create different resources inside of azure. These modules are not intended for production use.
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