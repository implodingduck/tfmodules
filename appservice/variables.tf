variable "appname" {
  type = string
}

variable "tags" {
  type = map
  default = {}
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "sku_tier" {
  type = string
  default = "Basic"
}

variable "sku_size" {
  type = string
  default = "B1"
}

variable "app_service_kind" {
  type = string
  default = "Linux"
}

variable "app_settings" {
  type = map
  default = {}
}


variable "workspace_id" {
  type = string
}

variable "sc_always_on" {
  type = string
}

variable "sc_linux_fx_version" {
  type = string
}

variable "sc_health_check_path" {
  type = string
}

variable "storage_account" {
  default = []
}

variable "cors" {
  default = []
}

variable "acr_use_managed_identity_credentials" {
  default = false
}