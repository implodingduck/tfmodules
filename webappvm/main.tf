locals {
  loc_for_naming = lower(replace(var.location, " ", ""))
}

resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
    name = "rg-webapp-${var.name}-${local.loc_for_naming}"
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
  name                = "${var.cluster_name}-vnet-${local.loc_for_naming}"
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
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [var.vm_subnet_cidr]

}

resource "azurerm_network_interface" "nic" {
  count = var.num_vms
  name                = "${var.name}-${count.index}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myipconfig"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
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

    key_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Create",
      "Import",
      "Update",
      "Decrypt",
      "Encrypt"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge"
    ]
  }
}

resource "azurerm_key_vault_key" "generated" {
  name         = "generated-certificate"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 4096

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_linux_virtual_machine" "vm" {
    count                 = var.num_vms
    name                  = "${var.name}-vm-${count.index}"
    location              = azurerm_resource_group.rg.location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic[count.index].id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "20.04-LTS"
        version   = "latest"
    }

    computer_name  = "${var.name}-vm-${count.index}"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = file("~/.ssh/id_rsa.pub")
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.sa.primary_blob_endpoint
    }

    tags = {
        managed_by = "terraform"
    }
}

