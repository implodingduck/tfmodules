locals {
  merged_tags    = merge({ managed_by = "terraform" }, var.tags)
  loc_for_naming = lower(replace(var.location, " ", ""))
}

data "azurerm_client_config" "current" {}

resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
    name = "rg-${var.name}-webapp-${var.env}-${local.loc_for_naming}"
    location = var.location
    tags = local.merged_tags
}

resource "azurerm_storage_account" "sa" {
    name                        = "vmdiag${random_string.unique.result}${var.env}"
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = azurerm_resource_group.rg.location
    account_replication_type    = "LRS"
    account_tier                = "Standard"
    tags                        = local.merged_tags
}

resource "azurerm_virtual_network" "default" {
  name                = "${var.name}-vnet-${local.loc_for_naming}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]
  dns_servers         = []
  tags                = local.merged_tags
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
  service_endpoints    = []

}

resource "azurerm_key_vault" "kv" {
  name                        = "${var.name}-${var.env}-kv"
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
    certificate_permissions = []
    key_permissions = []
    storage_permissions = []
  }
  tags = local.merged_tags
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
  tags         = local.merged_tags
}



resource "azurerm_public_ip" "pip" {
  name                = "pipfor${var.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  zones               = []
  ip_tags             = {}
  tags                = local.merged_tags
}

data "template_file" "nginx-vm-cloud-init" {
  template = file("${path.module}/install-nginx.sh")
}

resource "azurerm_lb" "vmss" {
 name                = "${var.name}-lb"
 location            = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name

 frontend_ip_configuration {
   name                       = "PublicIPAddress"
   public_ip_address_id       = azurerm_public_ip.pip.id
   private_ip_address_version = "IPv4"
   zones                      = []
 }

 tags = local.merged_tags
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
 name                = "${var.name}-scaleset"
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
   os_type           = "Linux"
   vhd_containers    = []
 }

 storage_profile_data_disk {
   lun          = 0
   caching        = "ReadWrite"
   create_option  = "Empty"
   disk_size_gb   = 10
 }

 os_profile {
   computer_name_prefix = "${var.name}-${var.env}-vm-"
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
  storage_uri = azurerm_storage_account.sa.primary_blob_endpoint
 }

 tags = local.merged_tags
}