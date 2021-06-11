locals {
  loc_for_naming = lower(replace(var.location, " ", ""))
}

data "azurerm_client_config" "current" {}

resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
    name = "rg-webapp-${var.name}-${local.loc_for_naming}"
    location = var.location
}

resource "azurerm_storage_account" "sa" {
    name                        = "vmdiag${random_string.unique.result}"
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = azurerm_resource_group.rg.location
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        managed_by = "terraform"
    }
}

resource "azurerm_virtual_network" "default" {
  name                = "${var.name}-vnet-${local.loc_for_naming}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]

  tags = {
    managed_by = "terraform"
  }
}

resource "azurerm_subnet" "default" {
  name                 = "default-subnet-${local.loc_for_naming}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [var.default_subnet_cidr]

}

resource "azurerm_subnet" "vm" {
  name                 = "${var.name}-subnet-${local.loc_for_naming}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [var.vm_subnet_cidr]

}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-webapp-${var.name}"
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

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.kv.id
}



resource "azurerm_public_ip" "pip" {
  name                = "pipfor${var.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# resource "azurerm_lb" "lb" {
#   name                = "lb${var.name}"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   frontend_ip_configuration {
#     name                 = "PublicIPAddress"
#     public_ip_address_id = azurerm_public_ip.pip.id
#   }
# }

# resource "azurerm_lb_backend_address_pool" "azlb" {
#   name                = "BackEndAddressPool"
#   resource_group_name = azurerm_resource_group.rg.name
#   loadbalancer_id     = azurerm_lb.lb.id
# }

# resource "azurerm_lb_nat_rule" "rule" {
#   count                          = var.num_vms
#   resource_group_name            = azurerm_resource_group.rg.name
#   loadbalancer_id                = azurerm_lb.lb.id
#   name                           = "http-${count.index}"
#   protocol                       = "Tcp"
#   frontend_port                  = "808${count.index}"
#   backend_port                   = 80
#   frontend_ip_configuration_name = "PublicIPAddress"
# }

# resource "azurerm_lb_probe" "azlb" {
#   count               = var.num_vms
#   name                = "probe-${var.name}-${count.index}"
#   resource_group_name = azurerm_resource_group.rg.name
#   loadbalancer_id     = azurerm_lb.lb.id
#   protocol            = "Http"
#   port                = 80
#   interval_in_seconds = 30
#   number_of_probes    = 3
#   request_path        = "/"
# }

# resource "azurerm_lb_rule" "azlb" {
#   count                          = var.num_vms
#   name                           = "lb-rule-${var.name}-${count.index}"
#   resource_group_name            = azurerm_resource_group.rg.name
#   loadbalancer_id                = azurerm_lb.lb.id
#   protocol                       = "tcp"
#   frontend_port                  = "808${count.index}"
#   backend_port                   = 80
#   frontend_ip_configuration_name = "PublicIPAddress"
#   enable_floating_ip             = false
#   backend_address_pool_id        = azurerm_lb_backend_address_pool.azlb.id
#   idle_timeout_in_minutes        = 5
#   probe_id                       = azurerm_lb_probe.azlb[count.index].id
# }

# resource "azurerm_network_interface" "nic" {
#   count = var.num_vms
#   name                = "${var.name}-${count.index}-nic"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   enable_ip_forwarding = true
#   ip_configuration {
#     name                          = "myipconfig${count.index}"
#     subnet_id                     = azurerm_subnet.vm.id
#     private_ip_address_allocation = "Dynamic"
#     #load_balancer_backend_address_pools_ids = [azurerm_lb_backend_address_pool.azlb.id]
#     #load_balancer_inbound_nat_rules_ids = [azurerm_lb_nat_rule.rule[count.index].id]
#   }
# }

# resource "azurerm_network_interface_nat_rule_association" "assoc" {
#   count = var.num_vms
#   network_interface_id  = azurerm_network_interface.nic[count.index].id
#   ip_configuration_name = "myipconfig${count.index}"
#   nat_rule_id           = azurerm_lb_nat_rule.rule[count.index].id
# }

# resource "azurerm_availability_set" "set" {
#   name                = "aset-${var.name}"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   managed             = true
#   tags = {
#         managed_by = "terraform"
#     }
# }

data "template_file" "nginx-vm-cloud-init" {
  template = file("${path.module}/install-nginx.sh")
}

# resource "azurerm_linux_virtual_machine" "vm" {
#     count                 = var.num_vms
#     name                  = "${var.name}-vm-${count.index}"
#     location              = azurerm_resource_group.rg.location
#     resource_group_name   = azurerm_resource_group.rg.name
#     network_interface_ids = [azurerm_network_interface.nic[count.index].id]
#     size                  = var.vm_size
#     availability_set_id   = azurerm_availability_set.set.id
#     os_disk {
#         name              = "${var.name}vm${count.index}osdesk"
#         caching           = "ReadWrite"
#         storage_account_type = "Premium_LRS"
#     }

#     source_image_reference {
#         publisher = "Canonical"
#         offer     = "0001-com-ubuntu-server-focal"
#         sku       = "20_04-lts-gen2"
#         version   = "latest"
#     }

#     computer_name  = "${var.name}-vm-${count.index}"
#     admin_username = "azureuser"
#     admin_password = random_password.password.result
#     disable_password_authentication = false
#     custom_data    = base64encode(data.template_file.nginx-vm-cloud-init.rendered)
#     # admin_ssh_key {
#     #     username       = "azureuser"
#     #     public_key     = tls_private_key.example_ssh.public_key_openssh 
#     # }

#     boot_diagnostics {
#         storage_account_uri = azurerm_storage_account.sa.primary_blob_endpoint
#     }

#     tags = {
#         managed_by = "terraform"
#     }
# }



resource "azurerm_lb" "vmss" {
 name                = "${var.name}-lb"
 location            = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name

 frontend_ip_configuration {
   name                 = "PublicIPAddress"
   public_ip_address_id = azurerm_public_ip.pip.id
 }

 tags = merge({managed_by = "terraform"}, var.tags)
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
 loadbalancer_id     = azurerm_lb.vmss.id
 name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "vmss" {
 resource_group_name = azurerm_resource_group.rg.name
 loadbalancer_id     = azurerm_lb.vmss.id
 name                = "http-running-probe"
 port                = 80
}

resource "azurerm_lb_rule" "lbnatrule" {
   resource_group_name            = azurerm_resource_group.rg.name
   loadbalancer_id                = azurerm_lb.vmss.id
   name                           = "http"
   protocol                       = "Tcp"
   frontend_port                  = 80
   backend_port                   = 80
   backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
   frontend_ip_configuration_name = "PublicIPAddress"
   probe_id                       = azurerm_lb_probe.vmss.id
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
 name                = "vmscaleset"
 location            = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name
 upgrade_policy_mode = "Manual"

 sku {
   name     = var.vm_size
   tier     = "Standard"
   capacity = var.num_vms
 }

 storage_profile_image_reference {
   publisher = "Canonical"
   offer     = "0001-com-ubuntu-server-focal"
   sku       = "20_04-lts-gen2"
   version   = "latest"
 }

 storage_profile_os_disk {
   name              = ""
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 storage_profile_data_disk {
   lun          = 0
   caching        = "ReadWrite"
   create_option  = "Empty"
   disk_size_gb   = 10
 }

 os_profile {
   computer_name_prefix = "${var.name}-vm"
   admin_username = "azureuser"
   admin_password = random_password.password.result
   custom_data    = base64encode(data.template_file.nginx-vm-cloud-init.rendered)
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

 network_profile {
   name    = "terraformnetworkprofile"
   primary = true

   ip_configuration {
     name                                   = "IPConfiguration"
     subnet_id                              = azurerm_subnet.vm.id
     load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
     primary = true
   }
 }
 boot_diagnostics {
  storage_account_uri = azurerm_storage_account.sa.primary_blob_endpoint
 }

 tags = merge({managed_by = "terraform"}, var.tags)
}