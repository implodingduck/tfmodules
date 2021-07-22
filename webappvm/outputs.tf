output "resource_group_name" { 
    value = azurerm_resource_group.rg.name
}

output "resource_group_location" { 
    value = azurerm_resource_group.rg.location
}

output "vmpassword" {
    sensitive = true
    value = random_password.password.result
}